"""Scientific figures and animations built directly from computed results."""

from io import BytesIO
from pathlib import Path
import numpy as np
import networkx as nx
import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.colors import ListedColormap
from matplotlib.patches import PathPatch, Rectangle
from matplotlib.path import Path as PlotPath
from PIL import Image

INK = "#15263f"
TEAL = "#007f86"
CORAL = "#d85d3f"
GOLD = "#f2ad43"
BLUE = "#3767a6"
MUTED = "#5d6c7e"
BASIN_COLORS = [
    "#007f86",
    "#6659a6",
    "#d48435",
    "#3671a9",
    "#b65371",
    "#7b873d",
    "#6c7d91",
    "#a26a3d",
    "#443e65",
]


def style():
    plt.rcParams.update(
        {
            "font.family": "DejaVu Sans",
            "font.size": 10,
            "text.color": INK,
            "axes.labelcolor": MUTED,
            "axes.edgecolor": "#d4dde6",
            "xtick.color": MUTED,
            "ytick.color": MUTED,
            "axes.spines.top": False,
            "axes.spines.right": False,
            "figure.facecolor": "white",
            "savefig.facecolor": "white",
            "svg.fonttype": "none",
            "svg.hashsalt": "essentiality-and-control",
        }
    )


def title(fig, heading, subtitle):
    fig.text(0.035, 0.96, heading, fontsize=21, fontweight="bold", va="top", color=INK)
    fig.text(0.035, 0.91, subtitle, fontsize=10.5, va="top", color=MUTED)


def layout(network):
    graph = nx.DiGraph()
    graph.add_nodes_from(range(network.n))
    graph.add_edges_from((a, b) for a, b, _ in network.signed_edges() if a != b)
    positions = nx.kamada_kawai_layout(graph.to_undirected())
    return graph, positions


def network_panel(
    ax,
    network,
    graph,
    positions,
    values,
    mode="activity",
    source=None,
    clamps=None,
    target=None,
    propagation=None,
):
    """Draw real functional edges, using truth-table-derived signs."""
    for sign, arrow, color in [
        (1, "-|>", "#9cabb8"),
        (-1, "-[", "#ae98a4"),
        (0, "-|>", "#b5a8c5"),
    ]:
        edges = [(a, b) for a, b, s in network.signed_edges() if s == sign and a != b]
        nx.draw_networkx_edges(
            graph,
            positions,
            ax=ax,
            edgelist=edges,
            arrowstyle=arrow,
            arrowsize=9,
            width=1.0,
            edge_color=color,
            alpha=0.60,
            node_size=650,
            connectionstyle="arc3,rad=0.07",
        )
    if propagation:
        for (a, b), weight in propagation.items():
            if a != b and graph.has_edge(a, b):
                nx.draw_networkx_edges(
                    graph,
                    positions,
                    ax=ax,
                    edgelist=[(a, b)],
                    arrowstyle="-|>",
                    arrowsize=12,
                    width=1 + 3 * weight,
                    edge_color=CORAL,
                    alpha=0.4 + 0.5 * weight,
                    node_size=650,
                    connectionstyle="arc3,rad=0.07",
                )
    colors = (
        plt.cm.YlOrRd(np.clip(values, 0, 1))
        if mode == "dp"
        else [GOLD if v else "#e1e8f0" for v in values]
    )
    borders = [
        CORAL if i in (clamps or {}) else TEAL if i == target else "#bdc9d5"
        for i in range(network.n)
    ]
    widths = [
        2.5 if i in (clamps or {}) or i == target else 0.8 for i in range(network.n)
    ]
    nx.draw_networkx_nodes(
        graph,
        positions,
        ax=ax,
        node_color=colors,
        node_size=650,
        edgecolors=borders,
        linewidths=widths,
    )
    if source is not None:
        nx.draw_networkx_nodes(
            graph,
            positions,
            ax=ax,
            nodelist=[source],
            node_size=900,
            node_color="none",
            edgecolors=INK,
            linewidths=2,
        )
    labels = {i: network.names[i] for i in range(network.n)}
    for light in [True, False]:
        selected = {
            i: name
            for i, name in labels.items()
            if (mode == "dp" and values[i] > 0.65) == light
        }
        nx.draw_networkx_labels(
            graph,
            positions,
            selected,
            ax=ax,
            font_size=7.1,
            font_weight="bold",
            font_color="white" if light else INK,
        )
    ax.margins(0.17)
    ax.set_axis_off()


def trellis_panel(ax, network, scores, predecessor, step):
    active = np.flatnonzero(scores.max(axis=1) > 1e-10)
    if len(active) > 24:
        active = np.argsort(-scores.sum(axis=1))[:24]
        active = np.sort(active)
    rows = {int(row): len(active) - 1 - i for i, row in enumerate(active)}
    for t in range(scores.shape[1]):
        for row in active:
            if t >= step or scores[row, t] <= 1e-10:
                continue
            y = rows[int(row)]
            value = scores[row, t]
            if t > 0:
                parent = int(predecessor[row, t]) - 1
                if parent in rows:
                    ax.plot(
                        [t, t + 1],
                        [rows[parent], y],
                        color=TEAL,
                        alpha=0.18 + 0.55 * value,
                        lw=0.5 + 1.7 * value,
                        zorder=1,
                    )
            ax.scatter(
                t + 1,
                y,
                s=18 + 110 * value,
                color=plt.cm.YlOrRd(value),
                edgecolors="#c7ad8f",
                linewidths=0.35,
                zorder=3,
            )
    labels = [
        network.names[int(row) % network.n] + (" ↑" if row < network.n else " ↓")
        for row in active
    ]
    ax.set_yticks([rows[int(row)] for row in active], labels, fontsize=7.2)
    ax.set_xticks(range(1, scores.shape[1] + 1))
    ax.set_xlim(0.5, scores.shape[1] + 0.5)
    ax.set_ylim(-1, len(active))
    ax.set_xlabel("Dynamic-programming time step")
    ax.tick_params(axis="y", length=0)
    ax.grid(axis="x", color="#edf0f4", lw=0.7)
    ax.set_title(
        "One maximizing predecessor per error state",
        loc="left",
        fontsize=11,
        fontweight="bold",
        pad=12,
    )


def as_image(fig):
    stream = BytesIO()
    fig.savefig(stream, format="png", dpi=110)
    stream.seek(0)
    return Image.open(stream).convert("RGB").copy()


def fault_propagation(data, out):
    network = data["helper"]
    source = data["source"]
    n = network.n
    scores = data["epp"]["sa1"]["pulse_scores"][:, :, source]
    predecessor = data["epp"]["sa1"]["pulse_predecessor"][:, :, source]
    graph, positions = layout(network)
    frames = []
    for step in range(1, scores.shape[1] + 1):
        fig = plt.figure(figsize=(15, 8))
        gs = fig.add_gridspec(
            1, 2, left=0.025, right=0.98, bottom=0.13, top=0.82, width_ratios=[1.15, 1]
        )
        title(
            fig,
            "Follow a fault through a biological network",
            "T-helper differentiation · "
            + network.names[source]
            + " forced ON for three DP steps · actual max-product recurrence",
        )
        ax = fig.add_subplot(gs[0])
        spread = np.maximum(scores[:n, step - 1], scores[n:, step - 1])
        propagation = {}
        if step > 1:
            for row in np.flatnonzero(scores[:, step - 1] > 0):
                parent = int(predecessor[row, step - 1]) - 1
                if parent >= 0:
                    edge = (parent % n, int(row) % n)
                    propagation[edge] = max(
                        propagation.get(edge, 0), float(scores[row, step - 1])
                    )
        network_panel(
            ax,
            network,
            graph,
            positions,
            spread,
            "dp",
            source=source,
            propagation=propagation,
        )
        ax.set_title(
            "t = %d  |  source %s" % (step, "held ON" if step <= 3 else "released"),
            loc="left",
            fontweight="bold",
            fontsize=12,
        )
        ax = fig.add_subplot(gs[1])
        trellis_panel(ax, network, scores, predecessor, step)
        fig.text(
            0.04,
            0.065,
            "Color: fault-path score, 0 → 1. Coral edges: maximizing transmissions. Trellis: ↑ 0→1 error; ↓ 1→0 error.",
            fontsize=9,
            color=MUTED,
        )
        fig.text(
            0.04,
            0.03,
            "Each update keeps the strongest incoming path:  V(j,t) = maxᵢ [ V(i,t−1) × local transmission likelihood ].",
            fontsize=10,
            color=TEAL,
        )
        frames.append(as_image(fig))
        if step == 3:
            fig.savefig(out / "fault_propagation.png", dpi=150)
            fig.savefig(out / "fault_propagation.svg", metadata={"Date": None})
        if step == scores.shape[1]:
            fig.savefig(out / "dp_trellis.png", dpi=150)
        plt.close(fig)
    frames[0].save(
        out / "fault_propagation.gif",
        save_all=True,
        append_images=frames[1:],
        duration=[1200] + [850] * (len(frames) - 2) + [2200],
        loop=0,
        optimize=True,
    )


def alluvial(
    ax, left_labels, right_labels, left_names, right_names, right_title="PERTURBED"
):
    """Basin-to-basin flow for the same initial states on both sides."""
    left_order = sorted(set(left_labels), key=lambda k: -np.sum(left_labels == k))
    right_order = sorted(set(right_labels), key=lambda k: -np.sum(right_labels == k))
    total = len(left_labels)
    gap = 0.018
    scale = (1 - gap * (max(len(left_order), len(right_order)) - 1)) / total

    def blocks(labels, order, x, names):
        positions = {}
        top = 1.0
        for i, label in enumerate(order):
            size = int(np.sum(labels == label))
            height = size * scale
            bottom = top - height
            positions[label] = [bottom, top]
            color = BASIN_COLORS[i % len(BASIN_COLORS)]
            ax.add_patch(
                Rectangle(
                    (x, bottom),
                    0.035,
                    height,
                    facecolor=color,
                    edgecolor="white",
                    lw=0.5,
                )
            )
            ax.text(
                x - 0.025 if x < 0.5 else x + 0.06,
                (top + bottom) / 2,
                names[label] + "  %.1f%%" % (size / total * 100),
                ha="right" if x < 0.5 else "left",
                va="center",
                fontsize=8.5,
                color=INK,
            )
            top = bottom - gap
        return positions

    left = blocks(left_labels, left_order, 0, left_names)
    right = blocks(right_labels, right_order, 1, right_names)
    left_cursor = {k: v[0] for k, v in left.items()}
    right_cursor = {k: v[0] for k, v in right.items()}
    for i, a in enumerate(left_order):
        for b in right_order:
            count = int(np.sum((left_labels == a) & (right_labels == b)))
            if not count:
                continue
            height = count * scale
            lo = left_cursor[a]
            ro = right_cursor[b]
            vertices = [
                (0.035, lo),
                (0.40, lo),
                (0.60, ro),
                (1, ro),
                (1, ro + height),
                (0.60, ro + height),
                (0.40, lo + height),
                (0.035, lo + height),
                (0.035, lo),
            ]
            codes = (
                [PlotPath.MOVETO]
                + [PlotPath.CURVE4] * 3
                + [PlotPath.LINETO]
                + [PlotPath.CURVE4] * 3
                + [PlotPath.CLOSEPOLY]
            )
            ax.add_patch(
                PathPatch(
                    PlotPath(vertices, codes),
                    facecolor=BASIN_COLORS[i % len(BASIN_COLORS)],
                    alpha=0.27,
                    edgecolor="none",
                )
            )
            left_cursor[a] += height
            right_cursor[b] += height
    ax.set_xlim(-0.43, 1.47)
    ax.set_ylim(-0.03, 1.1)
    ax.axis("off")
    ax.text(0.015, 1.055, "WILD TYPE", ha="center", fontsize=10, fontweight="bold")
    ax.text(1.02, 1.055, right_title, ha="center", fontsize=10, fontweight="bold")


def attractor_landscape(data, out):
    wt = data["wt_basins"]
    mut = data["fault_basins"]
    names = data["helper"].names
    fig = plt.figure(figsize=(15, 7.5))
    gs = fig.add_gridspec(
        1, 2, left=0.035, right=0.96, top=0.80, bottom=0.16, width_ratios=[1.1, 1]
    )
    title(
        fig,
        "A fault can reshape the attractor landscape",
        "Exact enumeration · %s initial states · fixed external inputs · persistent %s = ON"
        % (format(wt["initial_states"], ","), names[data["source"]]),
    )
    ax = fig.add_subplot(gs[0])
    alluvial(
        ax,
        wt["labels"],
        mut["labels"],
        {i: "W%d · period %d" % (i + 1, len(c)) for i, c in enumerate(wt["cycles"])},
        {i: "M%d · period %d" % (i + 1, len(c)) for i, c in enumerate(mut["cycles"])},
    )
    ax.set_title(
        "Where each initial state eventually settles",
        loc="left",
        fontsize=12,
        fontweight="bold",
        pad=12,
    )
    ax = fig.add_subplot(gs[1])
    profiles = np.array([c.mean(axis=0) for c in wt["cycles"] + mut["cycles"]])
    ax.imshow(
        profiles.T,
        aspect="auto",
        cmap=ListedColormap(["#e3eaf2", TEAL]),
        vmin=0,
        vmax=1,
    )
    ax.set_yticks(range(len(names)), names, fontsize=8)
    labels = ["W%d" % (i + 1) for i in range(len(wt["cycles"]))] + [
        "M%d" % (i + 1) for i in range(len(mut["cycles"]))
    ]
    ax.set_xticks(range(len(labels)), labels)
    ax.axvline(len(wt["cycles"]) - 0.5, color="white", lw=5)
    ax.set_title(
        "The attractor states themselves",
        loc="left",
        fontsize=12,
        fontweight="bold",
        pad=12,
    )
    ax.set_xlabel("Gray = OFF · teal = ON")
    fig.text(
        0.04,
        0.06,
        "The basin flows are exact for this synchronous Boolean model and the stated input conditions.",
        fontsize=10,
        color=MUTED,
    )
    fig.text(
        0.04,
        0.025,
        "EPP-DP is a scalable proxy for perturbation impact; these attractors are obtained independently by explicit state transitions.",
        fontsize=9.5,
        color=TEAL,
    )
    fig.savefig(out / "attractor_landscape.png", dpi=150)
    fig.savefig(out / "attractor_landscape.svg", metadata={"Date": None})
    plt.close(fig)


def essentiality_ranks(data, out):
    epp = data["epp"]
    names = data["helper"].names
    order = np.argsort((epp["sa0"]["mean_rank"] + epp["sa1"]["mean_rank"]) / 2)
    fig, axes = plt.subplots(
        1, 2, figsize=(14, 7.5), gridspec_kw={"width_ratios": [1, 1.15]}
    )
    title(
        fig,
        "Essentiality depends on how a gene is perturbed",
        "T-helper differentiation · persistent faults · mean rank across eight DP time steps · lower rank = greater influence",
    )
    y = np.arange(len(names))
    ax = axes[0]
    ax.hlines(
        y,
        epp["sa0"]["mean_rank"][order],
        epp["sa1"]["mean_rank"][order],
        color="#d2dbe6",
        lw=2,
    )
    ax.scatter(
        epp["sa0"]["mean_rank"][order],
        y,
        color=TEAL,
        s=40,
        label="SA0 · forced OFF",
        zorder=3,
    )
    ax.scatter(
        epp["sa1"]["mean_rank"][order],
        y,
        color=CORAL,
        s=40,
        label="SA1 · forced ON",
        zorder=3,
    )
    ax.set_yticks(y, [names[i] for i in order], fontsize=8)
    ax.invert_yaxis()
    ax.set_xlabel("Mean within-step rank (ties averaged)")
    ax.legend(loc="upper right", frameon=False, fontsize=8)
    ax.grid(axis="x", color="#edf0f4")
    ax = axes[1]
    influence = np.hstack(
        [epp["sa0"]["influence"][order], epp["sa1"]["influence"][order]]
    )
    im = ax.imshow(influence, aspect="auto", cmap="magma_r")
    ax.set_yticks([])
    ax.axvline(7.5, color="white", lw=4)
    ax.set_xticks(range(16), list(range(1, 9)) * 2, fontsize=8)
    ax.set_xlabel("SA0 time steps 1–8                      SA1 time steps 1–8")
    ax.set_title(
        "Total directional fault-path influence at each step", fontsize=11, loc="left"
    )
    fig.colorbar(
        im,
        ax=ax,
        fraction=0.035,
        pad=0.03,
        label="Sum of DP scores across error states",
    )
    fig.subplots_adjust(left=0.12, right=0.94, top=0.82, bottom=0.12, wspace=0.25)
    fig.savefig(out / "essentiality_ranks.png", dpi=150)
    plt.close(fig)


def control_dynamics(data, out):
    network = data["tcell"]
    graph, positions = layout(network)
    example = data["example"]
    a = data["wt_orbits"][example]
    b = data["controlled_orbits"][example]

    def state(orbit, t):
        if t < len(orbit.trajectory) - 1:
            return orbit.trajectory[t]
        return orbit.cycle[(t - orbit.transient_length) % len(orbit.cycle)]

    policy = ", ".join(
        network.names[n] + "=" + ("ON" if v else "OFF")
        for n, v in data["policy"].items()
    )
    length = max(
        a.transient_length + 2 * len(a.cycle), b.transient_length + 2 * len(b.cycle), 14
    )
    length = min(length, 28)
    frames = []
    for t in range(length):
        fig, axes = plt.subplots(1, 2, figsize=(16, 8.4))
        title(
            fig,
            "Control the target while limiting collateral change",
            "T-cell receptor signaling · GPB-selected indirect policy · " + policy,
        )
        for ax, orbit, label, clamps in [
            (axes[0], a, "Wild type", {}),
            (axes[1], b, "Controlled", data["policy"]),
        ]:
            x = state(orbit, t)
            network_panel(
                ax, network, graph, positions, x, clamps=clamps, target=data["target"]
            )
            ax.set_title(
                "%s · t=%d · %s=%s"
                % (
                    label,
                    t,
                    network.names[data["target"]],
                    "ON" if x[data["target"]] else "OFF",
                ),
                loc="left",
                fontsize=12,
                fontweight="bold",
            )
        fig.subplots_adjust(left=0.01, right=0.99, top=0.81, bottom=0.12, wspace=0.03)
        fig.text(
            0.04,
            0.065,
            "Gold = ON · gray = OFF · coral outline = intervention · teal outline = target cCbl",
            fontsize=10,
            color=MUTED,
        )
        fig.text(
            0.04,
            0.03,
            "Same initial state on both sides. All frames follow the actual Boolean truth tables; periodic attractors continue cycling.",
            fontsize=9.5,
            color=TEAL,
        )
        frames.append(as_image(fig))
        if t == length - 1:
            fig.savefig(out / "control_dynamics.png", dpi=150)
        plt.close(fig)
    frames[0].save(
        out / "control_dynamics.gif",
        save_all=True,
        append_images=frames[1:],
        duration=[1200] + [650] * (len(frames) - 2) + [2200],
        loop=0,
        optimize=True,
    )


def control_attractors(data, out):
    left = data["wt_orbits"]
    right = data["controlled_orbits"]
    network = data["tcell"]
    keys_left = sorted({o.key for o in left})
    keys_right = sorted({o.key for o in right})
    li = {k: i for i, k in enumerate(keys_left)}
    ri = {k: i for i, k in enumerate(keys_right)}
    l = np.array([li[o.key] for o in left])
    r = np.array([ri[o.key] for o in right])
    summary = data["record"]["control"]
    fig = plt.figure(figsize=(15, 8))
    gs = fig.add_gridspec(
        1, 2, left=0.04, right=0.96, bottom=0.16, top=0.79, width_ratios=[1.1, 1]
    )
    title(
        fig,
        "Wild-type attractors → controlled attractors",
        "%d paired initial states · complete cycles retained · target cCbl → ON"
        % len(left),
    )
    ax = fig.add_subplot(gs[0])
    alluvial(
        ax,
        l,
        r,
        {i: "W%d · p%d" % (i + 1, len(k)) for i, k in enumerate(keys_left)},
        {i: "C%d · p%d" % (i + 1, len(k)) for i, k in enumerate(keys_right)},
        right_title="CONTROLLED",
    )
    ax.set_title(
        "Sampled basin transitions (p = cycle period)",
        fontsize=12,
        fontweight="bold",
        loc="left",
        pad=12,
    )
    ax = fig.add_subplot(gs[1])
    profile = np.array([np.mean(k, axis=0) for k in keys_left + keys_right])
    image = ax.imshow(profile.T, aspect="auto", cmap="YlGnBu", vmin=0, vmax=1)
    fig.colorbar(
        image,
        ax=ax,
        fraction=0.03,
        pad=0.02,
        ticks=[0, 0.5, 1],
        label="Fraction of cycle ON",
    )
    ax.set_yticks(range(network.n), network.names, fontsize=6.8)
    ax.set_xticks(
        range(len(profile)),
        ["W%d" % (i + 1) for i in range(len(keys_left))]
        + ["C%d" % (i + 1) for i in range(len(keys_right))],
        fontsize=7,
        rotation=45,
    )
    ax.axvline(len(keys_left) - 0.5, color="white", lw=4)
    ax.axhline(data["target"] - 0.5, color=CORAL, lw=1)
    ax.axhline(data["target"] + 0.5, color=CORAL, lw=1)
    ax.set_title(
        "ON occupancy across each complete attractor cycle",
        fontsize=11,
        fontweight="bold",
        loc="left",
        pad=12,
    )
    fig.text(
        0.04,
        0.08,
        "Target ON occupancy: %.1f%% → %.1f%%  |  phase-aligned cycle disturbance: %.1f%%"
        % (
            summary["target_occupancy_wild_type"] * 100,
            summary["target_occupancy_controlled"] * 100,
            summary["mean_cycle_aligned_hamming"] * 100,
        ),
        fontsize=12,
        color=TEAL,
        fontweight="bold",
    )
    fig.text(
        0.04,
        0.035,
        "A seeded sample of the 40-node state space. Search uses the original repeated-state reward; the cycle analysis here is an independent final evaluation.",
        fontsize=9,
        color=MUTED,
    )
    fig.savefig(out / "control_attractors.png", dpi=150)
    fig.savefig(out / "control_attractors.svg", metadata={"Date": None})
    plt.close(fig)


def control_search(data, out):
    control = data["control"]
    gpb = np.asarray(control["gpb"]["Rewards"]).ravel()
    fig, axes = plt.subplots(1, 2, figsize=(14, 5.8))
    title(
        fig,
        "Searching a combinatorial intervention space",
        "GPB and UCT-RAVE use their native reward evaluations · individual seeded runs, with different rollout budgets",
    )
    for ax, key, color in [(axes[0], "gpb", TEAL), (axes[1], "uct", BLUE)]:
        if key not in control:
            ax.axis("off")
            continue
        rewards = np.asarray(control[key]["Rewards"]).ravel()
        x = np.arange(1, len(rewards) + 1)
        ax.plot(x, rewards, color=color, alpha=0.3, lw=1)
        ax.plot(x, np.maximum.accumulate(rewards), color=color, lw=2)
        ax.set_ylim(0, 1)
        ax.set_xlabel("Search iteration")
        ax.set_ylabel("Sampled reward")
        ax.set_title(
            key.upper() + " · endpoint preservation × target achievement",
            fontsize=10,
            loc="left",
        )
        ax.grid(axis="y", color="#edf0f4")
    fig.subplots_adjust(left=0.07, right=0.97, top=0.75, bottom=0.18, wspace=0.25)
    fig.text(
        0.05,
        0.055,
        "Faint: iteration reward. Solid: running maximum of observed reward. These curves are not a matched-budget algorithm benchmark.",
        fontsize=9,
        color=MUTED,
    )
    fig.savefig(out / "control_search.png", dpi=150)
    plt.close(fig)


def render(data, root):
    style()
    out = Path(root) / "docs/figures"
    out.mkdir(parents=True, exist_ok=True)
    for function in [
        fault_propagation,
        attractor_landscape,
        essentiality_ranks,
        control_dynamics,
        control_attractors,
        control_search,
    ]:
        print("Rendering " + function.__name__, flush=True)
        function(data, out)
    for path in out.glob("*.svg"):
        path.write_text(
            "\n".join(line.rstrip() for line in path.read_text(encoding="utf-8").splitlines()) + "\n",
            encoding="utf-8",
        )
