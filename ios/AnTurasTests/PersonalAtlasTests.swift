import XCTest
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

    private func bundledPack() throws -> PersonalAtlasPack {
        let bundle = Bundle(for: type(of: self))
        let url = try XCTUnwrap(
            bundle.url(forResource: "personal-atlas-subjects", withExtension: "json"),
            "The personal-atlas resource was not copied into the test bundle"
        )
        return try PersonalAtlasLoader.decode(Data(contentsOf: url))
    }
}
