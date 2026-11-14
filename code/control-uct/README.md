# Control with UCT and UCT-RAVE

We build a tree of intervention choices, complete policies through simulation and use the resulting rewards to guide further search. Both tree variants require three distinct non-target genes.

From this directory:

```matlab
addpath(pwd)
rng(31,'twister')
search = UCTAlgoP(180,4,8,0.15,11,1,1,1000);
```

The arguments are iterations, rollouts per iteration, paired starts per rollout, exploration constant, target index, desired target value, heuristic/RAVE flag and RAVE parameter. `UCTAlgoP` uses ordered permutations; `UCTAlgoC` uses increasing action combinations. Actions 1..40 mean OFF and 41..80 mean ON. Both directions on a previously selected gene are excluded.

`Rewards` contains mean rollout rewards used in tree updates. `SolutionsApplied` and `RolloutBestRewards` record matching best rollout policies/rewards for each iteration. `BestSolution` selects from those pairs. The original missing selection helper is implemented in [ApplyExploitF.m](ApplyExploitF.m); its reconstructed status and formula are documented in the methods.

[Every component explained](../../docs/CODE_GUIDE.md#uct-build-simulate-and-update-a-search-tree) | [Objective and sampling](../../docs/METHODS.md#control-and-attractor-preservation) | [Run instructions](../../docs/USAGE.md)
