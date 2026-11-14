function test_native()
%TEST_NATIVE Analytic dynamics, truth-table equivalence and legal searches.
root = fileparts(fileparts(mfilename('fullpath')));
old = pwd; cleanup = onCleanup(@() cd(old));
cd(fullfile(root,'code','control-gpb')); addpath(pwd);
load TCellNetworkData
F = NetData.F; varF = NetData.varF; nv = NetData.nv;
rng(17,'twister');
for trial = 1:100
    x = double(rand(1,40)>.5); expected = x;
    for i = 1:40
        if nv(i)>0
            index = x(varF(1:nv(i),i))*2.^(nv(i)-1:-1:0)'+1;
            expected(i) = F(index,i);
        end
    end
    assert(isequal(expected,bnNextStateGP(x,F,varF,nv)));
end
[endpoint,cycle] = FindAtt(0,[1;0],1,1,1);
assert(size(cycle,1)==2 && any(endpoint==cycle));
cd(fullfile(root,'code','essentiality')); addpath(pwd);
[means,ranks] = rank_fault_scores([1 4;1 2;0 2]);
assert(isequal(ranks,[1.5 1;1.5 2.5;3 2.5]));
% A holds its value; B is NOT A. With unbiased inputs, a source ON
% error transmits a 1->0 error to B with local likelihood one half.
evalc('stats(1)=ErrorProp([1 1 1],.5,0,[0;1],0); stats(2)=ErrorProp([2 1 1],.5,0,[1;0],0);');
stats = InputLike(stats,[]); [p10,p01,bias] = EPPMatrices(stats);
[sa1,parents] = EPPDPALGOR(1,1,stats,p01,p10,bias,2,4,4);
sa0 = EPPDPALGOR(1,2,stats,p01,p10,bias,2,4,4);
assert(isequal(sa1,[ones(1,4);zeros(2,4);.5*ones(1,4)]));
assert(isequal(sa0,[zeros(1,4);.5*ones(1,4);ones(1,4);zeros(1,4)]));
assert(all(parents(4,2:end)==1));
pulse = EPPDPALGOR(1,1,stats,p01,p10,bias,2,4,3);
assert(pulse(1,3)==1 && pulse(1,4)==.5);
one_step = EPPDPALGOR(1,1,stats,p01,p10,bias,2,4,1);
assert(one_step(1,1)==1 && one_step(1,2)==.5);
cd(fullfile(root,'code','control-uct')); addpath(pwd,'-begin');
assert(~any(ismember(control_candidates(1:80,[2 43],40),[2 42 3 43])));
% Both rank classes must be sampled: the old loop always chose the last.
rng(33,'twister'); draws = zeros(1,500);
for i=1:500; draws(i)=HeuristicExplore([1 2],[1 2]); end
assert(any(draws==1) && any(draws==2));
% Cross root saturation to exercise exploitation as well as exploration.
for variant = {'P','C'}
    rng(31,'twister');
    evalc('run = feval([''UCTAlgo'' variant{1}],90,2,2,.15,11,1,1,1000);');
    for i=1:size(run.SolutionsApplied,1)
        actions = run.SolutionsApplied(i,:);
        assert(length(unique(mod(actions-1,40)+1))==3);
        assert(~any(mod(actions-1,40)+1==11));
        if strcmp(variant{1},'C'); assert(all(diff(actions)>0)); end
    end
    [best,index] = max(run.RolloutBestRewards);
    assert(best == run.BestSolution.Reward);
    assert(isequal(run.SolutionsApplied(index,:),run.BestSolution.GeneMutations));
end
fprintf('Native checks passed: truth tables, complete cycles, ties, legal UCT policies and reward bookkeeping.\n');
end
