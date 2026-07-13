import XCTest
@testable import AnTuras

final class SpeechCatalogTests: XCTestCase {
    func testProductionCatalogUsesSelectedHouseVoiceAndEveryClipIsBundled() throws {
        let manifestURL = try XCTUnwrap(
            Bundle.main.url(forResource: "manifest", withExtension: "json")
        )
        let object = try XCTUnwrap(
            JSONSerialization.jsonObject(with: Data(contentsOf: manifestURL)) as? [String: Any]
        )
        let voice = try XCTUnwrap(object["voice"] as? [String: String])
        XCTAssertEqual(voice["name"], "Irish Cultural Guide")
        XCTAssertEqual(voice["id"], "NPWroowF4phQhaPWjXPj")
        XCTAssertEqual(object["provider"] as? String, "ElevenLabs")
        XCTAssertEqual(object["model_id"] as? String, "eleven_v3")
        XCTAssertEqual(object["language_code"] as? String, "ga")

        let lines = try XCTUnwrap(object["lines"] as? [[String: Any]])
        XCTAssertEqual(lines.count, 79)
        for line in lines {
            let text = try XCTUnwrap(line["text"] as? String)
            let file = try XCTUnwrap(line["file"] as? String)
            XCTAssertNotNil(
                SpeechService.bundledURL(for: text),
                "Missing bundled house-voice clip \(file) for \(text)"
            )
        }
    }

    func testSlugRuleMatchesCatalogAndDoesNotInventPersonalizedSpeech() {
        XCTAssertEqual(SpeechService.slug(for: "Seo Bríd, m'iníon."), "seo-briid-m-iniion")
        XCTAssertEqual(SpeechService.slug(for: "Cén t-ainm atá ort?"), "ceen-t-ainm-ataa-ort")
        XCTAssertNil(SpeechService.bundledURL(for: "Is mise Saoirse."))
    }
}
