function [yAtt, cycle, trajectory] = FindAtt(x,F,varF,nv,n)
%FINDATT Follow synchronous Boolean updates until a complete cycle repeats.
% yAtt retains the historical first-repeated-state reward convention.
% cycle contains every state in that attractor; trajectory starts at x.
% A step limit turns nontermination into an explicit error.
initial = x;
visited = zeros(0,n);
for step = 1:10000
    y = bnNextStateGP(x,F,varF,nv);
    matching = find(all(visited == repmat(y,size(visited,1),1),2),1);
    if ~isempty(matching)
        yAtt = y;
        cycle = visited(matching:end,:);
        trajectory = [initial;visited;y];
        return;
    end
    visited(end+1,:) = y;
    x = y;
end
error('FindAtt:stepLimit','Attractor not reached within 10000 synchronous updates');
end
