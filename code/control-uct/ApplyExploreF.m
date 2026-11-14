function [Newstate,MoveApplied,TreeNodes,TreeMoves] = ApplyExploreF(state,PreviousMoves,MoveList,TreeNodes,TreeMoves,NodeCount,depth,RankedList)
%APPLYEXPLOREF Expand a legal increasing triplet, reserving its completion.
candidates = control_candidates(MoveList,PreviousMoves,NodeCount/2,2-length(PreviousMoves),true);
candidates = setdiff(candidates,TreeMoves(TreeNodes==state));
assert(~isempty(candidates),'No unexplored legal combination-tree action');
MoveApplied = candidates(randi(length(candidates)));
TreeNodes(end+1) = state; TreeMoves(end+1) = MoveApplied;
Newstate = length(TreeNodes);
end
