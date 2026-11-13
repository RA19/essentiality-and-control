% Hierarchical Clustering of Gene Mutations for the T-Cell Receptor Network

% Initializations
clear 
load TCellNetworkData
Nodes=80;
cnt=0;
l2norm(Nodes*Nodes).pair1=[];
l2norm(Nodes*Nodes).pair2=[];
Realvals=zeros(1,Nodes*Nodes);

% Calculating L2 Norm distance between pairs of gene mutations
for i=1:Nodes
    for j=1:Nodes
        cnt=cnt+1;
        l2norm(cnt).pair1 = i;
        l2norm(cnt).pair2 = j;
        if i~=j
            % L2 Norm
            Realvals(cnt) = sqrt(sum((KNew(i,1:Nodes)-KNew(j,1:Nodes)).^2));
        else
            Realvals(cnt)=1e9;
        end
     end
end

% Sorting PairWise Distances
[Svalue Sindex] = sort(Realvals,'ascend');

% If Svalues are the same, then we choose pair randomly
SumSet = sum(Svalue(1)==Svalue);
PairPerms = randperm(SumSet);
index = Sindex(PairPerms(1));
Ksub = KNew(1:Nodes,1:Nodes);

% Bulding Hierachical Clustering Tree
% Initializations
NodesUsed = zeros(1,Nodes);
EliminationVec=ones(1,Nodes);
EliVec=ones(1,Nodes);
ElimNodes = zeros(1,Nodes);
Terminate=0;
NodeDepths=ones(1,Nodes);
for n=1:Nodes
    TreeNodes(n).Eliminations.Nodes=[];
    TreeNodes(n).Eliminations.atDepth=[];
    TreeNodes(n).Eliminations.DepthReached=[];
    TreeNodes(n).EliminatedBy.Nodes =[];
    TreeNodes(n).EliminatedBy.atDepth =[];
end
counter=0;
while Terminate~=1;
    counter=counter+1;
    % Extracting Pair with least l2norm distance
    Pair1 = l2norm(index).pair1;
    Pair2 = l2norm(index).pair2;
    
    % Chossing WINNER Node randomly since depths are the same
    if (NodeDepths(Pair1) == NodeDepths(Pair2))
        if rand < 0.5
            NodeChosen = Pair1;
            NodeEliminated = Pair2;
        else
            NodeChosen = Pair2;
            NodeEliminated = Pair1;
        end
    elseif NodeDepths(Pair1) > NodeDepths(Pair2) % Choosing higher depth node
        NodeChosen = Pair1;
        NodeEliminated = Pair2;
    elseif NodeDepths(Pair1) < NodeDepths(Pair2) % Choosing higher depth node
        NodeChosen = Pair2;
        NodeEliminated = Pair1;
    end

    % Assigning New Depth to Winner
    if NodeDepths(NodeChosen) >= NodeDepths(NodeEliminated)
         NodeDepths(NodeChosen) = NodeDepths(NodeChosen)+ 1 ;
    else
         NodeDepths(NodeChosen) = NodeDepths(NodeEliminated)+ 1 ;
    end  
    
    % Elimination Matrix Holds :
    % rows: At which depth node eliminated
    % cols: Node eliminated
    % Value: Who eliminated the node
    EliminationVec(NodeEliminated) = NodeDepths(NodeChosen);
    EliVec(NodeEliminated) = NodeDepths(NodeEliminated);
    
    % Tree Data
    TreeNodes(NodeChosen).Eliminations.Nodes = [TreeNodes(NodeChosen).Eliminations.Nodes NodeEliminated];
    TreeNodes(NodeChosen).Eliminations.atDepth = [TreeNodes(NodeChosen).Eliminations.atDepth NodeDepths(NodeEliminated)];
    TreeNodes(NodeChosen).Eliminations.DepthReached = [TreeNodes(NodeChosen).Eliminations.DepthReached NodeDepths(NodeChosen)];
    TreeNodes(NodeEliminated).EliminatedBy.Nodes =NodeChosen;
    TreeNodes(NodeEliminated).EliminatedBy.atDepth =NodeDepths(NodeEliminated);
    
    % Updating Vectors
    NodesUsed(NodeEliminated) = 1;
    NodesUsed(NodeChosen) = 1;
    ElimNodes(NodeEliminated)=1;
    
    % Updating Values so that Node Eliminated is excluded
    Realvals([l2norm.pair1]==NodeEliminated)=1e9;
    Realvals([l2norm.pair2]==NodeEliminated)=1e9;
    
    % Finding Next Minimum
    [Svalue Sindex] = sort(Realvals,'ascend');

    % If Svalues are the same, then we choose pair randomly
    SumSet = sum(Svalue(1)==Svalue);
    PairPerms = randperm(SumSet);
    index = Sindex(PairPerms(1));

    % Termination Criterion: i.e Tree built
    
    if sum(ElimNodes) == (length(ElimNodes)-1)
        Terminate=1;
    end
     out1 = sprintf('%s %d ','Hierachical Clustering iteration :',counter);
     disp(out1);
end

save('TCellTree','NodeDepths','EliminationVec','EliVec','TreeNodes');

% Output Data

% NodeDepths Shows the depth at which the respective node is eliminated

% EliminationVec
% Elimination Matrix Holds :
% rows: At which depth node eliminated
% cols: Node eliminated
% Value: Who eliminated the node

% TreeNodes
%TreeNodes(3).Eliminations
% ans = 
% 
%            Nodes: [4 1 42 2]
%          atDepth: [1 1 1 1]
%     DepthReached: [2 3 4 5]
%     
%     Node 3 has eliminated Nodes [4 1 42 2] at Depth [1 1 1 1] and reached a depth of [2 3 4 5] respectively