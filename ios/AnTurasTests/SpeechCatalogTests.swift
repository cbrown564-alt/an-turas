import XCTest
@testable import AnTuras

@MainActor
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
        let exclusions = try XCTUnwrap(object["dynamic_exclusions"] as? [[String: Any]])
        let excludedSlugs = Set(exclusions.compactMap { $0["slug"] as? String })
        let failedSlugs = Set(lines.compactMap { line -> String? in
            guard line["qa_state"] as? String == "failed" else { return nil }
            return line["slug"] as? String
        })
        let unavailableSlugs = excludedSlugs.union(failedSlugs)

        XCTAssertEqual(
            unavailableSlugs.count,
            excludedSlugs.count + failedSlugs.subtracting(excludedSlugs).count
        )
        XCTAssertEqual(
            lines.count,
            Set(lines.compactMap { $0["slug"] as? String }).subtracting(unavailableSlugs).count
                + unavailableSlugs.count
        )
        for line in lines {
            let text = try XCTUnwrap(line["text"] as? String)
            let file = try XCTUnwrap(line["file"] as? String)
            let slug = try XCTUnwrap(line["slug"] as? String)
            if unavailableSlugs.contains(slug) {
                XCTAssertNil(SpeechService.bundledURL(for: text), "Retired clip must be unavailable: \(file)")
            } else {
                XCTAssertNotNil(
                    SpeechService.bundledURL(for: text),
                    "Missing bundled house-voice clip \(file) for \(text)"
                )
            }
        }
    }

    func testManifestExclusionsAndFailedQAAreUnavailableAtRuntime() throws {
        let manifestURL = try XCTUnwrap(
            Bundle.main.url(forResource: "manifest", withExtension: "json")
        )
        let object = try XCTUnwrap(
            JSONSerialization.jsonObject(with: Data(contentsOf: manifestURL)) as? [String: Any]
        )
        let lines = try XCTUnwrap(object["lines"] as? [[String: Any]])
        let exclusions = try XCTUnwrap(object["dynamic_exclusions"] as? [[String: Any]])
        let excludedSlugs = Set(exclusions.compactMap { $0["slug"] as? String })
        let failedSlugs = Set(lines.compactMap { line in
            line["qa_state"] as? String == "failed" ? line["slug"] as? String : nil
        })
        let unavailableLines = lines.filter { line in
            guard let slug = line["slug"] as? String else { return false }
            return excludedSlugs.contains(slug) || line["qa_state"] as? String == "failed"
        }

        XCTAssertEqual(unavailableLines.count, excludedSlugs.union(failedSlugs).count)
        let quarantinedTexts = [
            "An baile é Corca Dhuibhne?",
            "Is baile é Corca Dhuibhne.",
        ]
        for text in quarantinedTexts {
            XCTAssertFalse(SpeechService.shared.canSpeak(text), text)
            SpeechService.shared.speak(text)
            XCTAssertFalse(SpeechService.shared.speaking, text)
            XCTAssertNil(SpeechService.shared.currentText, text)
            XCTAssertNil(SpeechService.bundledURL(for: text), text)
        }
        for line in unavailableLines {
            let text = try XCTUnwrap(line["text"] as? String)
            XCTAssertNil(SpeechService.bundledURL(for: text), text)
        }
    }

    func testNamedManifestAssetsUseTheSameFailClosedPolicy() {
        let excludedAssets = [
            "an-baile-ee-corca-dhuibhne.mp3",
            "is-baile-ee-corca-dhuibhne.mp3",
        ]
        for asset in excludedAssets {
            XCTAssertFalse(SpeechService.shared.canPlayVerifiedAsset(named: asset), asset)
            XCTAssertNil(SpeechService.bundledURL(named: asset), asset)
            SpeechService.shared.playVerifiedAsset(named: asset, displayText: asset)
            XCTAssertFalse(SpeechService.shared.speaking, asset)
            XCTAssertNil(SpeechService.shared.currentText, asset)
        }

        XCTAssertTrue(SpeechService.shared.canPlayVerifiedAsset(named: "sean.mp3"))
        XCTAssertNotNil(SpeechService.bundledURL(named: "sean.mp3"))
    }

    func testNamedLookupFailsClosedWhenCatalogCannotLoad() {
        let missingCatalog = SpeechRuntimeCatalog.index(from: nil)
        let malformedCatalog = SpeechRuntimeCatalog.index(from: Data("{not-json".utf8))
        let unavailableCatalog = SpeechRuntimeIndex.unavailable

        for catalog in [missingCatalog, malformedCatalog, unavailableCatalog] {
            XCTAssertFalse(catalog.isLoaded)
            XCTAssertNil(
                SpeechService.bundledURL(named: "sean.mp3", using: catalog),
                "Named assets must fail closed without a loaded catalog"
            )
        }

        XCTAssertNotNil(
            SpeechService.bundledURL(named: "sean.mp3", using: SpeechRuntimeCatalog.index),
            "A separate verified recording remains available with a loaded catalog"
        )
        XCTAssertNil(
            SpeechService.bundledURL(
                named: "an-baile-ee-corca-dhuibhne.mp3",
                using: SpeechRuntimeCatalog.index
            )
        )
    }

    func testSlugRuleMatchesCatalogAndDoesNotInventPersonalizedSpeech() {
        XCTAssertEqual(SpeechService.slug(for: "Seo Bríd, m'iníon."), "seo-briid-m-iniion")
        XCTAssertEqual(SpeechService.slug(for: "Cén t-ainm atá ort?"), "ceen-t-ainm-ataa-ort")
        XCTAssertNil(SpeechService.bundledURL(for: "Is mise Saoirse."))
    }
}
