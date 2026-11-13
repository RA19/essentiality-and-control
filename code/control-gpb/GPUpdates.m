function [Ct,yt] = GPUpdates(kt,Ct,yt,EndReward,count);

% Covariance Matrix Updates
ktnew = [kt 1+rand*0.2];
yt = [yt EndReward];
Ctnew=zeros(length(ktnew),length(ktnew));
Ctnew(1:size(Ct,1),1:size(Ct,2))=Ct;
Ctnew(count+1,:) = ktnew;
Ctnew(:,count+1) = ktnew';
Ct=Ctnew;