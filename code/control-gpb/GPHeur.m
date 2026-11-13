function [PrimaryNodes] = GPHeur(NetData,ControlNode,FNodeCount,RealNodeCount,HeuristicLevel);

if HeuristicLevel==0;
    PrimaryNodes=[];
elseif HeuristicLevel==1;
    [RankedList Set1 Set2 Set3] = TNodeHeuristic(NetData,ControlNode,FNodeCount,RealNodeCount);
    PrimaryNodes=Set1;
elseif HeuristicLevel==2;
    [RankedList Set1 Set2 Set3] = TNodeHeuristic(NetData,ControlNode,FNodeCount,RealNodeCount);
    PrimaryNodes=[Set1 Set2];
elseif HeuristicLevel==2;
    [RankedList Set1 Set2 Set3] = TNodeHeuristic(NetData,ControlNode,FNodeCount,RealNodeCount);
    PrimaryNodes=[Set1 Set2 Set3];
end