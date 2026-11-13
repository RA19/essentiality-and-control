% run_essentiality.m — Showcase driver for the EPP-DP essentiality code.
%
% NEW driver script — the original algorithm files in code/essentiality/
% are NOT modified. This driver replicates the loop in EPP_DP.m but keeps
% the per-node DP results (ProbMatrix, SeqMatrix, MLSeq) so that
% fault-propagation figures can be generated.
%
% Run (from repository root):
%   octave-cli examples/run_essentiality.m
%
% Outputs:
%   results/generated/epp_dp_thelper.mat   (all raw results)
%   results/generated/node_names.txt       (gene names, one per line)
%   results/generated/prob_matrix_nodeNN.csv  (46 x TimeSteps per node)
%   results/generated/prob_vector.csv      (NodeCount x TimeSteps)
%   results/generated/final_ranks.csv      (node, mean rank)

clear; clc;

repo_root = fileparts(fileparts(mfilename('fullpath')));
code_dir  = fullfile(repo_root, 'code', 'essentiality');
out_dir   = fullfile(repo_root, 'results', 'generated');
if ~exist(out_dir, 'dir'); mkdir(out_dir); end
cd(code_dir);

load THelpAttractor
load THelpTruth
file = textread('thelper.txt', '%s', 'delimiter', '\n', 'whitespace', '');
NodeCount = 23;
In = [1 3 5 9];
InVals = [0 0 0 0];
TDecay = 3;
TimeSteps = 5;
MutationType = 1;   % 1 = stuck-at-0 fault, 2 = stuck-at-1

% 1. Fault statistics from the Boolean network definition
[FStats Node F varF nv] = readingtext(file, In, NodeCount, InVals);

% 2. Error-propagation probability matrices
[P1_0MAT P0_1MAT NewBiasMAT] = EPPMatrices(FStats);

% 3. EPP-DP for every node — keep per-node matrices for figures
SA_Fault = MutationType;
ProbMatrixAll = cell(NodeCount, 1);
SeqMatrixAll  = cell(NodeCount, 1);
for n = 1:NodeCount
    [ProbMatrix SeqMatrix MLSeq(n,:) Faults] = DPALGONEW( ...
        n, SA_Fault, FStats, P0_1MAT, P1_0MAT, NewBiasMAT, ...
        NodeCount, TimeSteps, TDecay);
    FaultStats(n) = Faults(n);
    ProbVector(n,:) = sum(ProbMatrix);
    ProbMatrixAll{n} = ProbMatrix;
    SeqMatrixAll{n}  = SeqMatrix;
    printf('EPP-DP done for node %d / %d\n', n, NodeCount);
end

% 4. Rankings (as in EPP_DP.m)
for t = 1:TimeSteps
    [Val Ind] = sort(ProbVector(:,t));
    for n = 1:NodeCount
        RankMat(n,t) = find(flipud(Ind) == n);
    end
end
for n = 1:NodeCount
    MeanRanks(n) = mean(RankMat(n,:));
end
[MeanRank Rank] = sort(MeanRanks);
FinalRanks = [flipud(Rank)' flipud(MeanRank)']

% ---- save everything ----
save('-mat', fullfile(out_dir, 'epp_dp_thelper.mat'));

% node names (strip the "x" prefix used inside the text format)
fid = fopen(fullfile(out_dir, 'node_names.txt'), 'w');
for n = 1:NodeCount
    nm = Node(n).Type;              % "# 1 = TCR" -> "TCR"
    eq = strfind(nm, '=');
    if ~isempty(eq); nm = strtrim(nm(eq(end)+1:end)); end
    fprintf(fid, '%s\n', nm);
end
fclose(fid);

for n = 1:NodeCount
    csvwrite(fullfile(out_dir, sprintf('prob_matrix_node%02d.csv', n)), ...
             ProbMatrixAll{n});
end
csvwrite(fullfile(out_dir, 'prob_vector.csv'), ProbVector);
csvwrite(fullfile(out_dir, 'final_ranks.csv'), FinalRanks);
printf('Saved results to %s\n', out_dir);
