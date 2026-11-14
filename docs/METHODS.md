# Methods

[Overview](../README.md) | [Run the examples](USAGE.md) | [Code guide](CODE_GUIDE.md)

## Boolean network dynamics

Each node represents a gene, protein or signaling component with a binary state: OFF (0) or ON (1). A node's truth table specifies its next state from its regulators' current states. Updates are **synchronous and deterministic**. The probability calculations used by EPP-DP and the random starts used by control search do not make these state transitions stochastic.

An attractor is a fixed point or a repeating sequence of states. Its basin contains the initial states that eventually reach it. A single repeated state is only a representative of a periodic attractor; it does not describe its full cycle.

The native representation is `F` (truth-table outputs, unused entries -1), `varF` (1-based regulator indices) and `nv` (regulator counts). The first listed regulator is the most significant truth-table input bit. Zero-input nodes retain their state unless fixed by the model setup. Permanent interventions clamp the selected genes before the first update and thereafter.

## Essentiality through error propagation

### Fault diagnosis as a biological analogy

In a circuit, a stuck-at fault forces a wire or gate output to 0 or 1. Whether it changes another gate's output depends on both the gate's logic and its other inputs. We apply this principle to biological Boolean networks: **a perturbation matters when the regulatory logic lets its effect travel**.

SA0 is a forced-OFF, knockout-like perturbation; SA1 is a forced-ON perturbation representing constitutive activity in the model. A binary ON state does not quantify an expression level or a drug dose.

### Local statistics and the DP recurrence

`readingtext` expands the network's truth tables. `ErrorProp` identifies input states for which an SA0 or SA1 input fault changes a node's output, in either direction. Local input-state probabilities are formed from the model's input biases, using the factorization in the research implementation. These are model assumptions, not measured expression distributions.

`EPPDPALGOR` propagates two error channels per node: an output changing from 0 to 1, and an output changing from 1 to 0. For error state j at step t:

```text
V(j,t) = max over incoming error states i of
         V(i,t-1) * L(j | i)
```

`L(j | i)` is the local transmission likelihood. The engine stores the maximizing predecessor for each positive score, so a path can be traced through the DP trellis. Feedback and reconvergent wiring remain in the network, but the max-product recurrence does not resolve every dependence between simultaneous paths.

**Interpretation:** `V` scores the most likely path under the local model. It is not the marginal probability that a node is erroneous after summing over all paths. Summing these scores across nodes gives a fault-influence score; that sum is not a probability bounded by one.

The total influence at each step is used to rank sources separately for SA0 and SA1. We average each source's ranks over the eight steps, assigning average ranks to ties. A lower mean rank denotes greater modeled fault influence. This differs from ranking a single cumulative score across all steps. The source's own score is included.

### Two different perturbation experiments

The supplied outputs contain **persistent source faults for eight-step rankings**, and a separate **three-step source pulse followed through eight DP columns** for the propagation animation. Source duration refers to DP columns; these are algorithmic steps, not elapsed biological time.

For the attractor figure, we independently enumerate actual Boolean transitions with **GATA3 held ON permanently**. Four external inputs (TCR, IFN-beta, IL-18 and IL-12) remain OFF. There are 19 free initial bits, hence 2^19 = 524,288 starts. We resolve the complete functional graph for wild type and the perturbed network, retaining the pairing between the same initial states. The attractor experiment is not an output of the DP approximation.

The animation source is selected reproducibly as the SA1 pulse with the largest sum of non-source DP scores. It is an illustrative high-propagation example, not an independent validation result.

### Engine lineage and encoding

The maintained engine follows the modular `gsk_toolbox` EPP-DP formulation. `DPALGONEW` is a compatibility entry point. The recurrence retains the archived propagation scores; the maintained implementation separates the local-likelihood calculation and follows the stored predecessors during traceback.

The two original APIs use different encodings:

| API | Encoding |
|---|---|
| Essentiality `fault_code` | **1 = SA1**, **2 = SA0** |
| Control action on an n-node model | **1..n = SA0**, **n+1..2n = SA1** |
| Python node indices | Zero-based; control dictionaries map node index to 0 or 1 |

## Control and attractor preservation

### Objective and legal interventions

We search over three distinct genes, excluding direct intervention on the target. For the 40-node model this gives 39 choose 3, times 2^3 = **73,112 legal intervention sets**. A permutation tree can encounter the same set in different orders; a combination tree uses increasing action indices.

The native search objective is:

```text
reward = (1 - mean normalized endpoint Hamming distance)
         * mean(target endpoint equals desired state)
```

Each evaluation uses paired random initial states for the wild-type and controlled models. The endpoint is the first repeated state found by the native attractor routine. The Hamming distance includes all 40 nodes, including target and intervention nodes. A policy is therefore penalized for collateral changes as well as the target change itself.

This reward encourages preservation; it does not guarantee preservation of every attractor, basin or cycle. When a trajectory reaches a periodic attractor, the endpoint comparison can depend on cycle phase. `FindAtt` retains its original representative-state convention as its first return value, and also returns the full cycle and trajectory for further analysis.

### Search strategies

**Gaussian Process Bandits.** `GPClusterSearch` models rewards across intervention sets. A kernel derived from the network shares information between related gene faults; confidence-based selection balances predicted reward and uncertainty. Hierarchical clustering limits the initial action set and expands it during search. The example uses 200 iterations, plus an initial policy evaluation, with 24 paired starts per evaluation.

**UCT / UCT-RAVE.** `UCTAlgoP` uses a permutation tree; `UCTAlgoC` uses a combination tree. Tree expansion and rollouts exclude both fault directions on genes already selected. UCB selection can blend its value estimate with RAVE statistics, and rollouts can favor actions related to the target's inputs. The example uses the permutation tree with 180 iterations, up to four rollouts per iteration and eight paired starts per rollout, C=0.15 and k=1000. A completed tree policy needs only one rollout.

Tree updates use the mean rollout reward. The recommended policy is paired with its own best observed rollout reward. These are separate output fields. `ApplyExploitF` is a reconstructed UCB/RAVE selector because that helper was missing from the archived source. It implements a square-root exploration bonus and a RAVE blend with beta=sqrt(k/(3*n+k)); this executable is not a claim of byte-for-byte recovery of the original experiment.

The search plot shows native iteration rewards and their running maximum. GPB and UCT have different sampling and rollout budgets; the plot is not a controlled performance comparison.

### Independent complete-cycle evaluation

We evaluate the selected GPB policy on **512 fresh paired starts**, with evaluation seed 2026, independently of search seed 27. For each start we retain the entire wild-type and controlled attractor cycle. The 40-node state space is not exhaustively enumerated.

- **Target ON occupancy:** the fraction of each cycle spent with the target ON, averaged equally over sampled initial states.
- **Cycle disturbance:** normalized Hamming distance over the least common multiple of the two cycle lengths, minimized over relative phase and averaged over the paired starts.
- **Basin transitions:** counts of initial states reaching each paired wild-type/controlled cycle. Cycles differing only by rotation have the same identity.
- **Attractor activity matrix:** per-node ON occupancy over each distinct complete cycle; it is not a matrix of single endpoint representatives.

These measures are additional analyses of the selected intervention, not replacements for the native search objective. Python independently evaluates the exported truth tables and checks that each Octave endpoint belongs to the corresponding complete cycle.

## Scope of the evidence

The figures demonstrate the algorithms on bundled Boolean models. The original research also compares essentiality rankings with static centrality measures and perturbation-derived attractor loss, and explores multiple control targets. Those experiments are described in the [research materials](RESEARCH.md). The present examples do not reproduce every historical benchmark or establish experimental gene essentiality.
