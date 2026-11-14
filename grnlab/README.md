# Dynamics, analysis and scientific figures

These Python modules analyze the truth tables and outputs produced by the native MATLAB/Octave research algorithms.

| File | Responsibility |
|---|---|
| [boolean.py](boolean.py) | Synchronous scalar/batch transitions, permanent clamps, full attractor cycles, phase-independent cycle identities, exact basin enumeration and phase-aligned cycle distance |
| [analysis.py](analysis.py) | Load native results, enumerate the small model, evaluate the selected control policy, check native/Python agreement and export named metrics |
| [thesis.py](thesis.py) | Redraw the two historical research results from sourced CSV tables, including derived ranking-cost reduction and reward gain |
| [figures.py](figures.py) | Draw functional network edges, animate DP scores and Boolean trajectories, and plot rankings, basins, cycles and native search curves |

Run [build_showcase.py](../examples/build_showcase.py) to generate the complete set. Use `--figures-only` to read the bundled native results. Exact basin enumeration is limited to 20 free Boolean variables to avoid unintentionally allocating a huge state space.

[Methods and metric definitions](../docs/METHODS.md) | [Output formats](../docs/USAGE.md#outputs)
