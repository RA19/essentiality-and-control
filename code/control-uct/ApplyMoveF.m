function  [Newstate AppliedMoves NodesTraversed depth TreeNodes TreeMoves]  = ApplyMoveF(state,MoveList,NodeCount,TreeNodes,TreeMoves,TDepth,ControlNode,RankedList,H,C,k);
% Applying Move Function

% Two options include:
% Exploting or Exploring

% If not all possible moves have been explored at least once then Explore
% one of the moves which are left randomly.
[Exploit] = AllExploredF(state,NodeCount,0,TreeNodes,TreeMoves,[],ControlNode);


depth=1;
PreviousMoves=[];
n=1;
while (Exploit ==1) && (depth < TDepth+1)
   [state MoveApplied] = ApplyExploitF(state,TreeNodes,TreeMoves,H,C,k);
    AppliedMoves(n) = MoveApplied;
    NodesTraversed(n) = state;
    if depth~=3
        [Exploit] = AllExploredF(state,NodeCount,depth,TreeNodes,TreeMoves,MoveApplied,ControlNode);
       
    end
    PreviousMoves = AppliedMoves;
    depth=depth+1;
    n=n+1;
    
end
if depth ~= TDepth+1; %Then we have NOT reached terminal leaf hence we still must explore next move
% Leaf in Current Stored tree has been reached hence we must explore the
% next move
[Newstate MoveApplied TreeNodes TreeMoves]  = ApplyExploreF(state,PreviousMoves,MoveList,TreeNodes,TreeMoves,NodeCount,depth-1,RankedList);
AppliedMoves(n) = MoveApplied;
NodesTraversed(n) = Newstate;
else
    Newstate=state;
end