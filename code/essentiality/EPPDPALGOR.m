function [scores, predecessor, path, fault_stats] = EPPDPALGOR(source, fault_code, stats, P01, P10, bias_matrix, n, steps, source_duration)
%EPPDPALGOR Max-product error propagation, derived from the GSK toolbox.
% fault_code = 1 means SA1 (forced ON); 2 means SA0 (forced OFF).
% Rows 1:n describe output errors 0->1; rows n+1:2*n describe 1->0.
% Each entry is the score of the most likely fault path, not a marginal
% probability summing all possible paths. source_duration specifies how many
% DP columns keep the source error clamped; set it to steps for persistence.
%
% stats contains local truth-table fault statistics and input-state biases.
% P01/P10 initialize the recurrence. bias_matrix is retained in the original
% calling signature; local state probabilities in stats govern later steps.
% predecessor records the maximizing predecessor, allowing exact traceback.
validateattributes(source, {'numeric'}, {'scalar','integer','>=',1,'<=',n});
validateattributes(fault_code, {'numeric'}, {'scalar','integer','>=',1,'<=',2});
validateattributes(steps, {'numeric'}, {'scalar','integer','>=',1});
validateattributes(source_duration, {'numeric'}, {'scalar','integer','>=',1});
scores = zeros(2*n, steps);
predecessor = zeros(2*n, steps);
scores(:,1) = [P01(:,source,fault_code); P10(:,source,fault_code)];
predecessor(scores(:,1)>0,1) = source;
source_row = source + (fault_code == 2)*n;
scores([source source+n],1) = 0;
scores(source_row,1) = 1;
predecessor(source_row,1) = source;
transition = {[P01(:,:,1) P01(:,:,2)], [P10(:,:,1) P10(:,:,2)]};
for t = 2:steps
    for row = 1:2*n
        target = mod(row-1,n)+1;
        output_error = 1 + (row > n);
        if ~any(transition{output_error}(target,:))
            continue;
        end
        weights = zeros(1,2*n);
        for position = 1:length(stats(target).Inputs)
            input = stats(target).Inputs(position);
            for input_error = 1:2
                weights(input+(input_error-1)*n) = local_likelihood( ...
                    stats(target), position, input_error, output_error);
            end
        end
        [scores(row,t), parent] = max(weights .* scores(:,t-1)');
        if scores(row,t) > 0
            predecessor(row,t) = parent;
        end
    end
    if t <= source_duration
        scores([source source+n],t) = 0;
        scores(source_row,t) = 1;
        predecessor(source_row,t) = source_row;
    end
end

% Follow one maximizing path back from the strongest final error state.
% Unlike the original traceback, do not replace its first parent with an
% unrelated column maximum. Both error channels keep separate predecessors.
path = zeros(1,steps+1);
path(1) = source;
[last_score, row] = max(scores(:,end));
if last_score > 0
    path(end) = row;
    for t = steps:-1:2
        path(t) = predecessor(path(t+1),t);
        if path(t) == 0; break; end
    end
end
fault_stats = FaultInit(n);
fault_stats(source) = FaultNorm(fault_stats,source,steps,fault_code);
fault_stats(source).Involved = 0;
end

function probability = local_likelihood(target, position, input_error, output_error)
% Probability mass of the local input states that transmit this error.
if input_error == 1
    input_stats = target.SA1Input(position);
else
    input_stats = target.SA0Input(position);
end
if output_error == 1
    propagation = input_stats.POutput0_1;
    state_field = 'OnNodes0_1';
else
    propagation = input_stats.POutput1_0;
    state_field = 'OnNodes1_0';
end
probability = 0;
if propagation.val <= 0; return; end
if length(target.Inputs) == 1
    states = propagation.PropState;
else
    state_values = propagation.(state_field);
    states = state_values(propagation.PropState > 0,:) > 0;
    % Recover the original input state before imposing the upstream error.
    states(:,position) = (input_error == 2);
    states = states * (2.^(size(states,2)-1:-1:0))' + 1;
end
probability = sum(target.StateProb(states));
end
