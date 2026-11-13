function  [Newstate AppliedMoves NodesTraversed depth TreeNodes TreeMoves]  = ApplyMoveP(state,MoveList,NodeCount,TreeNodes,TreeMoves,TDepth,ControlNode,RankedList,H,C,k);
% Applying Move Function

% Two options include:
% Exploting or Exploring

% If not all possible moves have been explored at least once then Explore
% one of the moves which are left randomly.
[Exploit] = AllExploredP(state,NodeCount,0,TreeNodes);

depth=1;
PreviousMoves=[];
n=1;
while (Exploit ==1) && (depth < TDepth+1)
    % Apply UCT to choose next move
    [state MoveApplied] = ApplyExploitF(state,TreeNodes,TreeMoves,H,C,k);
    AppliedMoves(n) = MoveApplied;
    NodesTraversed(n) = state;
    if depth~=3
       [Exploit] = AllExploredP(state,NodeCount,depth,TreeNodes);
    end
    PreviousMoves = AppliedMoves;
    depth=depth+1;
    n=n+1;
    
end
if depth ~= TDepth+1; %Then we have NOT reached terminal leaf hence we still must explore next move
% Leaf in Current Stored tree has been reached hence we must explore the
% next move
[Newstate MoveApplied TreeNodes TreeMoves] = ApplyExploreP(state,PreviousMoves,MoveList,TreeNodes,TreeMoves,RankedList);
AppliedMoves(n) = MoveApplied;
NodesTraversed(n) = Newstate;
else
    Newstate=state;
end