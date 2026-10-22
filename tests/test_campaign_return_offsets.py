"""QA counters follow real Q02 loot outings, never a rerolled one-trip assumption."""
import copy
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from tools.verify_migration import q02_extra_returns as source_offset
from tools.build_local_windows import q02_extra_returns as build_offset


def sample(trips):
    before = {"successful_sorties": 2, "narrative_slice": {"settled": {"Q01": True, "Q02": False}}}
    after = {"successful_sorties": 2 + trips, "narrative_slice": {"settled": {"Q01": True, "Q02": True}}, "sortie_checkpoint": {}}
    return copy.deepcopy(after), {"profile_before": before, "profile_after": after, "outings": [{"number": i + 1} for i in range(trips)]}


class ActualReturnOffsets(unittest.TestCase):
    def test_one_two_three_real_outings_and_inputs_unchanged(self):
        for function in [source_offset, build_offset]:
            for trips in [1, 2, 3]:
                with self.subTest(function=function.__module__, trips=trips):
                    profile, evidence = sample(trips)
                    before = copy.deepcopy((profile, evidence))
                    self.assertEqual(function(profile, evidence), trips - 1)
                    self.assertEqual((profile, evidence), before)

    def test_invalid_or_inconsistent_evidence_rejected(self):
        for function in [source_offset, build_offset]:
            for mutation in ["zero", "four", "lost_return", "duplicate_return", "unsettled", "pending", "duplicate_outing", "wrong_origin"]:
                with self.subTest(function=function.__module__, mutation=mutation):
                    profile, evidence = sample(2)
                    if mutation in ["zero", "four"]:
                        profile, evidence = sample(0 if mutation == "zero" else 4)
                    elif mutation == "lost_return":
                        profile["successful_sorties"] -= 1
                    elif mutation == "duplicate_return":
                        profile["successful_sorties"] += 1
                    elif mutation == "unsettled":
                        profile["narrative_slice"]["settled"]["Q02"] = False
                    elif mutation == "pending":
                        profile["sortie_checkpoint"] = {"phase": "battle"}
                    elif mutation == "duplicate_outing":
                        evidence["outings"][1]["number"] = 1
                    elif mutation == "wrong_origin":
                        evidence["profile_before"]["successful_sorties"] = 3
                    with self.assertRaises(AssertionError):
                        function(profile, evidence)


if __name__ == "__main__":
    unittest.main()
