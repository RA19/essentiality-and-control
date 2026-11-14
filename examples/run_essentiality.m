function result = run_essentiality(output_dir)
%RUN_ESSENTIALITY Run both fault directions on the 23-node T-helper network.
% Saves only algorithm results and model data, with no workstation paths.
% Persistent faults are used for rankings; a three-step pulse provides the
% separate propagation/decay example. SA1=1 and SA0=2 in the original engine.
root = fileparts(fileparts(mfilename('fullpath')));
if nargin < 1; output_dir = fullfile(root,'results','demo'); end
if ~exist(output_dir,'dir'); mkdir(output_dir); end
old_directory = pwd; restore_directory = onCleanup(@() cd(old_directory));
cd(fullfile(root,'code','essentiality'));
addpath(pwd);
file = textread('thelper.txt','%s','delimiter','\n','whitespace','');
evalc('[stats,nodes,F,varF,nv] = readingtext(file,[1 3 5 9],23,[0 0 0 0]);');
[p10,p01,bias] = EPPMatrices(stats);
result.F = F; result.varF = varF; result.nv = nv;
result.steps = 8; result.pulse_duration = 3;
result.input_nodes = [1 3 5 9]; result.input_values = [0 0 0 0];
result.names = cell(1,23);
for i = 1:23
    label = nodes(i).Type; equals = strfind(label,'=');
    result.names{i} = strtrim(label(equals(end)+1:end));
end
for fault_value = 0:1
    fault_code = 2-fault_value;
    key = sprintf('sa%d',fault_value);
    scores = zeros(46,8,23); parents = zeros(46,8,23);
    pulse_scores = scores; pulse_parents = parents;
    for source = 1:23
        [scores(:,:,source),parents(:,:,source)] = EPPDPALGOR( ...
            source,fault_code,stats,p01,p10,bias,23,8,8);
        [pulse_scores(:,:,source),pulse_parents(:,:,source)] = EPPDPALGOR( ...
            source,fault_code,stats,p01,p10,bias,23,8,3);
    end
    influence = reshape(sum(scores,1),8,23)';
    [mean_rank,rank_by_step,order] = rank_fault_scores(influence);
    result.(key).scores = scores;
    result.(key).predecessor = parents;
    result.(key).pulse_scores = pulse_scores;
    result.(key).pulse_predecessor = pulse_parents;
    result.(key).influence = influence;
    result.(key).mean_rank = mean_rank;
    result.(key).rank_by_step = rank_by_step;
    result.(key).order = order;
end
save(fullfile(output_dir,'essentiality.mat'),'result','-v7');
fprintf('Saved SA0/SA1 essentiality and pulse propagation results.\n');
end
