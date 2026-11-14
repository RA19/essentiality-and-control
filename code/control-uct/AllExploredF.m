function Exploit = AllExploredF(CurrentState,NodeCount,depth,TreeNodes,TreeMoves,MoveToParent,ControlNode)
%ALLEXPLOREDF Count legal branches from the actual ancestor sequence.
previous = []; state = CurrentState;
while state > 1
    previous = [TreeMoves(state) previous]; state = TreeNodes(state);
end
n = NodeCount/2; moves = setdiff(1:NodeCount,[ControlNode ControlNode+n]);
candidates = control_candidates(moves,previous,n,2-length(previous),true);
Exploit = all(ismember(candidates,TreeMoves(TreeNodes==CurrentState)));
end
