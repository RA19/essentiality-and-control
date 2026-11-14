# Run and explore

[Overview](../README.md) | [Methods](METHODS.md) | [Code guide](CODE_GUIDE.md)

## Requirements

Use Python 3.10+ and GNU Octave. The full pipeline has been exercised with Octave 11.3 and Python 3.13. The native functions also use MATLAB-compatible syntax; a current MATLAB run has not been independently checked. The Python figure pipeline accepts MATLAB v7 MAT files from either environment.

```bash
python -m pip install -r requirements.txt
python examples/build_showcase.py
```

Run from the repository root. The launcher finds `octave-cli` on PATH, checks `OCTAVE_EXECUTABLE`, and recognizes the standard per-user Windows Octave installation. To choose an executable explicitly:

```bash
python examples/build_showcase.py --octave "/path/to/octave-cli"
```

The full run performs native EPP-DP, GPB and UCT-RAVE calculations, then complete-cycle analysis and figure generation. GPB is the longest stage; runtime depends on the numerical libraries and search budget.

## Rebuild figures from the supplied outputs

```bash
python examples/build_showcase.py --figures-only
```

This needs Python only. It reads the bundled native results, recomputes exact T-helper basins and sampled control-cycle analyses, and rebuilds the figures. No fabricated interpolation or simulated display data is added to the animations.

## Rebuild only the original research result figures

```bash
python examples/build_thesis_figures.py
```

This redraws the essentiality comparison and control-neutralization result from the sourced tables in `results/thesis/`. The full showcase also rebuilds these figures. [Definitions and original sources](RESULTS.md).

## Change the search budget

```bash
python examples/build_showcase.py --gpb-iterations 100 --uct-iterations 120
```

Use `--uct-iterations 0` to skip UCT. The default is 200 GPB iterations and 180 UCT-RAVE iterations. Different budgets can select different interventions and therefore change the control figures. Fixed seeds make a run repeatable within the same numerical environment; MATLAB and Octave random streams and numerical decisions may differ.

## Native MATLAB / Octave entry points

From the repository root, in the MATLAB or Octave console:

```matlab
addpath(fullfile(pwd,'examples'));
run_essentiality();
run_control();
```

Both functions accept an absolute output directory. `run_control(output_dir, gpb_iterations, uct_iterations)` accepts custom budgets. The examples use their own working directories to find the bundled network data and restore the caller's directory afterward.

For a different target, call the underlying search from its code directory:

```matlab
cd code/control-gpb
addpath(pwd)
rng(27,'twister')
search = GPClusterSearch(200,24,11,1);  % cCbl (node 11) -> ON
```

`GPClusterSearch(iterations, reward_runs, target_node, target_value)` returns the policy, evaluated policies and rewards. For UCT, run from `code/control-uct`:

```matlab
rng(31,'twister')
search = UCTAlgoP(180,4,8,0.15,11,1,1,1000);
% For the increasing-action combination tree, use UCTAlgoC.
```

See the [code guide](CODE_GUIDE.md) for custom model preparation. The showcase itself intentionally uses one fully specified target and two bundled models.

## Outputs

| Path | Contents |
|---|---|
| `results/demo/essentiality.mat` | Model truth tables; names and input conditions; both fault directions; persistent and pulse DP scores/predecessors; time-step influence and mean ranks |
| `results/demo/control.mat` | T-cell truth tables; GPB and UCT search records; selected GPB policy; evaluation starts; native endpoints and full cycles; seeds |
| `results/demo/analysis.json` | Model settings, basin counts, named interventions, target occupancy and cycle-distance metrics |
| `results/demo/essentiality.csv` | Named SA0/SA1 mean ranks and cumulative influence scores |
| `results/demo/landscapes.npz` | Paired exact T-helper basin labels and T-cell cycle-occupancy arrays |
| `docs/figures/` | GIF animations, PNG figures and SVG versions of the basin/attractor diagrams |

The JSON field `example_initial_state` is a zero-based row index into the saved evaluation starts. The animation selects the start with the largest target improvement, breaking ties by cycle disturbance. Its illustrative trajectory is not a population average.

## Checks

```bash
python -m unittest discover -s tests -v
```

In Octave or MATLAB, from the repository root:

```matlab
addpath(fullfile(pwd,'tests'));
test_native();
```

The checks cover analytical fixed points/cycles, truth-table ordering, clamp timing, tied ranks, policy legality, both UCT tree variants and recommendation/reward bookkeeping. The figure pipeline also checks agreement between native attractor endpoints and independently calculated Python cycles.
