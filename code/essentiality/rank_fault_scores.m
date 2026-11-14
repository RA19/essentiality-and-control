function [mean_rank, rank_by_step, order] = rank_fault_scores(influence)
%RANK_FAULT_SCORES Rank source influence at each step, then average ranks.
% Larger influence ranks first. Equal scores receive their average rank;
% inactive nodes are therefore tied rather than ordered by their file index.
[n, steps] = size(influence);
rank_by_step = zeros(n,steps);
for t = 1:steps
    [values, indices] = sort(influence(:,t),'descend');
    first = 1;
    while first <= n
        last = first;
        while last < n && values(last+1) == values(first)
            last = last+1;
        end
        rank_by_step(indices(first:last),t) = (first+last)/2;
        first = last+1;
    end
end
mean_rank = mean(rank_by_step,2);
[~,order] = sort(mean_rank);
end
