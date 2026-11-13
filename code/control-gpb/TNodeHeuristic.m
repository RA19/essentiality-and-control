function [RankedList Set1 Set2 Set3] = TNodeHeuristic(NetData,ControlNode,NodeCount,RealNodeCount);

% Finding Nodes which are Direct/Primary Inputs to ControlNode
Set1 = NetData.varF(1:NetData.nv(ControlNode),ControlNode)';

% Nodes Which are Secondary Inputs to Controlnode
Set2=[];
for n=1:length(Set1);
    Set2=[Set2 NetData.varF(1:NetData.nv(Set1(n)),Set1(n))'];
end
Set2 = setdiff(Set2,Set1);

% Nodes Which are Tertiary Inputs to Controlnode
Set3=[];
for n=1:length(Set2);
    Set3=[Set3 NetData.varF(1:NetData.nv(Set2(n)),Set2(n))'];
end
Set3 = setdiff(Set3,Set2);
Set3 = setdiff(Set3,Set1);

% Adding SA1 Nodes
Set1 = [Set1 Set1+RealNodeCount];
Set2 = [Set2 Set2+RealNodeCount];
Set3 = [Set3 Set3+RealNodeCount];

% Ranking Nodes - Highest Value = 4;
RankedList = ones(1,NodeCount);
RankedList(Set1) = 4;
RankedList(Set2) = 3;
RankedList(Set3) = 2;
