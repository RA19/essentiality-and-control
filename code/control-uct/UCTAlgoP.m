function [UCTRun] = UCTAlgoP(Iters,UCTRuns,RewardRuns,C,ControlNode,ControlValue,H,k)
% UCT Algorithm for Control in the T-Cell Receptor Network
% Permuation Tree

% OUTPUTS:
% UCTRun

% INPUTS:
% Number of UCT Iterations: Iters
% Number of UCT Simulations in Simulation Stage: UCTRuns
% Number of Runs for Estimating Final Reward: RewardRuns
% Exploitation Parameter: C
% Target Node to be Controlled: ControlNode
% Target State of Node to be Controlled: ControlValue
% UCT-RAVE and Domain Dependant Simulation: H=1 'ON', H=0 'OFF'
% UCT-RAVE parameter: k

load TCellNetworkData

global RStateActionCounts
global RUCT
global NStateActionCounts
global NUCT

% Network Specific Initializations
NodeCount=80;
RealNodeCount=40;
TDepth = 3;
MoveList=[1:NodeCount];
% TargetNode Heuristics
% Finding Nodes which are Direct Input to Target Node
[RankedList] = TNodeHeuristic(NetData,ControlNode,NodeCount,RealNodeCount);

% Removing Controlled Node
if ControlNode <=RealNodeCount
    MoveList = setdiff(MoveList,[ControlNode ControlNode+RealNodeCount]);
else
    MoveList = setdiff(MoveList,[ControlNode ControlNode-RealNodeCount]);
end

% UCT value and state count initializations
NStateActionCounts = zeros(Iters,NodeCount-2);
NUCT = zeros(Iters,NodeCount-2);
RStateActionCounts = zeros(Iters,NodeCount-2);
RUCT = zeros(Iters,NodeCount-2);

% Tree initializations
TreeNodes=0;
TreeMoves=0;
best=0;
ListOfMoves = zeros(Iters,TDepth);


% UCT ALGORITHM
for n=1:Iters
    
    state=1;
    % Applying Move
    [state AppliedMoves NodesTraversed depth  TreeNodes TreeMoves] = ApplyMoveP(state,MoveList,NodeCount,TreeNodes,TreeMoves,TDepth,ControlNode,RankedList,H,C,k);
    
    % We are at leafe node, hence we must simulate the rest of
    % the 'game' randomly from the given position
    [EndReward QuerySequence BestRolloutReward] = SimulateGameP(AppliedMoves,MoveList,NetData,NodeCount,RealNodeCount,depth,TDepth,ControlNode,ControlValue,UCTRuns,RewardRuns,RankedList,H);
    rewardplot(n) = EndReward;
    rollout_best(n) = BestRolloutReward;
    
    % Updating Tree and Node Statistics
    UpdateTreeF(AppliedMoves,[1 NodesTraversed],EndReward,TreeNodes,TreeMoves,n,Iters);
    ListOfMoves(n,1:length(QuerySequence)) = QuerySequence;
    
    % Visualization
    sout = sprintf('%s %d %f','Reward of Arm Chosen at iteration ', n, EndReward);
    disp(sout);
end

% UCT Output
UCTRun.Rewards = rewardplot;
UCTRun.RolloutBestRewards = rollout_best;
UCTRun.SolutionsApplied =ListOfMoves;
UCTRun.Stats.UCTRuns = UCTRuns;
UCTRun.Stats.Iterations = Iters;
UCTRun.Stats.ControlNode = ControlNode;
UCTRun.Stats.ControlValue = ControlValue;
[val ind] = max(rollout_best);
UCTRun.BestSolution.Reward = val;
UCTRun.BestSolution.GeneMutations = ListOfMoves(ind,:);


