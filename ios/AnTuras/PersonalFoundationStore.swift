import Foundation
import SQLite3

/// Read-only access to the broad Logainm corpus. The database stays on disk so opening
/// the atlas does not decode 126,000 foundation records or duplicate their search keys.
final class PersonalFoundationStore {
    struct Metadata {
        let version: String
        let contentDate: String
        let attribution: String
    }

    private let database: OpaquePointer
    let metadata: Metadata

    private static let sqliteTransient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

    static func bundled() -> PersonalFoundationStore? {
        guard let url = Bundle.main.url(
            forResource: "personal-atlas-foundation",
            withExtension: "sqlite"
        ) else { return nil }
        return try? PersonalFoundationStore(url: url)
    }

    init(url: URL) throws {
        var handle: OpaquePointer?
        guard sqlite3_open_v2(url.path, &handle, SQLITE_OPEN_READONLY, nil) == SQLITE_OK,
              let handle else {
            if let handle { sqlite3_close(handle) }
            throw PersonalAtlasLoadError.malformedContent("The offline place index could not be opened.")
        }
        database = handle
        metadata = try Self.readMetadata(from: handle)
    }

    deinit { sqlite3_close(database) }

    func matches(query: String, limit: Int = 200) -> [PersonalIndexEntry] {
        let key = PersonalSearch.normalize(query)
        guard !key.isEmpty else { return [] }
        let sql = """
            SELECT p.id, p.canonical, p.subtitle, p.variants, p.hierarchy, p.place_kind,
                   p.irish, p.english, p.latitude, p.longitude, p.permalink, p.modified_at,
                   MIN(CASE WHEN a.search_key = ?1 THEN 0
                            WHEN a.search_key LIKE ?2 THEN 1 ELSE 2 END) AS match_rank
            FROM aliases a JOIN places p ON p.id = a.place_id
            WHERE a.search_key = ?1 OR a.search_key LIKE ?2 OR a.search_key LIKE ?3
            GROUP BY p.id
            ORDER BY match_rank, p.canonical COLLATE NOCASE
            LIMIT ?4
            """
        guard let statement = prepare(sql) else { return [] }
        defer { sqlite3_finalize(statement) }
        bind(key, to: 1, in: statement)
        bind(key + "%", to: 2, in: statement)
        bind("%" + key + "%", to: 3, in: statement)
        sqlite3_bind_int(statement, 4, Int32(limit))
        return rows(from: statement)
    }

    func entry(id: String) -> PersonalIndexEntry? {
        guard id.hasPrefix("logainm."), let placeID = Int(id.dropFirst("logainm.".count)) else {
            return nil
        }
        let sql = """
            SELECT id, canonical, subtitle, variants, hierarchy, place_kind, irish, english,
                   latitude, longitude, permalink, modified_at
            FROM places WHERE id = ?1
            """
        guard let statement = prepare(sql) else { return nil }
        defer { sqlite3_finalize(statement) }
        sqlite3_bind_int64(statement, 1, sqlite3_int64(placeID))
        return rows(from: statement).first
    }

    private func prepare(_ sql: String) -> OpaquePointer? {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK else { return nil }
        return statement
    }

    private func bind(_ value: String, to index: Int32, in statement: OpaquePointer) {
        sqlite3_bind_text(statement, index, value, -1, Self.sqliteTransient)
    }

    private func rows(from statement: OpaquePointer) -> [PersonalIndexEntry] {
        var entries: [PersonalIndexEntry] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            let placeID = Int(sqlite3_column_int64(statement, 0))
            let canonical = text(statement, 1) ?? ""
            let variantsData = (text(statement, 3) ?? "[]").data(using: .utf8) ?? Data()
            let variants = (try? JSONDecoder().decode([String].self, from: variantsData)) ?? []
            let hierarchy = text(statement, 4) ?? "Ireland"
            let placeKind = text(statement, 5) ?? "place"
            let latitude = optionalDouble(statement, 8)
            let longitude = optionalDouble(statement, 9)
            let coordinates = latitude.flatMap { lat in longitude.map { PersonalCoordinates(lat: lat, lon: $0) } }
            let foundation = PersonalFoundationPlace(
                logainmId: placeID,
                irishForm: text(statement, 6),
                englishForm: text(statement, 7),
                placeKind: placeKind,
                hierarchy: hierarchy,
                coordinates: coordinates,
                permalink: text(statement, 10) ?? "https://www.logainm.ie/en/\(placeID)",
                modifiedAt: text(statement, 11),
                attribution: metadata.attribution
            )
            entries.append(PersonalIndexEntry(
                id: "logainm.\(placeID)", kind: .place, canonicalDisplay: canonical,
                subtitle: text(statement, 2) ?? "\(placeKind.lowercased()) · \(hierarchy)",
                variants: variants,
                variantRelationships: variants.map {
                    PersonalVariant(display: $0, relationship: .relatedForm, note: "Recorded by Logainm")
                },
                searchKeys: [canonical] + variants, depth: .foundation, nameKind: nil,
                hierarchy: hierarchy, placeKind: placeKind, foundation: foundation
            ))
        }
        return entries
    }

    private func text(_ statement: OpaquePointer, _ column: Int32) -> String? {
        guard sqlite3_column_type(statement, column) != SQLITE_NULL,
              let value = sqlite3_column_text(statement, column) else { return nil }
        return String(cString: value)
    }

    private func optionalDouble(_ statement: OpaquePointer, _ column: Int32) -> Double? {
        sqlite3_column_type(statement, column) == SQLITE_NULL ? nil : sqlite3_column_double(statement, column)
    }

    private static func readMetadata(from database: OpaquePointer) throws -> Metadata {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, "SELECT key, value FROM metadata", -1, &statement, nil) == SQLITE_OK,
              let statement else {
            throw PersonalAtlasLoadError.malformedContent("The offline place metadata is missing.")
        }
        defer { sqlite3_finalize(statement) }
        var values: [String: String] = [:]
        while sqlite3_step(statement) == SQLITE_ROW,
              let key = sqlite3_column_text(statement, 0),
              let value = sqlite3_column_text(statement, 1) {
            values[String(cString: key)] = String(cString: value)
        }
        guard let version = values["version"], let date = values["contentDate"],
              let attribution = values["attribution"] else {
            throw PersonalAtlasLoadError.malformedContent("The offline place metadata is incomplete.")
        }
        return Metadata(version: version, contentDate: date, attribution: attribution)
    }
}
