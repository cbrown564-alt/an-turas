import XCTest
@testable import AnTuras

/// Rebuild plan step 5 (schema hardening, phase B): failing fixtures for the
/// authored learning-contract rules, mirrored 1:1 with the Python validator
/// tests in tools/tests/test_validate_county_pack.py. The freeze fixture is
/// deliberately not production-gate shaped (D29: four target words, a
/// learning-only chapter, no introductions), so these tests pad it into a
/// valid envelope and then break one rule at a time.
final class CountyContractValidationTests: XCTestCase {

    // MARK: Envelope helpers

    /// The freeze fixture padded into a validator-clean envelope: twenty
    /// target words, one story-visible narrative page that introduces the four
    /// fixture lexemes ahead of the nine frozen steps.
    private func validFreezeEnvelope() throws -> [String: Any] {
        let url = Bundle.main.url(
            forResource: "mayo.clew-bay-freeze",
            withExtension: "json",
            subdirectory: "Fixtures"
        ) ?? Bundle.main.url(forResource: "mayo.clew-bay-freeze", withExtension: "json")
        let data = try Data(contentsOf: try XCTUnwrap(url))
        var envelope = try XCTUnwrap(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        var pack = try XCTUnwrap(envelope["pack"] as? [String: Any])
        var words = try XCTUnwrap(pack["targetWords"] as? [[String: Any]])
        for index in words.count..<20 {
            words.append([
                "ga": "padword\(index)",
                "en": "pad \(index)",
                "sound": "pad",
                "anchor": "padding",
            ])
        }
        pack["targetWords"] = words
        var chapters = try XCTUnwrap(pack["chapters"] as? [[String: Any]])
        var pages = try XCTUnwrap(chapters[0]["pages"] as? [[String: Any]])
        let intro: [String: Any] = [
            "id": "mayo.clew-bay.shoreline",
            "title": "The shoreline",
            "context": "Clew Bay",
            "body": "The sea names this coast.",
            "visibility": "both",
            "requirement": "optional",
            "kind": "narrative",
            "estimatedSeconds": 30,
            "introducedLexemeIDs": ["lex.farraige", "lex.ba", "lex.ait", "lex.as"],
            "resourceIDs": [String](),
        ]
        pages.insert(intro, at: 0)
        chapters[0]["pages"] = pages
        pack["chapters"] = chapters
        envelope["pack"] = pack
        return envelope
    }

    private func validate(_ envelope: [String: Any]) throws -> CountyPackReport {
        let data = try JSONSerialization.data(withJSONObject: envelope)
        let decoded = try JSONDecoder().decode(CountyStoryPackEnvelope.self, from: data)
        return try CountyStoryPackValidator.validate(decoded)
    }

    private func expectError(
        _ expected: CountyStoryPackError,
        file: StaticString = #filePath,
        line: UInt = #line,
        mutate: (inout [String: Any]) -> Void
    ) throws {
        var envelope = try validFreezeEnvelope()
        mutate(&envelope)
        let data = try JSONSerialization.data(withJSONObject: envelope)
        let decoded = try JSONDecoder().decode(CountyStoryPackEnvelope.self, from: data)
        XCTAssertThrowsError(try CountyStoryPackValidator.validate(decoded), file: file, line: line) { error in
            XCTAssertEqual(error as? CountyStoryPackError, expected, file: file, line: line)
        }
    }

    private func mutatePage(
        _ pageID: String,
        in envelope: inout [String: Any],
        _ body: (inout [String: Any]) -> Void
    ) {
        var pack = envelope["pack"] as! [String: Any]
        var chapters = pack["chapters"] as! [[String: Any]]
        for chapterIndex in chapters.indices {
            var pages = chapters[chapterIndex]["pages"] as! [[String: Any]]
            for pageIndex in pages.indices where pages[pageIndex]["id"] as? String == pageID {
                body(&pages[pageIndex])
            }
            chapters[chapterIndex]["pages"] = pages
        }
        pack["chapters"] = chapters
        envelope["pack"] = pack
    }

    private func mutateExercise(
        _ pageID: String,
        in envelope: inout [String: Any],
        _ body: (inout [String: Any]) -> Void
    ) {
        mutatePage(pageID, in: &envelope) { page in
            var exercise = page["exercise"] as! [String: Any]
            body(&exercise)
            page["exercise"] = exercise
        }
    }

    private func mutateContract(
        of pageID: String,
        in envelope: inout [String: Any],
        _ body: (inout [String: Any]) -> Void
    ) {
        mutateExercise(pageID, in: &envelope) { exercise in
            var contract = exercise["learningContract"] as! [String: Any]
            body(&contract)
            exercise["learningContract"] = contract
        }
    }

    // MARK: Positive control

    func testPaddedFreezeFixturePassesWithFullContractCoverage() throws {
        let report = try validate(try validFreezeEnvelope())

        XCTAssertEqual(report.contractAuthoredCount, 9)
        XCTAssertEqual(report.contractAdaptedCount, 0)
        XCTAssertGreaterThan(report.distractorCount, 0)
        XCTAssertEqual(report.distractorsMapped, report.distractorCount)
        XCTAssertEqual(
            Set(report.completionEvidenceKinds),
            [
                .correctSelection, .correctConstruction, .correctedConstruction,
                .reconstructedResponse, .validDialogueTurn, .completedRecordCompare,
            ]
        )
    }

    // MARK: Authored-contract rules

    func testMissingMisconceptionMappingWithoutID() throws {
        try expectError(.missingMisconceptionMapping("mayo.clew-bay.listen-farraige")) { envelope in
            mutateExercise("mayo.clew-bay.listen-farraige", in: &envelope) { exercise in
                var options = exercise["options"] as! [[String: Any]]
                options[1]["misconceptionID"] = NSNull()
                exercise["options"] = options
            }
        }
    }

    func testMissingMisconceptionMappingUndeclaredID() throws {
        try expectError(.missingMisconceptionMapping("mayo.clew-bay.listen-farraige")) { envelope in
            mutateExercise("mayo.clew-bay.listen-farraige", in: &envelope) { exercise in
                var options = exercise["options"] as! [[String: Any]]
                options[1]["misconceptionID"] = "ghost"
                exercise["options"] = options
            }
        }
    }

    func testMissingDiagnosticCases() throws {
        try expectError(.missingDiagnosticCases("mayo.clew-bay.build-origin")) { envelope in
            mutateContract(of: "mayo.clew-bay.build-origin", in: &envelope) { contract in
                contract["misconceptions"] = [[String: Any]]()
            }
        }
    }

    func testAnswerRevealingHintEqual() throws {
        try expectError(.answerRevealingHint("mayo.clew-bay.type-origin")) { envelope in
            mutateExercise("mayo.clew-bay.type-origin", in: &envelope) { exercise in
                var contract = exercise["learningContract"] as! [String: Any]
                contract["hint"] = exercise["answer"]
                exercise["learningContract"] = contract
            }
        }
    }

    func testAnswerRevealingHintContainsFadaFolded() throws {
        // The accepted answer folded and lowercased still counts as revealing.
        try expectError(.answerRevealingHint("mayo.clew-bay.type-origin")) { envelope in
            mutateContract(of: "mayo.clew-bay.type-origin", in: &envelope) { contract in
                contract["hint"] = "Write it once: is as maigh eo me. — then check."
            }
        }
    }

    func testTargetChangingRecovery() throws {
        try expectError(.targetChangingRecovery("mayo.clew-bay.build-origin")) { envelope in
            mutateContract(of: "mayo.clew-bay.build-origin", in: &envelope) { contract in
                var recovery = contract["recovery"] as! [String: Any]
                recovery["targetIDs"] = ["lex.farraige"]
                contract["recovery"] = recovery
            }
        }
    }

    func testRecoveryRestatingTheSameTargetsPasses() throws {
        var envelope = try validFreezeEnvelope()
        mutateContract(of: "mayo.clew-bay.build-origin", in: &envelope) { contract in
            var recovery = contract["recovery"] as! [String: Any]
            recovery["targetIDs"] = ["lex.as"]
            contract["recovery"] = recovery
        }

        XCTAssertEqual(try validate(envelope).contractAuthoredCount, 9)
    }

    func testUnsupportedCompletionEvidence() throws {
        try expectError(.unsupportedCompletionEvidence("mayo.clew-bay.speak-origin")) { envelope in
            mutateContract(of: "mayo.clew-bay.speak-origin", in: &envelope) { contract in
                contract["completionEvidence"] = "correctSelection"
            }
        }
    }

    func testOffTargetMemoryCredit() throws {
        try expectError(.offTargetMemoryCredit("mayo.clew-bay.build-origin")) { envelope in
            mutateContract(of: "mayo.clew-bay.build-origin", in: &envelope) { contract in
                contract["targets"] = [["id": "lex.ba", "capability": "produced"]]
            }
        }
    }

    // MARK: C3 / C5 container rules

    func testUntraceableReviewTarget() throws {
        try expectError(.untraceableReviewTarget("mayo.clew-bay.review-struggle")) { envelope in
            mutateExercise("mayo.clew-bay.review-struggle", in: &envelope) { exercise in
                var candidates = exercise["reviewCandidates"] as! [[String: Any]]
                var embedded = candidates[0]["exercise"] as! [String: Any]
                embedded["lexemeIDs"] = ["lex.ba"]
                candidates[0]["exercise"] = embedded
                exercise["reviewCandidates"] = candidates
            }
        }
    }

    func testUnsupportedCapabilityClaim() throws {
        try expectError(.unsupportedCapabilityClaim("mayo.clew-bay.completion")) { envelope in
            mutatePage("mayo.clew-bay.shoreline", in: &envelope) { page in
                page["introducedLexemeIDs"] = ["lex.farraige", "lex.ba", "lex.ait", "lex.as", "lex.solas"]
            }
            mutateExercise("mayo.clew-bay.completion", in: &envelope) { exercise in
                exercise["lexemeIDs"] = ["lex.solas"]
                var contract = exercise["learningContract"] as! [String: Any]
                contract["targets"] = [["id": "lex.solas", "capability": "recognised"]]
                exercise["learningContract"] = contract
            }
        }
    }

    // MARK: Pre-existing codes without Swift-side fixtures

    func testInvalidMatchingBoard() throws {
        try expectError(.invalidMatchingBoard("mayo.clew-bay.match-coast")) { envelope in
            mutateExercise("mayo.clew-bay.match-coast", in: &envelope) { exercise in
                exercise["pairs"] = [[String: Any]]()
            }
        }
    }

    func testInvalidConversationGraph() throws {
        try expectError(.invalidConversationGraph("mayo.clew-bay.conversation-origin")) { envelope in
            mutateExercise("mayo.clew-bay.conversation-origin", in: &envelope) { exercise in
                var graph = exercise["conversation"] as! [String: Any]
                var nodes = graph["nodes"] as! [[String: Any]]
                var replies = nodes[0]["replies"] as! [[String: Any]]
                replies[0]["next"] = "nowhere"
                nodes[0]["replies"] = replies
                graph["nodes"] = nodes
                exercise["conversation"] = graph
            }
        }
    }

    func testPrematureLexeme() throws {
        try expectError(.prematureLexeme("mayo.clew-bay.build-origin")) { envelope in
            mutatePage("mayo.clew-bay.shoreline", in: &envelope) { page in
                page["introducedLexemeIDs"] = ["lex.farraige", "lex.ba", "lex.ait"]
            }
        }
    }
}

/// The runtime enums and the shared documented list in
/// `Fixtures/contract-enums.json` must match exactly, so a pack cannot pass
/// the offline gate and fail after decoding (rebuild plan, "Automated
/// enforcement"). Python parity: SharedEnumList in
/// tools/tests/test_validate_county_pack.py.
final class CountyContractEnumsParityTests: XCTestCase {
    private func sharedList() throws -> [String: Any] {
        let url = Bundle.main.url(
            forResource: "contract-enums",
            withExtension: "json",
            subdirectory: "Fixtures"
        ) ?? Bundle.main.url(forResource: "contract-enums", withExtension: "json")
        let data = try Data(contentsOf: try XCTUnwrap(url))
        return try XCTUnwrap(try JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    func testRuntimeEnumsMatchTheSharedList() throws {
        let list = try sharedList()
        func strings(_ key: String) -> Set<String> {
            Set((list[key] as? [String]) ?? [])
        }

        // Conversation is a D27 distribution container but carries a response
        // method, so the shared list counts it with the response families; the
        // two lists together enumerate every family exactly once.
        XCTAssertTrue(strings("responseFamilies").isDisjoint(with: strings("pureContainers")))
        XCTAssertEqual(
            strings("responseFamilies").union(strings("pureContainers")),
            Set(CountyExerciseFamily.allCases.map(\.rawValue))
        )
        XCTAssertEqual(
            strings("targetCapabilities"),
            Set(CountyTargetCapability.allCases.map(\.rawValue))
        )
        XCTAssertEqual(
            strings("completionEvidenceKinds"),
            Set(CountyCompletionEvidence.allCases.map(\.rawValue))
        )
        XCTAssertEqual(
            strings("memoryEventKinds"),
            Set(CountyMemoryEventKind.allCases.map(\.rawValue))
        )
        // authoredUse has no runtime enum; assert the documented D27 list from
        // CountyExercise.authoredUse.
        XCTAssertEqual(strings("authoredUses"), ["ordering", "audioPrompted", "delayedRecall"])
    }

    func testCompatibilityTableCoversTheAdapterDefaults() throws {
        // Every evidence kind the deterministic adapter can declare must be a
        // kind the validator accepts for that family, in both uses.
        for family in CountyExerciseFamily.allCases {
            for authoredUse in [nil, "ordering", "audioPrompted", "delayedRecall"] {
                let adapted = family.adaptedCompletionEvidence(
                    authoredUse: authoredUse,
                    reviewCandidate: nil
                )
                if let adapted {
                    XCTAssertTrue(
                        family.compatibleCompletionEvidence.contains(adapted),
                        "\(family.rawValue) \(authoredUse ?? "plain")"
                    )
                } else {
                    XCTAssertTrue(family.compatibleCompletionEvidence.isEmpty, family.rawValue)
                }
            }
        }
    }
}
