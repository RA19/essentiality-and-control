function [Move] = HeuristicExplore(NewVec,RankedList);
% Choosing Next Move with a bias to primary inputs
Ranks=RankedList(NewVec);
RVec = unique(Ranks);
RVector = cumsum(RVec./sum(RVec));
randVal = rand;
for n=1:length(RVec)
    if randVal < RVector(n);
        RankSet=RVec(n);
    end
end
% We Can Now Select an Arm uniform Randomly from Chosen Set
if isempty(RankSet)==1
    hold=1;
end
ArmSet = NewVec(Ranks==RankSet);
if isempty(ArmSet)==1
    hold=1;
end
RandMoveIndex = randperm(length(ArmSet));
Move = ArmSet(RandMoveIndex(1));
