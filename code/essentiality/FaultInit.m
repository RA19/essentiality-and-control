function [EmptyStats] = FaultInit(NodeCount);


FaultStats.SA1.O0_1.FSB.val = 0;
FaultStats.SA1.O0_1.FSB.Pairs =[];
FaultStats.SA1.O0_1.SB.val = 0;
FaultStats.SA1.O0_1.SB.Pairs =[];
FaultStats.SA1.O0_1.SB.BlockEffect=0;
FaultStats.SA1.O0_1.NSB.val = 0;
FaultStats.SA1.O0_1.NSB.Pairs =[]; 

FaultStats.SA1.O1_0.FSB.val = 0;
FaultStats.SA1.O1_0.FSB.Pairs =[];
FaultStats.SA1.O1_0.SB.val = 0;
FaultStats.SA1.O1_0.SB.Pairs =[];
FaultStats.SA1.O1_0.SB.BlockEffect=0;
FaultStats.SA1.O1_0.NSB.val = 0;
FaultStats.SA1.O1_0.NSB.Pairs =[]; 

FaultStats.SA0.O0_1.FSB.val = 0;
FaultStats.SA0.O0_1.FSB.Pairs =[];
FaultStats.SA0.O0_1.SB.val = 0;
FaultStats.SA0.O0_1.SB.Pairs =[];
FaultStats.SA0.O0_1.SB.BlockEffect=0;
FaultStats.SA0.O0_1.NSB.val = 0;
FaultStats.SA0.O0_1.NSB.Pairs =[]; 

FaultStats.SA0.O1_0.FSB.val = 0;
FaultStats.SA0.O1_0.FSB.Pairs =[];
FaultStats.SA0.O1_0.SB.val = 0;
FaultStats.SA0.O1_0.SB.Pairs =[];
FaultStats.SA0.O1_0.SB.BlockEffect=0;
FaultStats.SA0.O1_0.NSB.val = 0;
FaultStats.SA0.O1_0.NSB.Pairs =[]; 

for n=1:NodeCount
    EmptyStats(n) = FaultStats;
end