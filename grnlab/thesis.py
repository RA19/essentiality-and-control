"""Redraw two historical results from explicitly sourced research tables.

These figures read the transcribed thesis data in results/thesis; they do not
reinterpret the current seeded demonstrations as historical experiments.
"""

import csv
from pathlib import Path

import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch

from .figures import INK, TEAL, MUTED, style, title


def read_values(path, label, value):
    with path.open(encoding="utf-8", newline="") as handle:
        return {row[label]: float(row[value]) for row in csv.DictReader(handle)}


def card(fig):
    fig.add_artist(
        FancyBboxPatch(
            (0.66, 0.23),
            0.30,
            0.57,
            boxstyle="round,pad=0.012,rounding_size=0.02",
            transform=fig.transFigure,
            facecolor="#eff7f6",
            edgecolor="none",
            zorder=0,
        )
    )


def save(fig, out, name):
    fig.savefig(out / (name + ".png"), dpi=160)
    path = out / (name + ".svg")
    fig.savefig(path, metadata={"Date": None})
    path.write_text(
        "\n".join(
            line.rstrip() for line in path.read_text(encoding="utf-8").splitlines()
        )
        + "\n",
        encoding="utf-8",
    )
    plt.close(fig)


def essentiality_result(root, out):
    values = read_values(
        root / "results/thesis/essentiality_thelper_overexpression.csv",
        "method",
        "top_rank_cost",
    )
    baseline = min(v for name, v in values.items() if name != "EPP-DP")
    reduction = 100 * (baseline - values["EPP-DP"]) / baseline
    names = sorted(values, key=values.get)
    fig = plt.figure(figsize=(13.5, 6.4))
    title(
        fig,
        "Better prioritization of high-impact perturbations",
        "T-helper differentiation | overexpression | comparison with four static centralities",
    )
    ax = fig.add_axes([0.19, 0.25, 0.40, 0.52])
    ax.barh(
        range(len(names)),
        [values[n] for n in names],
        height=0.54,
        color=[TEAL if n == "EPP-DP" else "#aab9c9" for n in names],
    )
    ax.set_yticks(range(len(names)), names, fontsize=11)
    ax.invert_yaxis()
    ax.set_xlim(0, 55)
    ax.set_xlabel("Top Rank Cost (lower is better)", labelpad=12)
    ax.grid(axis="x", color="#edf0f4")
    ax.set_axisbelow(True)
    for i, name in enumerate(names):
        ax.text(
            values[name] + 0.8,
            i,
            "%g" % values[name],
            va="center",
            fontweight="bold",
            color=TEAL if name == "EPP-DP" else INK,
        )
    card(fig)
    fig.text(
        0.69, 0.69, "%.1f%%" % reduction, fontsize=44, fontweight="bold", color=TEAL
    )
    fig.text(0.69, 0.61, "lower ranking cost", fontsize=16, fontweight="bold")
    fig.text(0.69, 0.55, "than the best static baseline", fontsize=11, color=MUTED)
    fig.text(0.69, 0.42, "An overlooked regulator", fontsize=11, fontweight="bold")
    fig.text(
        0.69,
        0.35,
        "IFN-\u03b2R reached EPP rank 4",
        fontsize=14,
        fontweight="bold",
        color=TEAL,
    )
    fig.text(
        0.69,
        0.28,
        "Static methods placed it near the bottom.",
        fontsize=10,
        color=MUTED,
    )
    fig.text(
        0.04,
        0.13,
        "Reference: perturbation-induced attractor changes in the Boolean model; not experimental viability.",
        fontsize=10,
        color=MUTED,
    )
    fig.text(
        0.04,
        0.065,
        "Essentiality and Control in Gene Regulatory Networks (2009) | Appendix 1.4d, PDF p. 93; Table 8.1, PDF p. 63",
        fontsize=8.8,
        color=MUTED,
    )
    save(fig, out, "thesis_essentiality_result")


def control_result(root, out):
    values = read_values(
        root / "results/thesis/control_zap70_neutralization.csv",
        "strategy",
        "final_reward",
    )
    direct = values["Direct control"]
    controlled = values["UCT with neutralization"]
    fig = plt.figure(figsize=(13.5, 6.4))
    title(
        fig,
        "Pair control with a neutralizing intervention",
        "T-cell receptor signaling | ZAP70 target ON | separate experiment allowing direct target intervention",
    )
    ax = fig.add_axes([0.22, 0.29, 0.37, 0.43])
    ax.barh([0, 1], [direct, controlled], height=0.42, color=["#aab9c9", TEAL])
    ax.set_yticks(
        [0, 1],
        ["Direct control\nZAP70 ON", "UCT policy\nZAP70 ON + LAT OFF + x"],
        fontsize=10,
    )
    ax.invert_yaxis()
    ax.set_xlim(0, 1)
    ax.set_xticks([0, 0.25, 0.5, 0.75, 1])
    ax.set_xlabel(
        "Final reward: preservation \u00d7 control (higher is better)", labelpad=12
    )
    ax.grid(axis="x", color="#edf0f4")
    ax.set_axisbelow(True)
    for i, value in enumerate([direct, controlled]):
        ax.text(
            value - 0.015,
            i,
            "%.4f" % value,
            va="center",
            ha="right",
            color="white",
            fontweight="bold",
            fontsize=13,
        )
    card(fig)
    fig.text(
        0.69,
        0.69,
        "+%.4f" % (controlled - direct),
        fontsize=40,
        fontweight="bold",
        color=TEAL,
    )
    fig.text(0.69, 0.61, "absolute reward gain", fontsize=16, fontweight="bold")
    fig.text(
        0.69, 0.49, "ZAP70 ON controls the target.", fontsize=12, fontweight="bold"
    )
    fig.text(
        0.69,
        0.42,
        "LAT OFF acts as a neutralizer.",
        fontsize=12,
        fontweight="bold",
        color=TEAL,
    )
    fig.text(0.69, 0.30, "x = an ineffective third mutation", fontsize=10, color=MUTED)
    fig.text(
        0.04,
        0.13,
        "Reported composite rewards, not success percentages. This experiment permits clamping the target itself.",
        fontsize=10,
        color=MUTED,
    )
    fig.text(
        0.04,
        0.065,
        "Essentiality and Control in Gene Regulatory Networks (2009) | Section 8.3.1, Table 8.3 | printed p. 55, PDF p. 66",
        fontsize=8.8,
        color=MUTED,
    )
    save(fig, out, "thesis_control_result")


def render_thesis_results(root):
    """Build both result figures from the archived table values."""
    root = Path(root)
    out = root / "docs/figures"
    out.mkdir(parents=True, exist_ok=True)
    style()
    essentiality_result(root, out)
    control_result(root, out)
