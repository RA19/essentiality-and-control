function Move = HeuristicExplore(NewVec,RankedList)
%HEURISTICEXPLORE Weighted rank-class draw, then uniform action in that class.
ranks = RankedList(NewVec); classes = unique(ranks);
thresholds = cumsum(classes/sum(classes));
index = find(rand <= thresholds,1,'first');
if isempty(index); index = length(classes); end
arms = NewVec(ranks == classes(index));
Move = arms(randi(length(arms)));
end
