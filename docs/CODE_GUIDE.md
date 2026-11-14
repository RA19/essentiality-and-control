# Code guide

[Overview](../README.md) | [Run the examples](USAGE.md) | [Methods](METHODS.md)

## Follow a complete run

```text
examples/build_showcase.py
    run_essentiality.m -> fault statistics -> EPP-DP -> essentiality.mat
    run_control.m     -> GPB / UCT search -> paired cycles -> control.mat
    grnlab/analysis.py -> exact basins + independent cycle evaluation
    grnlab/figures.py  -> animations, attractors, rankings, search curves
```

The native algorithms calculate the essentiality scores and search rewards. Python reads their results and evaluates the same exported truth tables for the dynamics figures.

## Essentiality: from logic to fault paths

Directory: [code/essentiality](../code/essentiality/README.md).

| Component | What it does |
|---|---|
| `readingtext.m` | Read the BNS truth-table definition, set external input values and construct the model and fault-statistics structures |
| `FuncExpand.m` | Expand truth-table rows containing don't-care inputs |
| `ErrorProp.m` | Enumerate input faults and identify output flips, separately for SA0/SA1 and 0-to-1/1-to-0 errors |
| `InputLike.m` | Weight local input configurations using regulator biases |
| `EPPMatrices.m` | Extract the initial directional propagation and bias matrices from fault statistics |
| `EPPDPALGOR.m` | Run max-product DP over the two directional error channels, retaining a predecessor for each score |
| `DPALGONEW.m` | Preserve the former engine call signature by forwarding to `EPPDPALGOR` |
| `FaultInit.m`, `FaultNorm.m` | Build the legacy fault-summary return structure |
| `rank_fault_scores.m` | Rank source influence within each time step, average ties and average over time |
| `EPP_DP.m` | Convenience entry point forwarding to the maintained essentiality example |
| `thelper.txt` | Authoritative bundled network definition used by the example |
| `THelpTruth.mat`, `THelpAttractor.mat` | Historical model/attractor assets; the example derives its model from text and recomputes its displayed basins |

[run_essentiality.m](../examples/run_essentiality.m) specifies the network conditions, eight-step horizon and three-step pulse, and exports both fault directions. To study another network, start with its BNS definition and explicitly specify the external inputs and their values. The parser expects the per-node format used by `thelper.txt`; it is not a general parser for every BNS file variant.

## GPB: share evidence between intervention sets

Directory: [code/control-gpb](../code/control-gpb/README.md).

| Component | What it does |
|---|---|
| `GPClusterSearch.m` | Coordinate action-set initialization, kernel predictions, confidence-based selection, evaluation and cluster expansion |
| `GPReward.m`, `GPUpdates.m`, `geninv.m` | Compute posterior means/variances, update the training system and calculate its generalized inverse |
| `KernelCalc.m`, `NewArmKernelCalc.m`, `SelfKernel.m` | Build intervention-set similarities for existing, newly expanded and self-comparison arms |
| `PairWiseKernel.m` | Prepare the network and gene-fault kernel from the T-cell definition; this preprocessing writes model data |
| `InitialClusters.m`, `CExpand.m`, `ArmExpansion.m` | Select initial representative actions, expand promising clusters and form legal new triplets |
| `HClustering.m` | Construct the archived hierarchical action tree; not needed when using the supplied tree |
| `GPHeur.m`, `TNodeHeuristic.m` | Identify actions related to the target's regulators |
| `ApplySAFaults.m` | Clamp a policy and calculate target achievement times endpoint preservation on paired random starts |
| `bnNextStateGP.m`, `FindAtt.m` | Update the Boolean model; return an attractor representative, complete cycle and trajectory |
| `Mycombntns.m` | Generate fixed-length combinations of available actions |
| `FuncExpand.m` | Expand the BNS truth-table representation during preprocessing |
| `ClusterExpansion.m`, `ExploratoryArms.m` | Older expansion helpers retained for research context; the showcase uses `CExpand` and `ArmExpansion` |
| `pbnRndBiasedGP.m`, `pmfrndGP.m`, `randintexGP.m` | Legacy random-network/distribution helpers; not used by the two showcase models |
| `TCellNetworkData.mat`, `TCellTree.mat`, `Tcell.txt` | Bundled truth tables, pairwise kernel, cluster tree and readable model definition |

The normal example loads the supplied kernel and tree. Rebuilding them is a separate research preprocessing step: `PairWiseKernel([],40,[])`, followed by `HClustering`, from this directory. Keep copies of the supplied MAT files before changing model-preparation settings.

## UCT: build, simulate and update a search tree

Directory: [code/control-uct](../code/control-uct/README.md).

| Component | What it does |
|---|---|
| `UCTAlgoP.m`, `UCTAlgoC.m` | Coordinate permutation-tree and combination-tree search |
| `ApplyMoveP.m`, `ApplyMoveF.m` | Traverse mature branches and expand a leaf |
| `AllExploredP.m`, `AllExploredF.m` | Determine whether all legal branches from a node have been expanded |
| `ApplyExploreP.m`, `ApplyExploreF.m`, `control_candidates.m` | Generate legal unexplored actions; exclude repeated/contradictory clamps and reserve valid combination-tree completions |
| `ApplyExploitF.m` | Select a child using UCB, with optional RAVE blending; reconstructed helper, as explained in the methods |
| `SimulateGameP.m`, `SimulateGameF.m` | Complete candidate policies, evaluate rollouts, return the mean for tree updates and the best observed policy/reward pair |
| `HeuristicExplore.m`, `TNodeHeuristic.m` | Draw from target-related action rank classes during heuristic rollouts |
| `UpdateTreeF.m`, `RAVE.m` | Update empirical tree values and ancestor action estimates |
| `ApplyUCTSAFaults.m` | Evaluate a legal policy using paired native attractor endpoints |
| `bnNextStateGP.m`, `FindAtt.m`, `TCellNetworkData.mat` | Local copies of the shared Boolean dynamics and T-cell model, allowing this code folder to run independently |

`F` in older UCT helper names denotes the combination-tree family, not the truth-table matrix argument used elsewhere. Search state is held in the legacy global UCT/RAVE arrays; run searches sequentially within one Octave/MATLAB process.

## Analysis and figures

| Component | What it does |
|---|---|
| [boolean.py](../grnlab/boolean.py) | Evaluate scalar/batch truth-table updates, detect full cycles, infer edge signs, decode policies, enumerate exact basins and compare cycles |
| [analysis.py](../grnlab/analysis.py) | Join native outputs to dynamics analysis, check endpoint agreement, export named metrics and choose documented illustrative examples |
| [figures.py](../grnlab/figures.py) | Draw actual regulatory graphs, DP trellises, trajectories, basin flows, activity matrices, rankings and search curves |
| [thesis.py](../grnlab/thesis.py), [build_thesis_figures.py](../examples/build_thesis_figures.py) | Redraw two original results from `results/thesis/` tables with explicit provenance; compute the displayed cost reduction and reward gain |
| [build_showcase.py](../examples/build_showcase.py) | Locate Octave, run native examples, analyze results and render all panels |

## Check the behavior

[Python checks](../tests/test_dynamics.py) cover analytical dynamics, clamp timing, policy encodings, truth-table/model consistency and directional DP bookkeeping. [Native checks](../tests/test_native.m) cover the Boolean updater, full cycles, ranking ties, heuristic sampling, both UCT variants and recommendation/reward correspondence. See [usage](USAGE.md#checks) for commands.
