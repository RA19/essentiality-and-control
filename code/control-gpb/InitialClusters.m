function [Nodes CLpercent] = InitialClusters(SNodes,EliminationVec,NodeDepths,L);
% Extracting Representative Nodes from Gene Mutation Hierarchical
% Clustering Tree
[ind1] = find(EliminationVec>=L);
[ind2] = find(NodeDepths>=L);

Tree_Nodes = unique([ind1 ind2]);
Nodes = intersect(SNodes,Tree_Nodes);
CLpercent = length(Nodes)/length(SNodes);