function Exploit = AllExploredP(state,NodeCount,depth,TreeNodes)
%ALLEXPLOREDP Each prior clamp removes both actions on that physical gene.
Exploit = sum(TreeNodes==state) >= NodeCount-2-2*depth;
end
