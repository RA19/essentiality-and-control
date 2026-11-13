function [EndReward] = ApplySAFaults(Genes,NetData,NodeCount,TDepth,ControlNode,ControlValue,runs,CREB_FLAG,XTRA);
% Extracting Final Reward on Gene Mutation Triplet Solution Applied

if CREB_FLAG==0; % NORMAL NETWORK
F = NetData.F;
varF = NetData.varF;
nv = NetData.nv;

% Applying SA Faults on chosen nodes
Fnew=F;
for n=1:TDepth
    if Genes(n) <= NodeCount % then SA0
        Fnew(Fnew(:,Genes(n))~=-1 ,Genes(n))   = 0;
        xSAval(n)=0;
        xSAGenes(n)=Genes(n);
    else % SA1
        NGenes = Genes(n) - NodeCount;
        Fnew(Fnew(:,NGenes)~=-1 ,NGenes)   = 1;
        xSAval(n)=1;
        xSAGenes(n)=NGenes;
    end
end


for r=1:runs
    % Random Start State
    x = logical(rand(1,NodeCount) >0.5);
    
    %Original Attractor
    [yAttOrig] = FindAtt(x,F,varF,nv,NodeCount);
    % SA Attractor
    x(xSAGenes) = xSAval;
    [yAtt] = FindAtt(x,Fnew,varF,nv,NodeCount);
    % Hamming Distance Reward
    HD(r) = sum(abs(yAttOrig - yAtt));
    HD(r)=HD(r)/NodeCount;
    % Control Reward
    CNodeVal(r) = yAtt(ControlNode);
    
   
end

elseif CREB_FLAG==1 % CREB NETWORK
    for n=1:TDepth
        if Genes(n) <= NodeCount % then SA0
            SANode(1,n) = Genes(n);
            SAType(1,n)=0;
        else % SA1
            SANode(1,n) = Genes(n) - NodeCount;
            SAType(1,n)=1;
        end
    end
    
    for r=1:runs

     x = logical(rand(1,NodeCount) >0.5);
     % Original Attractor
     [yAttOrig] = FindCREBAtt(x,NodeCount,NetData,[],-1,XTRA);
     
     % SA Attractor
     [yAtt] = FindCREBAtt(x,NodeCount,NetData,SANode,SAType,XTRA);
    
    HD(r) = sum(abs(yAttOrig - yAtt));
    HD(r)=HD(r)/NodeCount;
    CNodeVal(r) = yAtt(ControlNode);
    
    end
    
    
end
% Hamming Distance Reward
AvgHDVal = sum(HD)/runs; %Low Good
AvgCNodeVal = sum(CNodeVal)/runs;
HDReward = 1-AvgHDVal;
% Control Reward
if ControlValue==1
    ControlReward = AvgCNodeVal;
else
    ControlReward = 1-AvgCNodeVal;
end
% Final Reward
EndReward = HDReward*ControlReward; 