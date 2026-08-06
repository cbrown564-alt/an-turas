from __future__ import annotations

import sys
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools"))

import rank_slice_candidates as ranker  # noqa: E402


def member(**overrides):
    base = {
        "id": "test.member",
        "irish": {"text": "Tá an fharraige anseo.", "inventory_slug": "slug"},
        "english": {"intent": "The sea is here."},
        "exercise_consumers": [],
        "risk_flags": [],
        "target": {},
    }
    base.update(overrides)
    return base


class StoryRelevanceTest(unittest.TestCase):
    chapters = {"mayo.clew-bay.opening": "mayo.clew-bay"}

    def test_chapter_bound_in_scope_story_scores_top(self):
        score, bound, _ = ranker.score_story_relevance(
            member(
                exercise_consumers=[{"record_id": "mayo.clew-bay.opening"}],
            ),
            chapters=self.chapters,
            story_ids={"mayo.grainne-1593"},
        )
        self.assertEqual(score, 5)
        self.assertEqual(bound, ["mayo.clew-bay"])

    def test_consumer_not_in_pack_scores_lower(self):
        score, bound, reasons = ranker.score_story_relevance(
            member(exercise_consumers=[{"record_id": "d32.mayo.ask-what.08"}]),
            chapters=self.chapters,
            story_ids={"d32.mayo.grainne-1593"},
        )
        self.assertEqual(score, 3)
        self.assertEqual(bound, [])
        self.assertIn("consumer_not_chapter_bound", reasons)

    def test_out_of_scope_story_scores_lowest(self):
        score, _, reasons = ranker.score_story_relevance(
            member(exercise_consumers=[{"record_id": "x"}]),
            chapters=self.chapters,
            story_ids={"d32.tyrone.hugh-oneill-dungannon"},
        )
        self.assertEqual(score, 1)
        self.assertIn("out_of_scope_story", reasons)


class ReuseTest(unittest.TestCase):
    def test_conflicting_intent_duplicate_scores_zero(self):
        score, reasons = ranker.score_reuse(
            member(),
            risk_item={},
            duplicate_group=[{"counties": ["mayo", "galway"]}],
            intent_conflict=True,
        )
        self.assertEqual(score, 0)
        self.assertIn("conflicting_intent_duplicate", reasons)

    def test_consistent_duplicate_across_counties_scores_up(self):
        conflicting, _ = ranker.score_reuse(
            member(exercise_consumers=[{}, {}]),
            risk_item={"placement_ids": ["atlas.mayo.01"]},
            duplicate_group=[{"counties": ["mayo", "galway"]}],
            intent_conflict=True,
        )
        consistent, _ = ranker.score_reuse(
            member(exercise_consumers=[{}, {}]),
            risk_item={"placement_ids": ["atlas.mayo.01"]},
            duplicate_group=[{"counties": ["mayo", "galway"]}],
            intent_conflict=False,
        )
        self.assertGreater(consistent, conflicting)


class PedagogyTest(unittest.TestCase):
    def test_d30_pattern_with_sidecar_scores_top(self):
        score, _ = ranker.score_pedagogy(
            member(),
            patterns={"surround_change": True, "delayed_reuse": False},
            in_sidecar=True,
        )
        self.assertEqual(score, 5)

    def test_d30_pattern_detected_from_use_and_response_family(self):
        from_use = ranker.consumer_patterns(
            member(exercise_consumers=[{"use": "surround-change production"}])
        )
        self.assertTrue(from_use["surround_change"])
        from_family = ranker.consumer_patterns(
            member(exercise_consumers=[{"response_family": "sentenceConstruction"}])
        )
        self.assertTrue(from_family["surround_change"])
        delayed = ranker.consumer_patterns(
            member(exercise_consumers=[{"use": "delayed retrieval"}])
        )
        self.assertTrue(delayed["delayed_reuse"])


class RiskTest(unittest.TestCase):
    bounds = (10.0, 26.0)

    def test_near_universal_flags_do_not_contribute(self):
        plain, _, ignored = ranker.score_risk(
            member(risk_flags=["invented_text", "audio_pronunciation"]),
            risk_item={"risk_score": 10},
            intent_conflict=False,
            risk_score_bounds=self.bounds,
        )
        self.assertEqual(plain, 0.0)
        self.assertEqual(ignored, ["audio_pronunciation", "invented_text"])

    def test_discriminating_flags_add_penalty(self):
        penalty, reasons, _ = ranker.score_risk(
            member(risk_flags=["sense_ambiguity"]),
            risk_item={"risk_score": 10, "categories": ["names"]},
            intent_conflict=False,
            risk_score_bounds=self.bounds,
        )
        self.assertEqual(penalty, 5.0)
        self.assertIn("flag:sense_ambiguity", reasons)
        self.assertIn("category:names", reasons)

    def test_calibration_spreads_a_saturated_pool(self):
        raw = [8.0, 8.0, 9.0, 10.0, 11.0, 12.0, 20.0]
        calibrated = ranker.calibrate_risk(raw)
        self.assertEqual(min(calibrated), 0)
        self.assertGreater(max(calibrated), 0)
        self.assertEqual(len(set(calibrated)) > 1, True)


class AudioTest(unittest.TestCase):
    def test_track_d_outlier_scores_zero(self):
        score, reasons = ranker.score_audio(
            "bad-slug",
            manifest_row={"duration_seconds": 2.0},
            review_slugs={"bad-slug"},
            duration_band=(1.5, 2.5),
        )
        self.assertEqual(score, 0)
        self.assertIn("track_d_listening_review_outlier", reasons)

    def test_centre_band_beats_edge(self):
        centre, _ = ranker.score_audio(
            "a",
            manifest_row={"duration_seconds": 2.0},
            review_slugs=set(),
            duration_band=(1.5, 2.5),
        )
        edge, _ = ranker.score_audio(
            "b",
            manifest_row={"duration_seconds": 9.0},
            review_slugs=set(),
            duration_band=(1.5, 2.5),
        )
        self.assertGreater(centre, edge)


class DiscriminationTest(unittest.TestCase):
    def test_constant_criterion_is_flagged(self):
        rows = [
            {
                "subscores": {
                    "story_relevance": 3,
                    "reuse": 2,
                    "pedagogical_purpose": 2,
                    "risk": index % 5,
                    "audio_quality": 5,
                }
            }
            for index in range(20)
        ]
        report = ranker.criterion_discrimination(rows)
        self.assertTrue(report["story_relevance"]["effectively_constant"])
        self.assertFalse(report["risk"]["effectively_constant"])


class SelectionTest(unittest.TestCase):
    def _row(self, index, family, patterns=(), total=10):
        return {
            "member_id": f"m{index}",
            "family_id": family,
            "chapters": [],
            "d30_patterns": list(patterns),
            "weighted_total": total,
            "text_sha256": f"{index:064d}",
        }

    def test_family_cap_limits_a_dominant_family(self):
        rows = [self._row(index, "dominant") for index in range(40)]
        rows += [self._row(100 + index, f"other-{index}") for index in range(40)]
        result = ranker.select_slice(rows, slice_size=20)
        self.assertLessEqual(
            result["coverage"]["families"].get("dominant", 0), result["family_cap"]
        )

    def test_both_d30_patterns_are_covered_when_available(self):
        rows = [self._row(index, f"f{index}", total=100) for index in range(30)]
        rows.append(self._row(90, "late", patterns=["surround_change"], total=1))
        rows.append(self._row(91, "late", patterns=["delayed_reuse"], total=1))
        result = ranker.select_slice(rows, slice_size=10)
        covered = result["coverage"]["d30_patterns"]
        self.assertIn("surround_change", covered)
        self.assertIn("delayed_reuse", covered)

    def test_selection_is_deterministic(self):
        rows = [self._row(index, f"f{index % 5}") for index in range(50)]
        first = ranker.select_slice(rows, slice_size=15)
        second = ranker.select_slice(rows, slice_size=15)
        self.assertEqual(
            [row["member_id"] for row in first["slice"]],
            [row["member_id"] for row in second["slice"]],
        )


if __name__ == "__main__":
    unittest.main()
