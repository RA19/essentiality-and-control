function result = run_control(output_dir, gpb_iterations, uct_iterations)
%RUN_CONTROL Seeded GPB and UCT-RAVE searches on the 40-node T-cell network.
% The target cCbl is excluded from admissible interventions. The final policy
% is reevaluated on an independent bank of 512 starts, and complete cycles
% are retained for visualization. Search rewards use the original endpoint
% Hamming-distance objective; held-out cycle analysis is performed in Python.
root = fileparts(fileparts(mfilename('fullpath')));
if nargin < 1; output_dir = fullfile(root,'results','demo'); end
if nargin < 2; gpb_iterations = 200; end
if nargin < 3; uct_iterations = 180; end
if ~exist(output_dir,'dir'); mkdir(output_dir); end
old_directory = pwd; restore_directory = onCleanup(@() cd(old_directory));
rng(27,'twister');
target = 11; target_value = 1;
cd(fullfile(root,'code','control-gpb')); addpath(pwd);
fprintf('Searching for indirect control of cCbl -> ON with GPB...\n');
evalc('gpb = GPClusterSearch(gpb_iterations,24,target,target_value);');
load TCellNetworkData
F = NetData.F; varF = NetData.varF; nv = NetData.nv;
result.F = F; result.varF = varF; result.nv = nv;
result.gpb = gpb; result.target = target; result.target_value = target_value;
result.search_seed = 27;
genes = gpb.BestSolution;
assert(length(unique(mod(genes-1,40)+1))==3,'Policy must act on three distinct genes');
assert(~any(mod(genes-1,40)+1==target),'Indirect policy cannot clamp the target');
result.policy = genes;
Fnew = F; clamp_nodes = mod(genes-1,40)+1; clamp_values = genes>40;
for i = 1:3
    Fnew(Fnew(:,clamp_nodes(i))~=-1,clamp_nodes(i)) = clamp_values(i);
end
rng(2026,'twister');
result.evaluation_seed = 2026;
result.starts = double(rand(512,40)>0.5);
result.wild_type_endpoints = zeros(512,40);
result.controlled_endpoints = zeros(512,40);
result.wild_type_cycles = cell(512,1);
result.controlled_cycles = cell(512,1);
for r = 1:512
    x = result.starts(r,:);
    [result.wild_type_endpoints(r,:),result.wild_type_cycles{r}] = FindAtt(x,F,varF,nv,40);
    x(clamp_nodes) = clamp_values;
    [result.controlled_endpoints(r,:),result.controlled_cycles{r}] = FindAtt(x,Fnew,varF,nv,40);
end
if uct_iterations > 0
    fprintf('Searching with UCT-RAVE...\n');
    cd(fullfile(root,'code','control-uct')); addpath(pwd,'-begin');
    rng(31,'twister');
    evalc('uct = UCTAlgoP(uct_iterations,4,8,0.15,target,target_value,1,1000);');
    result.uct = uct;
    result.uct_seed = 31;
end
save(fullfile(output_dir,'control.mat'),'result','-v7');
fprintf('Saved control search and 512 paired wild-type/controlled attractors.\n');
end
