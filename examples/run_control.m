% run_control.m — Showcase driver for the GPB / UCT control code.
%
% NEW driver — original algorithm files are untouched (the single exception
% is code/control-uct/ApplyExploitF.m, a documented reconstruction of a file
% that was never archived).
%
% Run (from repository root):
%   octave-cli examples/run_control.m [target] [gpb_iters] [uct_iters]
%     target      = target node index (default 10 = ZAP70, dissertation set)
%     gpb_iters   = GPB iterations   (default 120; dissertation used 449)
%     uct_iters   = UCT iterations   (default 300; dissertation used 1500)
%
% Outputs (results/generated/):
%   control_gpb.csv         — GPRun.Rewards per iteration
%   control_uct.csv         — UCTRun best-reward per iteration (if produced)
%   control_summary.txt     — best solutions, rewards, run parameters
%   attractor_pairs.csv     — wild-type vs controlled attractor states
%   node_names_tcell.txt    — 40 T-cell node names

clear; clc;
repo_root = fileparts(fileparts(mfilename('fullpath')));
out_dir   = fullfile(repo_root, 'results', 'generated');
if ~exist(out_dir, 'dir'); mkdir(out_dir); end

args = argv();
ControlNode  = 10;          % ZAP70
gpb_iters    = 120;
uct_iters    = 300;
if length(args) >= 1; ControlNode = str2num(args{1}); end
if length(args) >= 2; gpb_iters   = str2num(args{2}); end
if length(args) >= 3; uct_iters   = str2num(args{3}); end
ControlValue = 1;

% T-cell node names (from code/control-gpb/Tcell.txt header comments)
node_names = {'CD45','CD8','TCRlig','TCRbind','PAGCsk','LCK','Fyn','Rlk', ...
 'TCRphos','ZAP70','cCbl','Itk','LAT','Gads','Slp76','PLCg_b','Grb2Sos', ...
 'DAG','PLCg_a','Ras','RasGRP1','PKCth','IP3','Raf','MEK','Ca','ERK','SEK', ...
 'IKK','Calcin','Rsk','Fos','JNK','Ikb','CREB','Jun','CRE','AP1','NFkB','NFAT'};
fid = fopen(fullfile(out_dir,'node_names_tcell.txt'),'w');
for i=1:40; fprintf(fid,'%s\n',node_names{i}); end; fclose(fid);

printf('=== GPB run: target %s -> %d, %d iters ===\n', ...
       node_names{ControlNode}, ControlValue, gpb_iters);

% ---------------- GPB ----------------
cd(fullfile(repo_root, 'code', 'control-gpb'));
[GPRun] = GPClusterSearch(gpb_iters, 20, ControlNode, ControlValue);
csvwrite(fullfile(out_dir,'control_gpb.csv'), GPRun.Rewards(:));

% ---------------- attractor pairs under the GPB solution ----------------
load TCellNetworkData
NodeCount = 40;
F = NetData.F; varF = NetData.varF; nv = NetData.nv;
Genes = GPRun.BestSolution;
Fnew = F;
xSAval = []; xSAGenes = [];
for n=1:length(Genes)
    if Genes(n) <= NodeCount
        Fnew(Fnew(:,Genes(n))~=-1, Genes(n)) = 0;
        xSAval(end+1)=0; xSAGenes(end+1)=Genes(n);
    else
        NGenes = Genes(n) - NodeCount;
        Fnew(Fnew(:,NGenes)~=-1, NGenes) = 1;
        xSAval(end+1)=1; xSAGenes(end+1)=NGenes;
    end
end

R = 400;   % random starts for the attractor-landscape comparison
orig = zeros(R, NodeCount);
ctrl = zeros(R, NodeCount);
for r = 1:R
    x = logical(rand(1,NodeCount) > 0.5);
    yAttOrig = FindAtt(x, F, varF, nv, NodeCount);
    x2 = x; x2(xSAGenes) = xSAval;
    yAtt = FindAtt(x2, Fnew, varF, nv, NodeCount);
    orig(r,:) = yAttOrig;
    ctrl(r,:) = yAtt;
end
csvwrite(fullfile(out_dir,'attractor_pairs.csv'), [orig ctrl]);
HD = sum(abs(orig - ctrl),2)/NodeCount;
tgt_achieved = mean(ctrl(:,ControlNode) == ControlValue);
printf('GPB best solution: [%s]\n', num2str(GPRun.BestSolution));
printf('Attractor pairs: %d sampled, mean HD=%.3f, target achieved=%.2f\n', ...
       R, mean(HD), tgt_achieved);

% ---------------- UCT-RAVE (P-tree) ----------------
cd(fullfile(repo_root, 'code', 'control-uct'));
try
    [UCTRun] = UCTAlgoP(uct_iters, 10, 15, 0.15, ControlNode, ControlValue, 1, 1000);
    if isfield(UCTRun,'Rewards')
        csvwrite(fullfile(out_dir,'control_uct.csv'), UCTRun.Rewards(:));
    end
    save('-mat', fullfile(out_dir,'uct_run.mat'), 'UCTRun');
    printf('UCT done. fields: %s\n', strjoin(fieldnames(UCTRun),','));
catch e
    printf('UCT run failed: %s\n', e.message);
    disp(e.stack);
end

% ---------------- summary ----------------
fid = fopen(fullfile(out_dir,'control_summary.txt'),'w');
fprintf(fid,'target=%s(%d)->%d  gpb_iters=%d uct_iters=%d\n', ...
        node_names{ControlNode}, ControlNode, ControlValue, gpb_iters, uct_iters);
fprintf(fid,'GPB.BestSolution=[%s] final_reward=%.4f\n', ...
        num2str(GPRun.BestSolution), max(GPRun.Rewards));
fprintf(fid,'GPB genes decoded: ');
for n=1:length(Genes)
    g = Genes(n);
    if g <= NodeCount
        fprintf(fid,'%s=SA0 ', node_names{g});
    else
        fprintf(fid,'%s=SA1 ', node_names{g-NodeCount});
    end
end
fprintf(fid,'\nmean_HD=%.4f target_achieved=%.3f\n', mean(HD), tgt_achieved);
fclose(fid);
printf('Saved to %s\n', out_dir);
