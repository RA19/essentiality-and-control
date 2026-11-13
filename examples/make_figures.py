# -*- coding: utf-8 -*-
"""
Figure generator for the essentiality-and-control showcase.

Reads the CSVs written by the Octave drivers (examples/run_essentiality.m,
examples/run_control.m) in results/generated/ and renders the showcase
figures into docs/figures/.

Run from the repository root:
    python examples/make_figures.py
"""

import csv
import os
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch, FancyArrowPatch

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GEN = os.path.join(REPO, "results", "generated")
FIGDIR = os.path.join(REPO, "docs", "figures")
os.makedirs(FIGDIR, exist_ok=True)

plt.rcParams.update({"font.size": 9, "figure.dpi": 120})


def read_csv(path):
    with open(path, newline="") as f:
        return np.array(
            [[float(x) for x in row] for row in csv.reader(f) if row]
        )


def read_names(path):
    with open(path) as f:
        return [l.strip() for l in f if l.strip()]


# ==================================================================
# 1) Fault propagation heatmap — EPP-DP ProbMatrix for key source nodes
# ==================================================================
names = read_names(os.path.join(GEN, "node_names.txt"))
N = len(names)

# ProbMatrix layout: rows 1..N = prob node i went 0->1 by time t;
# rows N+1..2N = prob node i went 1->0; cols = timesteps 1..5
sources = ["TCR", "IFN-\\beta R", "IL-18"]
fig, axes = plt.subplots(1, 3, figsize=(15, 5.4), sharey=True)
fig.suptitle("EPP-DP fault propagation — probability each node's output "
             "flips, t = 1…5 steps after the source mutation "
             "(T-helper differentiation network, SA0 fault)",
             fontsize=12, fontweight="bold")

for ax, src in zip(axes, sources):
    idx = names.index(src) if src in names else None
    if idx is None:
        # the text file escapes e.g. IFN-\beta
        cand = [i for i, n in enumerate(names)
                if src.replace("\\", "") in n.replace("\\", "")]
        idx = cand[0]
    pm = read_csv(os.path.join(GEN, "prob_matrix_node%02d.csv" % (idx + 1)))
    spread = pm[:N, :] + pm[N:, :]              # node x timestep flip prob
    im = ax.imshow(spread, aspect="auto", cmap="magma", vmin=0,
                   vmax=max(0.6, spread.max()))
    ax.set_title("source: %s" % src.replace("\\", ""), fontsize=10)
    ax.set_xlabel("time step")
    ax.set_yticks(range(N))
    if ax is axes[0]:
        ax.set_yticklabels([n.replace("\\", "") for n in names], fontsize=7)
        ax.set_ylabel("node")
    for j in range(1, N):
        ax.axhline(j - 0.5, color="white", lw=0.2, alpha=0.3)
    fig.colorbar(im, ax=ax, fraction=0.046, label="P(output flipped)")

fig.tight_layout(rect=[0, 0, 1, 0.92])
fig.savefig(os.path.join(FIGDIR, "fig_fault_propagation.png"), dpi=160)
plt.close(fig)
print("wrote fig_fault_propagation.png")

# ==================================================================
# 2) Error propagation over time + essentiality ranking
# ==================================================================
pv = read_csv(os.path.join(GEN, "prob_vector.csv"))     # N x T
ranks = read_csv(os.path.join(GEN, "final_ranks.csv"))  # node, mean rank

fig, axes = plt.subplots(1, 2, figsize=(14, 5.6),
                         gridspec_kw={"width_ratios": [1, 1.15]})
fig.suptitle("Gene essentiality = how broadly a malfunction propagates "
             "through the network", fontsize=12, fontweight="bold")

ax = axes[0]
order = np.argsort(-pv.sum(1))
cmap = plt.cm.viridis
for rank, i in enumerate(order):
    ax.plot(range(1, pv.shape[1] + 1), pv[i], marker="o", ms=3,
            lw=1.4, color=cmap(rank / (N - 1)),
            label=names[i].replace("\\", ""))
ax.set_xlabel("time steps after mutation")
ax.set_ylabel("Accumulated error probability\n(sum over downstream nodes)")
ax.set_title("(a) EPP per source node over time\n"
             "(colour = essentiality rank)", fontsize=10)
ax.legend(fontsize=6, ncol=2, loc="upper left", framealpha=0.9)

ax = axes[1]
top = order[:12]
ypos = np.arange(len(top))[::-1]
ax.barh(ypos, pv[top].sum(1), color="#b23a48", edgecolor="black")
ax.set_yticks(ypos)
ax.set_yticklabels([names[i].replace("\\", "") for i in top], fontsize=8)
ax.set_xlabel("EPP score (Σ error prob over nodes × timesteps)")
ax.set_title("(b) Most essential nodes — knock-out faults\n"
             "(dissertation baselines: degree / in / out / betweenness "
             "miss these)", fontsize=10)

fig.tight_layout(rect=[0, 0, 1, 0.92])
fig.savefig(os.path.join(FIGDIR, "fig_essentiality_ranking.png"), dpi=160)
plt.close(fig)
print("wrote fig_essentiality_ranking.png")

# ==================================================================
# 3) Control convergence — GPB vs UCT-RAVE
# ==================================================================
gpb_file = os.path.join(GEN, "control_gpb.csv")
uct_file = os.path.join(GEN, "control_uct.csv")
summary = ""
sfile = os.path.join(GEN, "control_summary.txt")
if os.path.exists(sfile):
    summary = open(sfile).read()

if os.path.exists(gpb_file):
    gpb = read_csv(gpb_file).ravel()
    fig, ax = plt.subplots(figsize=(11, 5))
    ax.set_title("Non-disruptive control search — reward per iteration\n"
                 "reward = (1 − attractor hamming distance) × "
                 "P(target state achieved)", fontsize=12, fontweight="bold")
    ax.plot(gpb, lw=1.0, color="#b23a48", alpha=0.45,
            label="GPB — per-iteration reward")
    # running max shows the best solution found so far
    ax.plot(np.maximum.accumulate(gpb), lw=2.0, color="#7a0d1a",
            label="GPB — best solution so far")
    if os.path.exists(uct_file):
        uct = read_csv(uct_file).ravel()
        ax.plot(np.maximum.accumulate(uct), lw=1.6, color="#1f5fa8",
                ls="--", label="UCT-RAVE — best so far")
    ax.set_xlabel("iteration")
    ax.set_ylabel("reward")
    ax.set_ylim(0, 1)
    ax.legend(loc="lower right")
    fig.tight_layout()
    fig.savefig(os.path.join(FIGDIR, "fig_control_convergence.png"), dpi=160)
    plt.close(fig)
    print("wrote fig_control_convergence.png")

# ==================================================================
# 4) Attractor landscape change under control
# ==================================================================
ap_file = os.path.join(GEN, "attractor_pairs.csv")
if os.path.exists(ap_file):
    ap = read_csv(ap_file)
    R, tot = ap.shape
    NC = 40
    orig, ctrl = ap[:, :NC], ap[:, NC:]
    tn = read_names(os.path.join(GEN, "node_names_tcell.txt"))
    tgt_line = ""
    tgt_idx = None
    for l in summary.splitlines():
        if l.startswith("target="):
            tgt_line = l
            tgt_idx = int(l.split("(")[1].split(")")[0]) - 1
    flip_prob = np.mean(np.abs(orig - ctrl), 0)
    tgt_on_orig = orig[:, tgt_idx].mean() if tgt_idx is not None else 0
    tgt_on_ctrl = ctrl[:, tgt_idx].mean() if tgt_idx is not None else 0

    fig, axes = plt.subplots(1, 2, figsize=(14.5, 5.6),
                           gridspec_kw={"width_ratios": [1.35, 1]})
    fig.suptitle("Wild-type vs controlled attractor landscape "
                 "(%d sampled start states)" % R,
                 fontsize=12, fontweight="bold")

    ax = axes[0]
    order_n = np.argsort(-flip_prob)
    ax.bar(range(NC), flip_prob[order_n],
           color=["#b23a48" if order_n[i] == tgt_idx else "#3f6fb0"
                  for i in range(NC)],
           edgecolor="black", lw=0.3)
    ax.set_xticks(range(NC))
    ax.set_xticklabels([tn[i] for i in order_n], rotation=90, fontsize=6.5)
    ax.set_ylabel("P(node differs in attractor)")
    ax.set_title("(a) Which nodes flip — the control policy barely disturbs\n"
                 "the landscape except where steering is needed",
                 fontsize=10)

    ax = axes[1]
    labels = ["Wild-type", "Controlled"]
    vals = [tgt_on_orig, tgt_on_ctrl]
    bars = ax.bar(labels, vals, color=["#3f6fb0", "#b23a48"],
                  edgecolor="black", width=0.5)
    for b, v in zip(bars, vals):
        ax.text(b.get_x() + b.get_width() / 2, v + 0.02, "%.2f" % v,
                ha="center", fontweight="bold")
    tname = tn[tgt_idx] if tgt_idx is not None else "?"
    ax.set_ylabel("P(%s = ON in attractor)" % tname)
    ax.set_ylim(0, 1.1)
    ax.set_title("(b) Target control achieved while HD stays low\n"
                 "(%s)" % tgt_line.replace("  ", ", "),
                 fontsize=10)

    fig.tight_layout(rect=[0, 0, 1, 0.92])
    fig.savefig(os.path.join(FIGDIR, "fig_attractor_change.png"), dpi=160)
    plt.close(fig)
    print("wrote fig_attractor_change.png")

# ==================================================================
# 5) Methods schematic — EPP-DP + non-disruptive control
# ==================================================================
fig, ax = plt.subplots(figsize=(13.5, 7.6))
ax.set_xlim(0, 100)
ax.set_ylim(0, 58)
ax.axis("off")
ax.set_title("Essentiality & control in Boolean gene regulatory networks",
             fontsize=13, fontweight="bold", pad=10)


def box(x, y, w, h, text, fc, fs=8, bold=False):
    ax.add_patch(FancyBboxPatch((x, y), w, h,
                 boxstyle="round,pad=0.35", fc=fc, ec="black", lw=1.1))
    ax.text(x + w / 2, y + h / 2, text, ha="center", va="center",
            fontsize=fs, fontweight="bold" if bold else "normal")


def arrow(x1, y1, x2, y2, color=(0.2, 0.2, 0.2), lw=1.5):
    ax.add_patch(FancyArrowPatch((x1, y1), (x2, y2),
                 arrowstyle="-|>", mutation_scale=12, color=color, lw=lw))


# left half — EPP-DP
box(2, 42, 20, 13, "Boolean network\n(.bns)\n\nnodes + per-node\ntruth tables",
    "#eaf2fb", bold=True)
box(2, 22, 20, 14, "Fault statistics\n\nfor each node & input state:\n"
    "P(output flips) under\nSA0 / SA1 faults\n(bias changes)", "#efe9f7",
    bold=True)
box(28, 32, 22, 16, "EPP-DP\n\nerror-propagation DP over\nt steps — "
    "prob a malfunction at\nnode i reaches each other node;\n"
    "accumulated score = essentiality", "#fdeaea", bold=True)
box(28, 12, 22, 10, "Essentiality ranking\n+ most-likely fault sequences",
    "#fdeaea", bold=True)
arrow(12, 42, 12, 36)
arrow(22, 29, 28, 36)
arrow(39, 32, 39, 22)

# right half — control
box(56, 42, 20, 13, "Same network\n+ target gene\ne.g. ZAP70 → ON",
    "#e9f7ef", bold=True)
box(56, 22, 20, 14, "Search space\n\ntriplets of SA faults\n"
    "(~80 C 3 ≈ 82k arms)\nGPB: GP posterior over\n"
    "kernel-similar arms\nUCT-RAVE: tree search", "#fff4e0", bold=True)
box(82, 32, 16, 16, "Reward\n\n(1 − HD(wild-type\natt., controlled\n"
    "att.)) × P(target\nachieved)", "#fdeaea", bold=True)
box(82, 12, 16, 10, "Control policy\n3 gene faults", "#e9f7ef", bold=True)
arrow(66, 42, 66, 36)
arrow(76, 30, 82, 36)
arrow(90, 32, 90, 22)
arrow(50, 40, 56, 45, color=(0.5, 0.5, 0.5))

ax.text(50, 4, "Both algorithms treat the network as a probabilistic "
        "state-transition system — essentiality asks where faults go;\n"
        "control asks which faults to install so the target changes "
        "while the attractor landscape is preserved",
        ha="center", fontsize=8.5, style="italic", color="#444444")

fig.savefig(os.path.join(FIGDIR, "fig_methods.png"), dpi=160,
            bbox_inches="tight")
plt.close(fig)
print("wrote fig_methods.png")
print("DONE")
