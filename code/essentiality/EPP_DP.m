load THelpAttractor
load THelpTruth
file = textread('thelper.txt', '%s', 'delimiter', '\n', 'whitespace', '');
NodeCount = 23;
In = [1 3 5 9];
InVals = [ 0 0 0 0];
TDecay=3;
TimeSteps=5;
MutationType=1

% 1
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% Generating Fault Statistics 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
[FStats Node F varF nv] = readingtext(file,In,NodeCount,InVals);


% 2
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% Generating Error Propogation Probability Matrices
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
[P1_0MAT P0_1MAT NewBiasMAT] = EPPMatrices(FStats);

% 3
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% Running EPP-DP centrality measure for each node
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
SA_Fault = MutationType;
for n=1:NodeCount
        % Error Propagation DP Algorithm
        [ProbMatrix SeqMatrix MLSeq(n,:) Faults] = DPALGONEW(n,SA_Fault,FStats,P0_1MAT,P1_0MAT,NewBiasMAT,NodeCount,TimeSteps,TDecay);
        FaultStats(n) = Faults(n);
        if SA_Fault==1
            % ProbMatrix(n,:) = 0;
        elseif SA_Fault==2
            % ProbMatrix(n+NodeCount,:)=0;
        end
        ProbVector(n,:) = sum(ProbMatrix);
        out1 = sprintf('%s %d','Calculating Error Propagation Probability for Node ',n);
        disp(out1)
end


% 4
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% Generating Rankings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
for t=1:TimeSteps
    [Val Ind] = sort(ProbVector(:,t));
    for n=1:NodeCount
        RankMat(n,t) = find(flipud(Ind) == n);
    end
end
for n=1:NodeCount
    MeanRanks(n) = mean(RankMat(n,:));
end
[MeanRank Rank] = sort(MeanRanks);
FinalRanks = [flipud(Rank)' flipud(MeanRank)']

