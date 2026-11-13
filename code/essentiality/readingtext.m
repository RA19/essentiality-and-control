function [FStats Node F varF nv] = readingtext(file,In,NodeCount,InVals)


% file = textread('testing.txt', '%s', 'delimiter', '\n', 'whitespace', '');

% SECTION 1: START
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Extracting text from .bns file and 
% Storing the text related to each function seperately into 'Node' 

l=1;
for n=1:NodeCount
    % Use the following for the dubrova networks
    Node(n).Type = file{l};
    Node(n).Inputs = file{l+1};
    l=l+2;
    
    % Use the following for the randomly generated networks in .bns format    
    % Random Nets
    % Node(n).Type = n;
    % Node(n).Inputs = file{l};
    % l=l+1;
    
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

% Section 1: END
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    


% Section 2: START
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Now that we have seperated the text file into seperate information
% related to each node in 'Node' we will create the following data
% 1. nv
% 2. varF
% 3. FOut
% 4. FStats
% Please refer to documentation for explanation of each data variable

for n=Count;
    
    % Creating # inputs matrix nv
    s = strread(Node(n).Inputs(3:end));
    nv(s(1)) = s(2);
    
    % Creating Variable Matrix varF
    % All values in column j represent the variables which determine the value
    % of the variable j
    varF(1:s(2),s(1)) = s(3:end);
    
    % Extracting input states with don't cares from text
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
    
    % DON'T CARE REMOVAL
    % Expanding Function Matrix with Don't Cares to all states
    [Fout] = FuncExpand(s,Node(n).StateSpace,Inputs,InputValues);
    % Fout contains the FULL function table output
    FuncOut(1:2^s(2),s(1)) = Fout;
    
    % BIAS CALCULATION
    bias = sum(Fout)/length(Fout);
    % [bias] = BiasCalc(s,Inputs)
    
    % FAULT STATISTICS EXTRACTION
    [FStats(s(1))] = ErrorProp(s,bias,Inputs,Fout,InputValues);

end
% SECTION 2: END
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Arranging information on input nodes
if sum(In) ~= 0
    for i = 1:length(In)
        s = strread(Node(In(i)).Inputs(3:end));
        % Creating Variable Matrix
        varF(:,s(1)) = In(i);
        FuncOut(:,s(1)) = InVals(i);
        FuncOut(1,s(1)) = InVals(i);
        nv(s(1)) = 1;
        FStats(s(1)).Bias=InVals(i);
    end
 end

% Extracting Input-State Probabilities for each Function
[FStats] = InputLike(FStats,In);
F = FuncOut;

% Adding the NAMES of the nodes to the fault statistics
for n=1:length(FStats)
    for h=1:length(Node(n).Type)
        if  (Node(n).Type(h) == '=')==1
            FStats(n).Name=Node(n).Type(h+1:end);
        end
    end
end
    