function  [NewNodes] =  CExpand(NodeChosenCount,NodeRewards,ExpansionNumber,CurrentNodes,TreeNodes,EliminationVec,ControlNode,RealNodeCount);
    % Sort Clusters According to Performance
    AvgNodeRewards(NodeChosenCount~=0) = NodeRewards(NodeChosenCount~=0)./ NodeChosenCount(NodeChosenCount~=0);
    [SVal SInd] = sort(AvgNodeRewards,'descend');
    % Chooosing Top Performing Nodes to Expand
    ExpandNodes = SInd(1:round(length(CurrentNodes)*ExpansionNumber));
   
   
    % Expanding Clusters / Generating New Exploratory Nodes
    [NewNodes] = ClusterExpansion(TreeNodes,ExpandNodes,EliminationVec,CurrentNodes);
    % Removing Controlled Node
    if ControlNode <=RealNodeCount
        NewNodes = setdiff(NewNodes,[ControlNode ControlNode+RealNodeCount]);
    else
        NewNodes = setdiff(NewNodes,[ControlNode ControlNode-RealNodeCount]);
    end
    
    if  sum(NewNodes==50)>0  || sum(NewNodes==10)>0 
        HOLD=1;
    end
    