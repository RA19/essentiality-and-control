"""Analytical and research-data checks for the figure-producing dynamics."""

from pathlib import Path
import unittest
import numpy as np
from scipy.io import loadmat
from grnlab.boolean import BooleanNetwork, decode_policy, cycle_distance, exact_basins

ROOT = Path(__file__).resolve().parents[1]


class DynamicsTests(unittest.TestCase):
    def test_single_inverter_has_a_period_two_cycle(self):
        network = BooleanNetwork(
            np.array([[1], [0]]), np.array([[1]]), [1], ["inverter"]
        )
        orbit = network.orbit([0])
        self.assertEqual(len(orbit.cycle), 2)
        self.assertEqual(orbit.key, network.orbit([1]).key)
        self.assertEqual(
            cycle_distance(orbit.cycle, np.roll(orbit.cycle, 1, axis=0)), 0
        )

    def test_a_clamp_is_applied_before_the_first_update(self):
        # A holds its initial value; B copies A. Setting A=1 affects B at t=1.
        network = BooleanNetwork(
            np.array([[0, 0], [1, 1]]), np.array([[1, 1]]), [1, 1], ["A", "B"]
        )
        np.testing.assert_array_equal(network.step([0, 0], {0: 1}), [1, 1])
        np.testing.assert_array_equal(network.step([[0, 0], [1, 1]]), [[0, 0], [1, 1]])

    def test_policy_encoding_and_contradictions(self):
        self.assertEqual(decode_policy([1, 6], 4), {0: 0, 1: 1})
        with self.assertRaises(ValueError):
            decode_policy([1, 5], 4)
        with self.assertRaises(ValueError):
            decode_policy([0], 4)

    def test_exact_basin_counts_for_a_two_node_copy_network(self):
        network = BooleanNetwork(
            np.array([[0, 0], [1, 1]]), np.array([[1, 1]]), [1, 1], ["A", "B"]
        )
        result = exact_basins(network, {})
        self.assertEqual(sorted(result["sizes"].tolist()), [2, 2])
        self.assertEqual([len(c) for c in result["cycles"]], [1, 1])
        controlled = exact_basins(network, {}, {0: 1})
        self.assertEqual(controlled["sizes"].tolist(), [4])

    def test_inhibitory_and_activating_edges_come_from_truth_tables(self):
        network = BooleanNetwork(
            np.array([[0, 1], [1, 0]]), np.array([[1, 1]]), [1, 1], ["A", "notA"]
        )
        self.assertIn((0, 1, -1), network.signed_edges())
        self.assertIn((0, 0, 1), network.signed_edges())

    def test_all_tcell_single_step_states_match_the_native_truth_tables(self):
        native = loadmat(
            ROOT / "code/control-gpb/TCellNetworkData.mat", simplify_cells=True
        )["NetData"]
        network = BooleanNetwork(
            native["F"], native["varF"], native["nv"], [str(i) for i in range(40)]
        )
        states = np.random.default_rng(17).integers(0, 2, (100, 40), dtype=np.uint8)
        actual = network.step(states)
        for row, x in enumerate(states):
            for node, k in enumerate(network.nv):
                index = sum(
                    int(x[parent]) * 2 ** (k - j - 1)
                    for j, parent in enumerate(network.inputs[node])
                )
                self.assertEqual(actual[row, node], native["F"][index, node])

    def test_bundled_models_match_the_readable_network_definitions(self):
        # Independently expand the BNS patterns, including don't-care bits.
        for model, path, fixed in [
            ("essentiality", "code/essentiality/thelper.txt", {0: 0, 2: 0, 4: 0, 8: 0}),
            ("control", "code/control-gpb/Tcell.txt", {}),
        ]:
            native = loadmat(
                ROOT / ("results/demo/" + model + ".mat"), simplify_cells=True
            )["result"]
            rules = {}
            node = None
            for line in (ROOT / path).read_text(encoding="utf-8").splitlines():
                if line.startswith(".n "):
                    values = list(map(int, line.split()[1:]))
                    node = values[0] - 1
                    rules[node] = (np.array(values[2:]) - 1, [])
                elif line and not line.startswith("#"):
                    rules[node][1].append(line.split())
            for node, (parents, patterns) in rules.items():
                for index in range(2 ** int(native["nv"][node])):
                    if node in fixed:
                        expected = fixed[node]
                    else:
                        bits = list(format(index, "0%db" % len(parents)))
                        matches = {
                            int(output)
                            for pattern, output in patterns
                            if all(a == "-" or a == b for a, b in zip(pattern, bits))
                        }
                        self.assertEqual(len(matches), 1, (model, node, index, matches))
                        expected = matches.pop()
                    self.assertEqual(
                        native["F"][index, node], expected, (model, node, index)
                    )

    def test_all_supplied_search_policies_are_legal(self):
        control = loadmat(ROOT / "results/demo/control.mat", simplify_cells=True)[
            "result"
        ]
        rows = [control["gpb"]["InitialSolution"], *control["gpb"]["EvaluatedMoves"]]
        if "uct" in control:
            rows.extend(control["uct"]["SolutionsApplied"])
        for row in rows:
            policy = decode_policy(row, 40)
            self.assertEqual(len(policy), 3)
            self.assertNotIn(int(control["target"]) - 1, policy)

    def test_dp_direction_labels_and_predecessors(self):
        data = loadmat(ROOT / "results/demo/essentiality.mat", simplify_cells=True)[
            "result"
        ]
        for value in [0, 1]:
            scores = data["sa%d" % value]["scores"]
            parents = data["sa%d" % value]["predecessor"]
            for source in range(23):
                row = source + (0 if value == 1 else 23)
                np.testing.assert_array_equal(scores[row, :, source], 1)
                np.testing.assert_array_equal(scores[(row + 23) % 46, :, source], 0)
                for t in range(1, scores.shape[1]):
                    for node in np.flatnonzero(scores[:, t, source] > 0):
                        parent = int(parents[node, t, source]) - 1
                        self.assertGreaterEqual(parent, 0)
                        self.assertGreater(scores[parent, t - 1, source], 0)


if __name__ == "__main__":
    unittest.main()
