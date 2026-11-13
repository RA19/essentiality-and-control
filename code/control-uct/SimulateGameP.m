function [EndReward QuerySequence] = SimulateGameP(AppliedMoves,MoveList,NetData,NodeCount,RealNodeCount,Depth,TDepth,ControlNode,ControlValue,UCTRuns,RewardRuns,RankedList,H);
% UCT simulation Stage

% Initializations
ILLEGALCOUNT=0;
ILLEGAL=0;
if Depth==TDepth
   UCTRuns=1;
   RewardRuns=25;
end
if H==1
    Hval=0.5; % Domain Depednant Simulation ON
else
    Hval=0; % Domain Dependant Simulation OFF
end

for SimCnt=1:UCTRuns
cnt=0;
MoveSequence = AppliedMoves;
for n=Depth+1:TDepth
    NewVec = setdiff(MoveList,MoveSequence);
    if isempty(NewVec)~=1
        if rand > Hval
        % Uniform Random Move Selection
         RandMoveIndex = randperm(length(NewVec));
         MoveSequence(n) = NewVec(RandMoveIndex(1));
        else
        % Heuristic Move Selection
        [Move] = HeuristicExplore(NewVec,RankedList);
        MoveSequence(n) = Move;
        end
        ILLEGAL=0;
    else
        ILLEGAL=1;
        ILLEGALCOUNT=ILLEGALCOUNT+1;
        break;
    end
end

QuerySequence = MoveSequence;
clear MoveSequence

if ILLEGAL~=1
    % Calculating Final Reward
    [ER] = ApplyUCTSAFaults(QuerySequence,NetData,RealNodeCount,TDepth,ControlNode,ControlValue,RewardRuns);
    SimReward(SimCnt) = ER;
else
    SimReward(SimCnt) =0;
end

end


% Averaging Out Rewards
if ILLEGALCOUNT==UCTRuns
    EndReward=0;
else
    EndReward = sum(SimReward)/(SimCnt-ILLEGALCOUNT);
end
