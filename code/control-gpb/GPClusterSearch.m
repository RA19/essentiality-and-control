function [GPRun] = GPClusterSearch(iters,runs,ControlNode,ControlValue);

% OUTPUTS:
% GPRun

% INPUTS:
% Number of GP Iterations: iters
% Number of Runs for Estimating Final Reward: runs
% Target Node to be Controlled: ControlNode
% Target State of Node to be Controlled: ControlValue

load TCellNetworkData
load TCellTree
CREB_FLAG =0; % FOR CREB NETWORK or 0 Otherwise
Knorm = KNew;
clear KNew;


%%% NETWORK PARAMETERS %%%
RealNodeCount=size(Knorm,1)/2; % Real Number of Genes
FNodeCount=RealNodeCount*2; % Full Node Count 
TDepth=3; % Number of SA Genes
m=1; 
XTRA.Node=[];
XTRA.Value=[];

if CREB_FLAG==1 
    % REMOVED
else
    % Removing Target Node
    if ControlNode <=RealNodeCount
        Nodes = setdiff([1:FNodeCount],[ControlNode ControlNode+RealNodeCount]);
    else
        Nodes = setdiff([1:FNodeCount],[ControlNode ControlNode-RealNodeCount]);
    end
end


%%% CLUSTERING PARAMETERS %%%
InitClusterSize = 0.2; % Percentage of Initial Clusters (Effective Nodes)
ExpansionTime = 25; % Iteration No. at which Expansion of Clusters occurs
ExpansionNumber = 0.5; % Percentage of Clusters Expanded
ExpansionLevel =1; % Level of Expansion

% Extracting Initial Set of Nodes
Level=0;
CLpercent=1;
ConstNodes=Nodes;
while CLpercent > InitClusterSize
    Level=Level+1;
    [Nodes CLpercent] = InitialClusters(ConstNodes,EliVec,NodeDepths,Level); % Initial Nodes

end
% Heuristics
[PrimaryNodes] = GPHeur(NetData,ControlNode,FNodeCount,RealNodeCount,2);
CurrentNodes = [Nodes PrimaryNodes];

% Removing Target Node
if ControlNode <=RealNodeCount
    CurrentNodes = setdiff(CurrentNodes,[ControlNode ControlNode+RealNodeCount]);
else
    CurrentNodes = setdiff(CurrentNodes,[ControlNode ControlNode-RealNodeCount]);
end

% Generating Initial Move
% Select the initial move only after contradictory clamps are removed.
% Extracting All Possible Arm combinations
ExpArms = Mycombntns(Nodes,TDepth);
% Checking for illegal Combinations
ind = ones(1,size(ExpArms,1));
for n=1:size(ExpArms,1)
    x=ExpArms(n,:);
    illegal=0;
    vecs = abs([x(1)-x(2);x(1)-x(3);x(2)-x(3)]);
    CheckVec = RealNodeCount*ones(1,TDepth);
    if sum(vecs == CheckVec') > 0
        ind(n) =0;
    end
end
% Removing Illegal Arms
ExpArms = ExpArms(logical(ind),:);
BestMoveSeq = ExpArms(randi(size(ExpArms,1)),:);

%%% GAUSSIAN PROCESS PARAMETERS %%% 
c = 1; % Max Approximation Kernel Parameter
Ct = 1; % Initial Kernel Matrix
kttrain = Ct;
[EndReward] = ApplySAFaults(BestMoveSeq,NetData,RealNodeCount,TDepth,ControlNode,ControlValue,runs,CREB_FLAG,XTRA);
yt = EndReward; % Getting Initial End Reward

% Finding Self kernel of Exploratory arms
[KxxExp] = SelfKernel(ExpArms,Knorm,c,TDepth);
% Finding Index of First Applied Arm
FlagMat = ExpArms - repmat(BestMoveSeq,size(ExpArms,1),1);
% Finding Index of arm applied
ind = find(sum(FlagMat')==0);

% Initialize the incumbent even when no later evaluation improves it.
BestSeqSoFar = BestMoveSeq;
InitialSolution = BestMoveSeq;
InitialReward = EndReward;
EvaluatedMoves = zeros(iters,TDepth);

%%%%%%% GP ALGORITHM %%%%%%%%%%%%%%
TrainMoves=[];
ktexplores=[];
KxxTrain=[];
rewards=zeros(1,iters);
avgut=zeros(1,iters);
avgsigt=zeros(1,iters);
ytrewards=zeros(1,iters);
B_Ft_Iter = zeros(1,iters);
B_ut_Iter = zeros(1,iters);
B_sigt_Iter = zeros(1,iters);
NodeRewards = zeros(1,FNodeCount);
NodeChosenCount = zeros(1,FNodeCount);
AvgNodeRewards =zeros(1,FNodeCount);

for count=1:iters;

    TrainMoves= [TrainMoves;BestMoveSeq];
    
%%% GP Exploition vs Exploration Constants %%%
    A=1;
    B=sqrt(log(count+1)); 

%%%%%% Applying  Kernel To Exploratory Arms %%%%%%%%%
    if isempty(ExpArms)~=1
        % Summation Kernel
        [ktexplores KxxTrain  stop] = KernelCalc(ExpArms,TrainMoves,Knorm,TDepth,c,Ct,KxxTrain,ktexplores,KxxExp);
        if stop==1
            HOLD=1; % Check for erroneous ktexplores values
        end
    else
        stop=1;% All Parents Fully Explored
    end

%%%% Extracting GP Rewards %%%%%%%%%%%%%%%%%%%%%%%%%%
    kttrain = Ct;
    [Ft utExp sigtExp] = GPReward(ktexplores,Ct,yt,A,B);
    avgsigt(count)= sum(sigtExp)/length(sigtExp);
    avgut(count) = sum(utExp)/length(utExp);

    % Finding Arm which maximizes GP Posterior
    [val ind] = max(Ft);
    BestMoveSeq = ExpArms(ind,:);
    clear Ft utExp sigtExp

%%%% Extracting True End Reward %%%%%%%%%%%%%%%%%%%%%%%%%%
    [EndReward] = ApplySAFaults(BestMoveSeq,NetData,RealNodeCount,TDepth,ControlNode,ControlValue,runs,CREB_FLAG,XTRA);
    rewards(count)=EndReward;
    EvaluatedMoves(count,:) = BestMoveSeq;
    ytrewards(count) = max(yt);

    % Ouput Purposes
    % Visualization
    sout = sprintf('%s %d %f','Reward of Arm Chosen at iteration ', count, EndReward);
    disp(sout);
    
    if EndReward > max(yt)
       EndReward;
       BestSeqSoFar = ExpArms(ind,:);
    end

    %%% GP Parameters/Matrices Updates %%%
    [Ct,yt] = GPUpdates(ktexplores(ind,:),Ct,yt,EndReward,count);

%%%%%%%%%%%% CLUSTERING EXPANSION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

NodeRewards(BestMoveSeq) = NodeRewards(BestMoveSeq) + EndReward.*ones(1,TDepth);  
NodeChosenCount(BestMoveSeq) = NodeChosenCount(BestMoveSeq) +1;

if mod(count,ExpansionTime)==0; % Expand Clusters
    % Finding New Set of Nodes
    [NewNodes] =  CExpand(NodeChosenCount,NodeRewards,ExpansionNumber,CurrentNodes,TreeNodes,EliminationVec,ControlNode,RealNodeCount);
    
    % Introductin New Arms
    % Generating New set of Possible Arms
    [NewArms] = ArmExpansion(NewNodes,RealNodeCount,ControlNode,CurrentNodes,TDepth);
    ExpArms = [ExpArms;NewArms];
    CurrentNodes = [CurrentNodes NewNodes];
    
    % Finding Self kernel of Exploratory arms
    [NKxxExp] = SelfKernel(NewArms,Knorm,c,TDepth);
    % Updating KxxExp
    KxxExp = [KxxExp;NKxxExp];
    % Finding Kernel of New Exploratory Arms with Current Training Data
    [Nktexplores stop] = NewArmKernelCalc(NewArms,TrainMoves,Knorm,TDepth,c,KxxTrain,NKxxExp);
    % Updating kexplores
    ktexplores = [ktexplores;Nktexplores];
    clear Nktexplores
    clear NewArms
    length(CurrentNodes)
end
%%%%%%%%%%%% CLUSTERING EXPANSION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
end
GPRun.Iterations = iters;
GPRun.RewardRuns = runs;
GPRun.TargetNode = ControlNode;
GPRun.TargetValue = ControlValue;
GPRun.Rewards = rewards;
GPRun.BestSolution = BestSeqSoFar;
GPRun.MoveList = TrainMoves;
GPRun.EvaluatedMoves = EvaluatedMoves;
GPRun.InitialSolution = InitialSolution;
GPRun.InitialReward = InitialReward;
