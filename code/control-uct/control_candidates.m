function candidates = control_candidates(moves, previous, n, remaining, ordered)
%CONTROL_CANDIDATES One clamp per gene; reserve legal ordered completions.
% Actions 1:n force OFF; n+1:2*n force ON.
if nargin < 4; remaining = 0; end
if nargin < 5; ordered = false; end
used = mod(previous-1,n)+1;
candidates = moves(~ismember(mod(moves-1,n)+1,used));
if ordered && ~isempty(previous)
    candidates = candidates(candidates > previous(end));
end
if ordered && remaining > 0
    keep = false(size(candidates));
    for i = 1:length(candidates)
        later = candidates(candidates > candidates(i));
        later = later(mod(later-1,n)+1 ~= mod(candidates(i)-1,n)+1);
        keep(i) = length(unique(mod(later-1,n)+1)) >= remaining;
    end
    candidates = candidates(keep);
end
end
