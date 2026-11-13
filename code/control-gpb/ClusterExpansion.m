function [NewNodes] = ClusterExpansion(TreeNodes,ExpandNodes,EliminationVec,CurrentNodes);
% CDV  = Current Depth Vector
% Exanding Best Performing Clusters from Gene Mutation hierarchical
% Clustering Tree
NewNodes=[];
for n=1:length(ExpandNodes);
    
    nd=ExpandNodes(n);
    
    % Finding Children of Curren Node To be Expanded
    PossibleNodes = setdiff([TreeNodes(nd).Eliminations.Nodes],CurrentNodes);
    PossibleNodes = intersect(PossibleNodes,[TreeNodes(nd).Eliminations.Nodes]);
    if isempty(PossibleNodes)~=1
        % Finding Next Child Down Tree
        [Pval Pind]=max(EliminationVec(PossibleNodes));
        NewNodes = [NewNodes PossibleNodes(Pind)];
    else
        % Do Nothing
                
    end
end

