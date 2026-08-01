import XCTest
@testable import AnTuras

final class PhraseFamilyCatalogTests: XCTestCase {
    func testMayoCatalogLoadsFarraigeCoastalAndKinMembers() {
        let catalog = PhraseFamilyCatalog.members(forCounty: "mayo")
        XCTAssertGreaterThanOrEqual(catalog.count, 20)
        XCTAssertEqual(catalog["farraige.ship-on-sea"]?.text, "Tá an long ar an bhfarraige.")
        XCTAssertEqual(catalog["caislean.castle-here"]?.text, "Tá an caisleán anseo.")
        XCTAssertEqual(catalog["teaghlach.household-here"]?.lexemeID, "lex.teaghlach")
        XCTAssertEqual(catalog["mac.son-under-pressure"]?.lexemeID, "lex.mac")
    }

    func testBundledRockfleetWiresPhraseFamilyMembers() throws {
        let pack = try XCTUnwrap(CountyStoryPackCatalog.pack(id: "mayo.grainne-1593"))
        let typed = try XCTUnwrap(pack.page(id: "mayo.rockfleet.type-castle")?.exercise)
        XCTAssertEqual(typed.answer, "Tá an caisleán anseo.")
        XCTAssertTrue(
            typed.phraseFamilyMemberIDs?.contains("caislean.castle-here") == true,
            "expected caislean.castle-here in \(String(describing: typed.phraseFamilyMemberIDs))"
        )
        XCTAssertNoThrow(try CountyStoryPackValidator.validate(
            CountyStoryPackEnvelope(schemaVersion: 2, pack: pack)
        ))
    }

    func testPhraseFamilyMemberMismatchFailsValidation() throws {
        let pack = try XCTUnwrap(CountyStoryPackCatalog.pack(id: "mayo.grainne-1593"))
        let typed = try XCTUnwrap(pack.page(id: "mayo.rockfleet.type-castle")?.exercise)
        var object = try JSONSerialization.jsonObject(with: JSONEncoder().encode(typed)) as! [String: Any]
        object["phraseFamilyMemberIDs"] = ["farraige.ship-on-sea"]
        let bad = try JSONDecoder().decode(
            CountyExercise.self,
            from: JSONSerialization.data(withJSONObject: object)
        )
        XCTAssertThrowsError(
            try CountyStoryPackValidator.validatePhraseFamilyMembers(
                bad,
                pageID: "mayo.rockfleet.type-castle",
                packID: pack.id
            )
        ) { error in
            XCTAssertEqual(
                error as? CountyStoryPackError,
                .phraseFamilyMemberMismatch("mayo.rockfleet.type-castle")
            )
        }
    }
}
