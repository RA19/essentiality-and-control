function [P1_0MAT P0_1MAT NewBiasMAT] = EPPMatrices(FStats);

% This function uses the Fault Statisics to turn the required 
% data by the EPP-DP into Matrix form for quicker access.

NodeCount = length(FStats);

P1_0MAT = zeros(NodeCount,NodeCount,2);

for func = 1:NodeCount
    for node = 1:length(FStats(func).Inputs)
        P1_0MAT(func,FStats(func).Inputs(node),1) = FStats(func).SA1Input(node).POutput1_0.Normval;
        P1_0MAT(func,FStats(func).Inputs(node),2) = FStats(func).SA0Input(node).POutput1_0.Normval;
    
    end
end


P0_1MAT = zeros(NodeCount,NodeCount,2);

for func = 1:NodeCount
    for node = 1:length(FStats(func).Inputs)
        P0_1MAT(func,FStats(func).Inputs(node),1) = FStats(func).SA1Input(node).POutput0_1.Normval;
        P0_1MAT(func,FStats(func).Inputs(node),2) = FStats(func).SA0Input(node).POutput0_1.Normval;
    end
end

NewBiasMAT = zeros(NodeCount,NodeCount,2);
% Column represents the SA input
% Row represents the outputs on which the SA input acts upon
% Element(i,j) represents that SA input on node j changes the bias of node
% i to the respective value

for func = 1:NodeCount
    for node = 1:length(FStats(func).Inputs)
        NewBiasMAT(func,FStats(func).Inputs(node),1) = FStats(func).SA1Input(node).NewBias;
        NewBiasMAT(func,FStats(func).Inputs(node),2) = FStats(func).SA0Input(node).NewBias;
    end
end

