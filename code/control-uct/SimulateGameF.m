function [EndReward QuerySequence] = SimulateGameF(AppliedMoves,MoveList,NetData,NodeCount,RealNodeCount,Depth,TDepth,ControlNode,ControlValue,UCTRuns,RewardRuns,RankedList,H);


ILLEGALCOUNT=0;
ILLEGAL=0;
if Depth==TDepth
   UCTRuns=1;
   RewardRuns=25;
end
if H==1
    Hval=0.5; % Heuristic Sim
else
    Hval=0; % Non Heuristic Sim
end

for SimCnt=1:UCTRuns

% NewVec=MoveList;
% for n=1:length(AppliedMoves);
%     CheckVec = NewVec - repmat(AppliedMoves(n),1,length(NewVec));
%     NewVec = NewVec(~CheckVec==0);
% end
% % Choosing Random Set of moves to apply
% RandMoveIndex = randperm(length(NewVec));
% MoveSequence = NewVec(RandMoveIndex(1:(TDepth-Depth)));
% QuerySequence = [AppliedMoves MoveSequence];
cnt=0;
MoveSequence = AppliedMoves;
if length(AppliedMoves)==3
    hey=1;
end
for n=Depth+1:TDepth
    NewVec = intersect(MoveList,[MoveSequence(n-1)+1:NodeCount]);
    
   % NewVec = MoveList(MoveSequence(n-1)+1:end);
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
    %[ER] = ApplyUCTSAFaults(QuerySequence);
    [ER] = ApplyUCTSAFaults(QuerySequence,NetData,RealNodeCount,TDepth,ControlNode,ControlValue,RewardRuns);
    SimReward(SimCnt) = ER;
else
    SimReward(SimCnt) =0;
end



end



if ILLEGALCOUNT==UCTRuns
    EndReward=0;
else
    EndReward = sum(SimReward)/(SimCnt-ILLEGALCOUNT);
end
