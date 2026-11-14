function [Newstate,MoveApplied,TreeNodes,TreeMoves] = ApplyExploreP(state,PreviousMoves,MoveList,TreeNodes,TreeMoves,RankedList)
%APPLYEXPLOREP Add one previously unexplored legal permutation-tree edge.
candidates = control_candidates(MoveList,PreviousMoves,length(RankedList)/2);
candidates = setdiff(candidates,TreeMoves(TreeNodes==state));
assert(~isempty(candidates),'No unexplored legal control action');
MoveApplied = candidates(randi(length(candidates)));
TreeNodes(end+1) = state; TreeMoves(end+1) = MoveApplied;
Newstate = length(TreeNodes);
end
