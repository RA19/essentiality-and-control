"""Connect native EPP-DP/control outputs to exact Boolean-state analysis."""

from collections import Counter
import csv
import json
from pathlib import Path
import numpy as np
from scipy.io import loadmat
from .boolean import BooleanNetwork, decode_policy, exact_basins, cycle_distance


def clean_name(name):
    return str(name).replace("\\beta", "β").replace("\\gamma", "γ").strip()


TCELL_NAMES = [
    "CD45",
    "CD8",
    "TCRlig",
    "TCRbind",
    "PAGCsk",
    "LCK",
    "Fyn",
    "Rlk",
    "TCRphos",
    "ZAP70",
    "cCbl",
    "Itk",
    "LAT",
    "Gads",
    "Slp76",
    "PLCg_b",
    "Grb2Sos",
    "DAG",
    "PLCg_a",
    "Ras",
    "RasGRP1",
    "PKCth",
    "IP3",
    "Raf",
    "MEK",
    "Ca",
    "ERK",
    "SEK",
    "IKK",
    "Calcin",
    "Rsk",
    "Fos",
    "JNK",
    "Ikb",
    "CREB",
    "Jun",
    "CRE",
    "AP1",
    "NFkB",
    "NFAT",
]


def load_results(root):
    root = Path(root)
    essentiality = loadmat(root / "results/demo/essentiality.mat", simplify_cells=True)[
        "result"
    ]
    control = loadmat(root / "results/demo/control.mat", simplify_cells=True)["result"]
    helper = BooleanNetwork(
        essentiality["F"],
        essentiality["varF"],
        essentiality["nv"],
        [clean_name(n) for n in essentiality["names"]],
    )
    tcell = BooleanNetwork(control["F"], control["varF"], control["nv"], TCELL_NAMES)
    return essentiality, control, helper, tcell


def analyze(root):
    """Calculate all data used in the figures; write compact, reusable records."""
    root = Path(root)
    epp, control, helper, tcell = load_results(root)
    # Pick the most widespread non-source pulse automatically, from computed
    # scores. The source is then named on every panel; no visual diffusion is
    # invented between frames.
    candidates = []
    for source in range(helper.n):
        score = epp["sa1"]["pulse_scores"][:, :, source].copy()
        score[[source, source + helper.n]] = 0
        candidates.append(np.sum(score))
    source = int(np.argmax(candidates))
    fixed = dict(
        zip(
            np.asarray(epp["input_nodes"]).astype(int) - 1,
            np.asarray(epp["input_values"]).astype(int),
        )
    )
    print(
        "Enumerating T-helper basins for wild type and persistent SA1 at "
        + helper.names[source],
        flush=True,
    )
    wt_basins = exact_basins(helper, fixed)
    fault_basins = exact_basins(helper, fixed, {source: 1})
    policy = decode_policy(control["policy"], tcell.n)
    starts = np.asarray(control["starts"], dtype=np.uint8)
    wt_orbits = [tcell.orbit(x) for x in starts]
    controlled_orbits = [tcell.orbit(x, policy) for x in starts]
    # Check the exact Python transition implementation against independently
    # exported native Octave attractor states. A periodic representative may
    # differ by phase; it must belong to the same complete cycle.
    for label, orbits, endpoints in [
        ("wild type", wt_orbits, control["wild_type_endpoints"]),
        ("controlled", controlled_orbits, control["controlled_endpoints"]),
    ]:
        for orbit, endpoint in zip(orbits, endpoints):
            if not np.any(np.all(orbit.cycle == endpoint, axis=1)):
                raise AssertionError("Python/native attractors disagree: " + label)
    target = int(control["target"]) - 1
    success_wt = np.array(
        [np.mean(o.cycle[:, target] == control["target_value"]) for o in wt_orbits]
    )
    success_controlled = np.array(
        [
            np.mean(o.cycle[:, target] == control["target_value"])
            for o in controlled_orbits
        ]
    )
    distances = np.array(
        [cycle_distance(a.cycle, b.cycle) for a, b in zip(wt_orbits, controlled_orbits)]
    )
    endpoint_hd = np.mean(
        np.asarray(control["wild_type_endpoints"]) != control["controlled_endpoints"]
    )
    changed = np.mean(
        np.abs(
            np.array([o.cycle.mean(axis=0) for o in wt_orbits])
            - np.array([o.cycle.mean(axis=0) for o in controlled_orbits])
        ),
        axis=0,
    )
    example = int(np.argmax((success_controlled - success_wt) * 10 + distances))
    record = {
        "essentiality": {
            "network": "T-helper differentiation",
            "nodes": helper.n,
            "dp_steps": int(epp["steps"]),
            "pulse_duration": int(epp["pulse_duration"]),
            "pulse_source": helper.names[source],
            "pulse_fault": "SA1",
            "exact_initial_states": int(wt_basins["initial_states"]),
            "wild_type_periods": [len(c) for c in wt_basins["cycles"]],
            "wild_type_basin_sizes": wt_basins["sizes"].tolist(),
            "faulted_periods": [len(c) for c in fault_basins["cycles"]],
            "faulted_basin_sizes": fault_basins["sizes"].tolist(),
        },
        "control": {
            "network": "T-cell receptor signaling",
            "nodes": tcell.n,
            "target": tcell.names[target],
            "target_value": int(control["target_value"]),
            "policy": {tcell.names[node]: value for node, value in policy.items()},
            "search_seed": int(control["search_seed"]),
            "evaluation_seed": int(control["evaluation_seed"]),
            "paired_initial_states": len(starts),
            "wild_type_attractors_observed": len({o.key for o in wt_orbits}),
            "controlled_attractors_observed": len({o.key for o in controlled_orbits}),
            "wild_type_period_counts": dict(
                Counter(str(len(o.cycle)) for o in wt_orbits)
            ),
            "controlled_period_counts": dict(
                Counter(str(len(o.cycle)) for o in controlled_orbits)
            ),
            "target_occupancy_wild_type": float(success_wt.mean()),
            "target_occupancy_controlled": float(success_controlled.mean()),
            "mean_cycle_aligned_hamming": float(distances.mean()),
            "mean_native_endpoint_hamming": float(endpoint_hd),
            "example_initial_state": example,
        },
    }
    out = root / "results/demo"
    (out / "analysis.json").write_text(
        json.dumps(record, indent=2) + "\n", encoding="utf-8"
    )
    with (out / "essentiality.csv").open("w", newline="", encoding="utf-8") as handle:
        writer = csv.writer(handle)
        writer.writerow(
            [
                "node",
                "sa0_mean_rank",
                "sa1_mean_rank",
                "sa0_total_influence",
                "sa1_total_influence",
            ]
        )
        for i, name in enumerate(helper.names):
            writer.writerow(
                [
                    name,
                    float(epp["sa0"]["mean_rank"][i]),
                    float(epp["sa1"]["mean_rank"][i]),
                    float(epp["sa0"]["influence"][i].sum()),
                    float(epp["sa1"]["influence"][i].sum()),
                ]
            )
    np.savez_compressed(
        out / "landscapes.npz",
        wt_labels=wt_basins["labels"],
        fault_labels=fault_basins["labels"],
        wild_type_cycle_occupancy=np.array([o.cycle.mean(axis=0) for o in wt_orbits]),
        controlled_cycle_occupancy=np.array(
            [o.cycle.mean(axis=0) for o in controlled_orbits]
        ),
    )
    print("Native/Python cycle agreement verified for all paired starts.", flush=True)
    return {
        "epp": epp,
        "control": control,
        "helper": helper,
        "tcell": tcell,
        "source": source,
        "wt_basins": wt_basins,
        "fault_basins": fault_basins,
        "policy": policy,
        "wt_orbits": wt_orbits,
        "controlled_orbits": controlled_orbits,
        "target": target,
        "distances": distances,
        "changed": changed,
        "record": record,
        "example": example,
    }
