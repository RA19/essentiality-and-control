function [EndReward, QuerySequence, BestReward] = SimulateGameF(varargin)
%SIMULATEGAMEF Rollouts in the increasing-action combination tree.
[EndReward, QuerySequence, BestReward] = SimulateGameP(varargin{:},true);
end
