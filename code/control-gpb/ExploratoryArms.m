function [ExpArms] = ExploratoryArms(ExpArms,ind);

FlagVec = ones(size(ExpArms,1),1);
FlagVec(ind) = 0;

ExpArms = ExpArms(logical(FlagVec),:);