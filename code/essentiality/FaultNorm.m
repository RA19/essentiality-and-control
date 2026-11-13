function [NormOut]= FaultNorm(FaultStats,StartNode,TimeSteps,SA_Value)

% Normalization

if SA_Value==1
% Removing Repetition of Fault Statistics due to TimeSteps
FaultStats(StartNode).SA1.O0_1.FSB.val = FaultStats(StartNode).SA1.O0_1.FSB.val/(TimeSteps-1);
FaultStats(StartNode).SA1.O0_1.FSB.Pairs = FaultStats(StartNode).SA1.O0_1.FSB.Pairs(1:FaultStats(StartNode).SA1.O0_1.FSB.val,:);

FaultStats(StartNode).SA1.O0_1.SB.val = FaultStats(StartNode).SA1.O0_1.SB.val/(TimeSteps-1);
FaultStats(StartNode).SA1.O0_1.SB.Pairs = FaultStats(StartNode).SA1.O0_1.SB.Pairs(1:FaultStats(StartNode).SA1.O0_1.SB.val,:);
FaultStats(StartNode).SA1.O0_1.SB.BlockEffect = FaultStats(StartNode).SA1.O0_1.SB.BlockEffect(1:FaultStats(StartNode).SA1.O0_1.SB.val);

FaultStats(StartNode).SA1.O0_1.NSB.val = FaultStats(StartNode).SA1.O0_1.NSB.val/(TimeSteps-1);
FaultStats(StartNode).SA1.O0_1.NSB.Pairs = FaultStats(StartNode).SA1.O0_1.NSB.Pairs(1:FaultStats(StartNode).SA1.O0_1.NSB.val,:);



%%%%

FaultStats(StartNode).SA1.O1_0.FSB.val = FaultStats(StartNode).SA1.O1_0.FSB.val/(TimeSteps-1);
FaultStats(StartNode).SA1.O1_0.FSB.Pairs = FaultStats(StartNode).SA1.O1_0.FSB.Pairs(1:FaultStats(StartNode).SA1.O1_0.FSB.val,:);

FaultStats(StartNode).SA1.O1_0.SB.val = FaultStats(StartNode).SA1.O1_0.SB.val/(TimeSteps-1);
FaultStats(StartNode).SA1.O1_0.SB.Pairs = FaultStats(StartNode).SA1.O1_0.SB.Pairs(1:FaultStats(StartNode).SA1.O1_0.SB.val,:);
FaultStats(StartNode).SA1.O1_0.SB.BlockEffect = FaultStats(StartNode).SA1.O1_0.SB.BlockEffect(1:FaultStats(StartNode).SA1.O1_0.SB.val);

FaultStats(StartNode).SA1.O1_0.NSB.val = FaultStats(StartNode).SA1.O1_0.NSB.val/(TimeSteps-1);
FaultStats(StartNode).SA1.O1_0.NSB.Pairs = FaultStats(StartNode).SA1.O1_0.NSB.Pairs(1:FaultStats(StartNode).SA1.O1_0.NSB.val,:);

elseif SA_Value==2
%%%% 
FaultStats(StartNode).SA0.O0_1.FSB.val = FaultStats(StartNode).SA0.O0_1.FSB.val/(TimeSteps-1);
FaultStats(StartNode).SA0.O0_1.FSB.Pairs = FaultStats(StartNode).SA0.O0_1.FSB.Pairs(1:FaultStats(StartNode).SA0.O0_1.FSB.val,:);

FaultStats(StartNode).SA0.O0_1.SB.val = FaultStats(StartNode).SA0.O0_1.SB.val/(TimeSteps-1);
FaultStats(StartNode).SA0.O0_1.SB.Pairs = FaultStats(StartNode).SA0.O0_1.SB.Pairs(1:FaultStats(StartNode).SA0.O0_1.SB.val,:);
FaultStats(StartNode).SA0.O0_1.SB.BlockEffect = FaultStats(StartNode).SA0.O0_1.SB.BlockEffect(1:FaultStats(StartNode).SA0.O0_1.SB.val);

FaultStats(StartNode).SA0.O0_1.NSB.val = FaultStats(StartNode).SA0.O0_1.NSB.val/(TimeSteps-1);
FaultStats(StartNode).SA0.O0_1.NSB.Pairs = FaultStats(StartNode).SA0.O0_1.NSB.Pairs(1:FaultStats(StartNode).SA0.O0_1.NSB.val,:);

%%%

FaultStats(StartNode).SA0.O1_0.FSB.val = FaultStats(StartNode).SA0.O1_0.FSB.val/(TimeSteps-1);
FaultStats(StartNode).SA0.O1_0.FSB.Pairs = FaultStats(StartNode).SA0.O1_0.FSB.Pairs(1:FaultStats(StartNode).SA0.O1_0.FSB.val,:);

FaultStats(StartNode).SA0.O1_0.SB.val = FaultStats(StartNode).SA0.O1_0.SB.val/(TimeSteps-1);
FaultStats(StartNode).SA0.O1_0.SB.Pairs = FaultStats(StartNode).SA0.O1_0.SB.Pairs(1:FaultStats(StartNode).SA0.O1_0.SB.val,:);
FaultStats(StartNode).SA0.O1_0.SB.BlockEffect = FaultStats(StartNode).SA0.O1_0.SB.BlockEffect(1:FaultStats(StartNode).SA0.O1_0.SB.val);

FaultStats(StartNode).SA0.O1_0.NSB.val = FaultStats(StartNode).SA0.O1_0.NSB.val/(TimeSteps-1);
FaultStats(StartNode).SA0.O1_0.NSB.Pairs = FaultStats(StartNode).SA0.O1_0.NSB.Pairs(1:FaultStats(StartNode).SA0.O1_0.NSB.val,:);

end
NormOut = FaultStats(StartNode);