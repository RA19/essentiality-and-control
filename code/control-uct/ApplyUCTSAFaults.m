function [EndReward] = ApplyUCTSAFaults(Genes,NetData,NodeCount,TDepth,ControlNode,ControlValue,runs);
% Final Reward Calculation for proposed Policy

assert(length(Genes)==TDepth && length(unique(mod(Genes-1,NodeCount)+1))==TDepth,'Each control gene must be distinct');
clamp_nodes = mod(Genes-1,NodeCount)+1;
clamp_values = Genes>NodeCount;

% Loading Network Data
F = NetData.F;
varF = NetData.varF;
nv = NetData.nv;

% Applying SA Faults on chosen nodes
Fnew=F;
% Decoding labels into genes and the respective stuck-at-fault
for n=1:TDepth
    if Genes(n) <= NodeCount % then SA0
        Fnew(Fnew(:,Genes(n))~=-1 ,Genes(n))   = 0;
    else % SA1
        NGenes = Genes(n) - NodeCount;
        Fnew(Fnew(:,NGenes)~=-1 ,NGenes)   = 1;
    end
end


for r=1:runs
    % Random Start State
    x = logical(rand(1,NodeCount) >0.5);
    % Original Attractor
    [yAttOrig] = FindAtt(x,F,varF,nv,NodeCount);
    % SA Attractor
    x(clamp_nodes) = clamp_values;
    [yAtt] = FindAtt(x,Fnew,varF,nv,NodeCount);
    % Hamming Distance Reward
    HD(r) = sum(abs(yAttOrig - yAtt));
    HD(r)=HD(r)/NodeCount;
    % Control Reward
    CNodeVal(r) = yAtt(ControlNode);
end

% Hamming Distance Reward
AvgHDVal = sum(HD)/runs; %Low Good
AvgCNodeVal = sum(CNodeVal)/runs;
HDReward = 1-AvgHDVal;

% Control Value Reward
if ControlValue==1
    ControlReward = AvgCNodeVal;
else
    ControlReward = 1-AvgCNodeVal;
end

% Final Reward: Hamming Dist Reward * Control Reward
EndReward = HDReward*ControlReward; 