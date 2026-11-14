# Control with Gaussian Process Bandits

We search for three-gene interventions that achieve a target state while rewarding preservation of wild-type attractor representatives. The model, gene-fault kernel and hierarchical action tree are supplied for the 40-node T-cell receptor network.

Start with [run_control.m](../../examples/run_control.m), or call [GPClusterSearch.m](GPClusterSearch.m) from this directory:

```matlab
addpath(pwd)
rng(27,'twister')
search = GPClusterSearch(200,24,11,1);  % cCbl -> ON
```

The arguments are search iterations, paired starts per reward evaluation, target index and desired target value. Actions 1..40 mean OFF and 41..80 mean ON. Three distinct genes are required, and the target is excluded. `BestSolution` records the best sampled policy; `EvaluatedMoves` aligns with `Rewards`. `InitialSolution` and `InitialReward` describe the evaluation preceding the numbered iterations.

The search reward compares repeated-state endpoints. The showcase separately evaluates the chosen policy's complete cycles on fresh starts. The two analyses have distinct interpretations.

[Every component explained](../../docs/CODE_GUIDE.md#gpb-share-evidence-between-intervention-sets) | [Objective and sampling](../../docs/METHODS.md#control-and-attractor-preservation) | [Run instructions](../../docs/USAGE.md)
