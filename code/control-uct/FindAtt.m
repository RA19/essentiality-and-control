function [yAtt] = FindAtt(x,F,varF,nv,n)
% Finding Attractor
States = 5*ones(1,n);
AttFound=0;
while AttFound~=1
    % Generating Next State
    y = bnNextStateGP(x,F,varF,nv);
    % Finding whether attractor reached
    Matches = sum((States==repmat(y,size(States,1),1))');
    if sum(Matches==n) > 0
        AttFound=1;
        yAtt = y;
    else
        x=y;
        States = [States;y];
    end
end

