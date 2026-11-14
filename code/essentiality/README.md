# EPP-DP essentiality

We rank source perturbations by the influence they can transmit through the network's Boolean logic. SA0 and SA1 are evaluated separately.

```text
BNS definition -> expanded logic -> fault statistics -> max-product DP
               -> scores and predecessors -> per-step ranks -> mean rank
```

Start with [run_essentiality.m](../../examples/run_essentiality.m). The maintained engine is [EPPDPALGOR.m](EPPDPALGOR.m), based on the modular GSK-toolbox formulation. [DPALGONEW.m](DPALGONEW.m) preserves the earlier call signature; [EPP_DP.m](EPP_DP.m) runs the maintained example.

**Encoding:** engine fault code 1 means SA1 (ON), and 2 means SA0 (OFF). Score rows 1..n represent 0-to-1 errors; rows n+1..2n represent 1-to-0 errors. The scores retain the strongest path rather than sum over all paths. Source duration is counted in DP columns.

[Every component explained](../../docs/CODE_GUIDE.md#essentiality-from-logic-to-fault-paths) | [Mathematical interpretation](../../docs/METHODS.md#essentiality-through-error-propagation) | [Run instructions](../../docs/USAGE.md)
