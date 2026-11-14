# Research and model provenance

[Overview](../README.md) | [Methods](METHODS.md)

## Essentiality and Control in Gene Regulatory Networks

**Rudi Agius, September 2009, University College London.** Supervised by John Shawe-Taylor and Steven J. Barrett.

We investigate two connected problems: using dynamic error propagation to rank the importance of components in gene regulatory networks, and finding interventions that control a target while limiting disruption to wild-type behavior. The research brings together circuit fault diagnosis, dynamic programming, Gaussian Process Bandits and UCT-based search.

[Read the full report](research/essentiality-and-control-in-gene-regulatory-networks.pdf) | [Read the summary](research/essentiality-and-control-summary.pdf)

The report develops the theory and experimental design, studies essentiality across four biological networks, and evaluates control strategies in the T-cell receptor network. It includes comparisons with static centralities and perturbation-induced attractor loss. The figures in the repository overview are newly computed examples with their own stated settings; historical tables and new seeded runs are not pooled into a single benchmark.

## Dynamic Programming-based Error-Propagation Probability for Gene Essentiality

**Rudi Agius and Steven J. Barrett.** Research poster, with affiliations to UCL / Cancer Research UK London Research Institute and GSK Discovery Analytics.

The poster explains fault-statistics extraction, propagation and decay, rankings and the use of attractor changes to assess perturbation impact. Its T-cell receptor examples illustrate why regulatory logic provides information beyond network topology.

[View the research poster](research/dynamic-programming-error-propagation-gene-essentiality.pptx)

## Biological models in the runnable examples

| Model | Bundled definition | Example |
|---|---|---|
| T-helper differentiation, 23 nodes | [thelper.txt](../code/essentiality/thelper.txt) | SA0/SA1 EPP-DP; exact basin enumeration with four external inputs OFF |
| T-cell receptor signaling, 40 nodes | [Tcell.txt](../code/control-gpb/Tcell.txt), [native model data](../code/control-gpb/TCellNetworkData.mat) | Indirect control of cCbl; GPB and UCT-RAVE; paired complete-cycle evaluation |

These are the Boolean model variants used in the research code, distributed in the BNS network format. They are abstractions of regulation and signaling, not patient data. The original research also studies Arabidopsis flower morphogenesis and Drosophila segment polarity; those networks are not bundled as runnable examples here.

Relevant primary model publications:

- Mendoza and Xenarios (2006), [A method for the generation of standardized qualitative dynamical systems of regulatory networks](https://pmc.ncbi.nlm.nih.gov/articles/PMC1440308/), describes the T-helper regulatory network and its qualitative dynamics.
- Klamt et al. (2006), [A methodology for the structural and functional analysis of signaling and regulatory networks](https://pubmed.ncbi.nlm.nih.gov/16464248/), develops logical analysis with a T-cell receptor signaling model. DOI: 10.1186/1471-2105-7-56.
- Garg et al. (2008), [Synchronous versus asynchronous modeling of gene regulatory networks](https://doi.org/10.1093/bioinformatics/btn336), describes Boolean benchmarks including the 23-node T-helper and 40-node T-cell receptor networks.

The executable definitions in this repository specify the exact model used for each figure; a related publication can contain other formulations or input assumptions.

## Original control results

The [control-search workbook](research/control-search-results.xls) preserves the original experimental tables. The full report explains the historical targets, budgets, baselines and repeated runs. Direct and indirect control solve different intervention constraints; neither the historical results nor the current example supports a blanket claim that one search method wins on every target.

## Attribution and reuse

The work is by Rudi Agius, with the supervision and collaboration acknowledged above. Original attribution comments are retained in the source, including the Boolean state-update routine derived from Ilya Shmulevich and modified by HL. The research report states its copying and acknowledgment conditions in its front matter. No new blanket license is asserted for third-party model material or legacy routines.
