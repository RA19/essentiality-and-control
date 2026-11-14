function [EndReward, QuerySequence, BestReward] = SimulateGameP(AppliedMoves,MoveList,NetData,NodeCount,RealNodeCount,Depth,TDepth,ControlNode,ControlValue,UCTRuns,RewardRuns,RankedList,H,ordered)
%SIMULATEGAMEP Complete legal policies and evaluate each sampled rollout.
% Tree updates use the mean. QuerySequence and BestReward describe the same
% best rollout, rather than pairing the last policy with a mean reward.
if nargin < 14; ordered = false; end
if length(AppliedMoves) == TDepth; UCTRuns = 1; end
rewards = zeros(1,UCTRuns); BestReward = -Inf; QuerySequence = [];
for simulation = 1:UCTRuns
    sequence = AppliedMoves;
    for d = length(sequence)+1:TDepth
        candidates = control_candidates(MoveList,sequence,RealNodeCount,TDepth-d,ordered);
        assert(~isempty(candidates),'No legal completion of the control policy');
        if H == 1 && rand < 0.5
            move = HeuristicExplore(candidates,RankedList);
        else
            move = candidates(randi(length(candidates)));
        end
        sequence(end+1) = move;
    end
    rewards(simulation) = ApplyUCTSAFaults(sequence,NetData,RealNodeCount,TDepth,ControlNode,ControlValue,RewardRuns);
    if rewards(simulation) > BestReward
        BestReward = rewards(simulation); QuerySequence = sequence;
    end
end
EndReward = mean(rewards);
end
