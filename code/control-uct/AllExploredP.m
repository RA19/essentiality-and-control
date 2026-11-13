function [Exploit] = AllExploredP(state,NodeCount,depth,TreeNodes);
% Finding moves applied from current node - or rather, finding if node in
% tree has branced out maturely


% Finding branches of given node from current tree
SumOfBranches = sum(state==TreeNodes);
if (NodeCount-depth -2) == SumOfBranches % then all moves from current node explored at least once
    % Exploit
    Exploit=1;
else
    % Explore
    Exploit=0;
end
