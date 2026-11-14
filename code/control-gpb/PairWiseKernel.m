function [Node F varF nv] = PairWiseKernel(In,NodeCount,InVals)

% Reading Input Test file in .bns format
file = textread('Tcell.txt', '%s', 'delimiter', '\n', 'whitespace', '');
l=1;
for n=1:NodeCount
     Node(n).Type = file{l};
     Node(n).Inputs = file{l+1};
     l=l+2;
    
% For  Random Nets
%       Node(n).Type = n;
%       Node(n).Inputs = file{l};
%       l=l+1;
    
      cnt=0;
    while isempty(file{l})==0
        cnt=cnt+1;
        Node(n).StateSpace(cnt,:) = file{l};
        l=l+1;
    end
    l=l+1;
end

Count = [1:NodeCount];
for i = 1:length(In)
    Count = Count(Count~=In(i));
end
    
for n=Count;
    s = strread(Node(n).Inputs(3:end));
    nv(s(1)) = s(2);
    % Creating Variable Matrix
    % All values in column j represent the variables which determine the value
    % of the variable j
    varF(1:s(2),s(1)) = s(3:end);
    Inputs=0;
    InputValues=0;
    Incnt=0;
    for i =1:length(In)
        if find(s(3:end)==In(i)) ~=0 
                Incnt=Incnt+1;
                Inputs(Incnt) = find(s(3:end)==In(i));
                InputValues(Incnt)=InVals(i);
        end
    end
    % Expanding Function Matrix with Don't Cares to all states
    [Fout] = FuncExpand(s,Node(n).StateSpace,Inputs,InputValues);
    FuncOut(1:2^s(2),s(1)) = Fout;
   
end

% Inputs
if sum(In) ~= 0
     
for i = 1:length(In)
    s = strread(Node(In(i)).Inputs(3:end));
    % Creating Variable Matrix
    varF(:,s(1)) = In(i);
    FuncOut(:,s(1)) = InVals(i);
    FuncOut(1,s(1)) = InVals(i);
    nv(s(1)) = 1;
end
end
F=-1*ones(size(FuncOut,1),size(FuncOut,2));
for n=1:size(FuncOut,2);
     F(1:2^nv(n),n) = FuncOut(1:2^nv(n),n);
end


% Network read and Created
% F - columns represent Nodes, values in each column represents function
% output
% varF - columns represent Nodes, values in each column shows which nodes
% are an input
% nv - columns represent Nodes, values represent the number of its inputs



% Calculating Pair-Wise Kernel
 RealNodeCount=NodeCount;
 FNodeCount=RealNodeCount*2;

FSA=zeros(2^max(nv),RealNodeCount,FNodeCount);
% Generating SA Fault Networks
for n=1:FNodeCount
    if n <=RealNodeCount % SA0
        Fnew=F;
        Fnew(F(:,n)~=-1 ,n)   = 0;
        FSA(:,:,n) = Fnew;
    else
        realn = n - RealNodeCount; %SA1
        Fnew=F;
        Fnew(F(:,realn)~=-1 ,realn)   = 1;
        FSA(:,:,n) = Fnew;
    end
end

runs=100;
ErrorVector = zeros(FNodeCount,RealNodeCount*2);
K=zeros(FNodeCount,FNodeCount);
KNew=K;
NodeSums=zeros(1,RealNodeCount);
for count=1:runs;

% Random Start State
xreal = logical(rand(1,RealNodeCount) >0.5);
x = xreal;
% Finding Attractor Reached by wild-type network
[yAttOrig] = FindAtt(x,F,varF,nv,RealNodeCount);
NodeSums = NodeSums + yAttOrig;
for n=1:FNodeCount
    x = xreal;
    % Finding Attractor Reached by mutated network
    [yAtt] = FindAtt(x,FSA(:,:,n),varF,nv,RealNodeCount);
    EV(n,:) = [(yAttOrig-yAtt)==-1,(yAttOrig-yAtt)==1];
end

% RBF parameter
sig=0.5/100;
const=-(1/(2*sig^2));
for i=1:FNodeCount
    for j=1:FNodeCount
        x=EV(i,:)+zeros(1,RealNodeCount*2);
        z=EV(j,:)+zeros(1,RealNodeCount*2);
        % RBF Kernel
        K(i,j) = exp(const*(x*x' +z*z' -2*(x*z')));
    end
end
KNew = KNew + K;
out1 = sprintf('%s %d ','Pair-wise Kernel Matrix iteration :',count);
disp(out1)
end
% Normalizing Kernel Matrix
D = diag(1./sqrt(diag(KNew)));
KNew = D*KNew*D;

% Calculation average value of each node in the attractors
NodeAvgs = NodeSums./runs;


% Storing Network Data
NetData.F = F;
NetData.varF = varF;
NetData.nv = nv;
save('TCellNetworkData','NetData','KNew','NodeAvgs','sig','runs');

