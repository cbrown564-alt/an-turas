import XCTest
import CryptoKit
@testable import AnTuras

final class PersonalAtlasTests: XCTestCase {
    func testBundledPackPassesStructuralValidation() throws {
        let pack = try bundledPack()

        XCTAssertEqual(pack.index.count, 80)
        XCTAssertEqual(pack.subjects.count, 80)
        XCTAssertEqual(PersonalAtlasLoader.validate(pack), [])
    }

    func testSearchPreservesIrishFormsWhileMatchingWithoutDiacritics() throws {
        let pack = try bundledPack()

        XCTAssertEqual(PersonalSearch.matches(query: "Grainne", in: pack).first?.id, "name.given.grainne")
        XCTAssertEqual(PersonalSearch.matches(query: "O Briain", in: pack).first?.id, "name.surname.obrien")
        XCTAssertEqual(PersonalSearch.matches(query: "Derry", in: pack).first?.id, "place.derry")
    }

    func testSearchReturnsFullResultSetBeforePresentationLimit() throws {
        let pack = try bundledPack()

        XCTAssertGreaterThan(PersonalSearch.matches(query: "i", in: pack).count, 12)
    }

    func testEveryAssertionResolvesItsEvidence() throws {
        let pack = try bundledPack()

        for subject in pack.subjects {
            let evidenceIds = Set(subject.evidence.map(\.id))
            for assertion in subject.assertions {
                XCTAssertFalse(assertion.evidenceIds.isEmpty, "\(subject.id) has an unsourced assertion")
                XCTAssertTrue(
                    Set(assertion.evidenceIds).isSubset(of: evidenceIds),
                    "\(subject.id) references evidence outside its subject"
                )
            }
        }
    }

    func testPrivacySafeQueryEventHasNoRawInputOrCoordinates() throws {
        let event = PersonalAtlasQueryEvent(
            id: UUID(),
            subjectId: "place.killala",
            outcome: .openedSubject,
            unresolvedReason: nil,
            createdAt: Date(timeIntervalSince1970: 0)
        )

        let object = try XCTUnwrap(
            JSONSerialization.jsonObject(with: JSONEncoder().encode(event)) as? [String: Any]
        )
        XCTAssertEqual(object["subjectId"] as? String, "place.killala")
        XCTAssertNil(object["rawQuery"])
        XCTAssertNil(object["latitude"])
        XCTAssertNil(object["longitude"])
    }

    func testCorrectionLeadRoundTripsAsPrivateEditorialInput() throws {
        let feedback = PersonalAtlasFeedback(
            id: UUID(),
            subjectId: "place.derry",
            assertionId: "Recorded public forms",
            kind: .localForm,
            context: "A local form with archive context",
            sourceURL: "https://example.invalid/archive",
            createdAt: Date(timeIntervalSince1970: 0)
        )

        let decoded = try JSONDecoder().decode(
            PersonalAtlasFeedback.self,
            from: JSONEncoder().encode(feedback)
        )
        XCTAssertEqual(decoded, feedback)
    }

    func testPlacePackSupportsCoarseNearbySuggestionsWithoutNetwork() throws {
        let places = try bundledPack().subjects.filter { $0.kind == .place }

        XCTAssertEqual(places.count, 30)
        XCTAssertTrue(places.allSatisfy { $0.placeProfile?.coordinates != nil })
    }

    func testPilotContentCannotMasqueradeAsPublicRelease() throws {
        let pack = try bundledPack()

        XCTAssertTrue(pack.subjects.allSatisfy { $0.editorial.releaseState == "pilot" })
    }

    func testPersonalAtlasDeepLinksRoundTripWithoutPrivateQueryText() throws {
        let id = "name.surname.obrien"
        let webURL = try XCTUnwrap(PersonalAtlasDeepLink.webURL(for: id))

        XCTAssertEqual(PersonalAtlasDeepLink.subjectID(from: webURL), id)
        XCTAssertEqual(
            PersonalAtlasDeepLink.subjectID(from: URL(string: "anturas://personal/\(id)")!),
            id
        )
        XCTAssertNil(PersonalAtlasDeepLink.subjectID(from: URL(string: "https://example.com/?subject=\(id)")!))
        XCTAssertFalse(webURL.absoluteString.localizedCaseInsensitiveContains("o%27brien"))
    }

    func testSignedDetailPackAuthenticatesCachesAndSurvivesNetworkFailure() async throws {
        let (subject, data) = try rawSubject(id: "place.killala")
        let privateKey = Curve25519.Signing.PrivateKey()
        let artifact = try signedArtifact(
            subjectId: subject.id,
            data: data,
            privateKey: privateKey
        )
        let manifest = PersonalAtlasReleaseManifest(
            releaseId: "test-release",
            version: "2.0.0",
            contentDate: "2026-07-13",
            publicKeyId: "test-key",
            artifacts: [artifact]
        )
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let cache = try PersonalAtlasDetailCache(directory: directory)
        let counter = FetchCounter()
        let repository = PersonalAtlasRepository(
            baseURL: URL(string: "https://content.invalid/personal-atlas/")!,
            manifest: manifest,
            pinnedPublicKey: privateKey.publicKey.rawRepresentation,
            cache: cache,
            fetcher: { url in
                await counter.increment()
                return (
                    data,
                    HTTPURLResponse(
                        url: url,
                        statusCode: 200,
                        httpVersion: nil,
                        headerFields: nil
                    )!
                )
            }
        )

        let first = try await repository.subject(id: subject.id)
        let second = try await repository.subject(id: subject.id)
        XCTAssertEqual(first.id, subject.id)
        XCTAssertEqual(second.id, subject.id)
        let fetchCount = await counter.value
        XCTAssertEqual(fetchCount, 1, "The second read should use the authenticated cache")
        try? FileManager.default.removeItem(at: directory)
    }

    func testSignedDetailPackRejectsTamperingBeforeCaching() throws {
        let (subject, data) = try rawSubject(id: "name.given.grainne")
        let privateKey = Curve25519.Signing.PrivateKey()
        let artifact = try signedArtifact(
            subjectId: subject.id,
            data: data,
            privateKey: privateKey
        )
        var tampered = data
        tampered.append(0x20)

        XCTAssertThrowsError(
            try PersonalAtlasPackVerifier.verify(
                tampered,
                artifact: artifact,
                publicKey: privateKey.publicKey.rawRepresentation
            )
        )
    }

    func testLogainmFoundationEntryBuildsHonestSourceBackedFallback() throws {
        let json = #"""
        {
          "id":"logainm.45008","kind":"place","canonicalDisplay":"Ceathrúnach",
          "subtitle":"townland · Sligeach","variants":["Carrownagh"],
          "variantRelationships":[{"display":"Carrownagh","relationship":"relatedForm","note":"Recorded by Logainm"}],
          "searchKeys":["Ceathrúnach","Carrownagh"],"depth":"foundation",
          "nameKind":null,"hierarchy":"Sligeach","placeKind":"Townland",
          "foundation":{"logainmId":45008,"irishForm":"Ceathrúnach","englishForm":"Carrownagh",
            "placeKind":"Townland","hierarchy":"Sligeach","coordinates":{"lat":54.2131,"lon":-8.41126},
            "permalink":"https://www.logainm.ie/en/45008","modifiedAt":"2026-06-01",
            "attribution":"Irish-language placename data by Logainm © Government of Ireland and licensed under CC BY 4.0."}
        }
        """#.data(using: .utf8)!
        let entry = try JSONDecoder().decode(PersonalIndexEntry.self, from: json)
        let place = try XCTUnwrap(entry.foundation)
        let subject = PersonalAtlasLoader.foundationSubject(entry: entry, place: place)

        XCTAssertEqual(subject.depth, .foundation)
        XCTAssertEqual(subject.placeProfile?.logainmId, 45008)
        XCTAssertEqual(subject.assertions.first?.certainty, .recorded)
        XCTAssertTrue(subject.editorial.shortAnswer.contains("deeper story is still being researched"))
        XCTAssertEqual(subject.evidence.first?.stableURL, "https://www.logainm.ie/en/45008")
    }

    func testBundledLogainmDatabaseSearchesLazilyAndBuildsDetail() throws {
        let store = try XCTUnwrap(PersonalAtlasLoader.foundationStore)
        let match = try XCTUnwrap(store.matches(query: "Rath Bhile", limit: 10).first)

        XCTAssertEqual(match.id, "logainm.1")
        XCTAssertEqual(match.canonicalDisplay, "Ráth Bhile")
        XCTAssertEqual(match.foundation?.englishForm, "Rathvilly")
        XCTAssertEqual(PersonalAtlasLoader.subject(id: match.id)?.placeProfile?.logainmId, 1)
    }

    func testBundledFoundationCarriesReviewedHierarchyRepairs() throws {
        let store = try XCTUnwrap(PersonalAtlasLoader.foundationStore)
        let townland = try XCTUnwrap(store.entry(id: "logainm.56408"))
        let townlandPlace = try XCTUnwrap(townland.foundation)
        XCTAssertEqual(townlandPlace.hierarchy, "Machaire Lainne / Armagh")
        XCTAssertEqual(townlandPlace.hierarchyRepairs?.map(\.county), ["Armagh"])
        XCTAssertEqual(
            townlandPlace.hierarchyRepairs?.first?.method,
            "reviewed_external_evidence"
        )

        let parish = try XCTUnwrap(store.entry(id: "logainm.2737")?.foundation)
        XCTAssertEqual(parish.hierarchy, "Armagh / Down")
        XCTAssertEqual(parish.hierarchyRepairs?.map(\.county), ["Armagh", "Down"])
    }

    private func bundledPack() throws -> PersonalAtlasPack {
        let bundle = Bundle(for: type(of: self))
        let url = try XCTUnwrap(
            bundle.url(forResource: "personal-atlas-subjects", withExtension: "json"),
            "The personal-atlas resource was not copied into the test bundle"
        )
        return try PersonalAtlasLoader.decode(Data(contentsOf: url))
    }

    private func rawSubject(id: String) throws -> (OriginSubject, Data) {
        let bundle = Bundle(for: type(of: self))
        let url = try XCTUnwrap(bundle.url(forResource: "personal-atlas-subjects", withExtension: "json"))
        let root = try XCTUnwrap(
            JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any]
        )
        let subjects = try XCTUnwrap(root["subjects"] as? [[String: Any]])
        let object = try XCTUnwrap(subjects.first { $0["id"] as? String == id })
        let data = try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
        return (try JSONDecoder().decode(OriginSubject.self, from: data), data)
    }

    private func signedArtifact(
        subjectId: String,
        data: Data,
        privateKey: Curve25519.Signing.PrivateKey
    ) throws -> PersonalAtlasArtifact {
        PersonalAtlasArtifact(
            subjectId: subjectId,
            version: "2.0.0",
            path: "subjects/\(subjectId).json",
            sha256: PersonalAtlasPackVerifier.digestHex(for: data),
            signature: try privateKey.signature(for: data).base64EncodedString(),
            contentDate: "2026-07-13"
        )
    }
}

private actor FetchCounter {
    private var count = 0
    var value: Int { count }
    func increment() { count += 1 }
}
