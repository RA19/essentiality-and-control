function UpdateTreeF(AppliedMoves,NodesTraversed,EndReward,TreeNodes,TreeMoves,n,Iters);
%  global StateActionCounts
%  global UCT
%  
 global RStateActionCounts
 global RUCT
  
 global NStateActionCounts
 global NUCT
 

%%%%%%%%%%%% Standard UCT %%%%%%%%%%%%%%%%
s=NodesTraversed(1:end-1); %since we are interested in state-action..and need to remove last state reeached
a=AppliedMoves; %Real Moves Applied

% Position of moves in current tree
for i=1:length(a);
    actuala(i) = find(TreeMoves(TreeNodes==s(i))==a(i));
end
a = actuala;

for i=1:length(s)
    % if state action never encountered then initialize count to 1
    % and UCT value to reward value
    if size(NStateActionCounts,1) < s(i) || size(NStateActionCounts,2) < a(i)
        NStateActionCounts(s(i),a(i)) = 1;
        NUCT(s(i),a(i)) = EndReward;
    elseif NStateActionCounts(s(i),a(i)) == 0
        NStateActionCounts(s(i),a(i)) =1;
        NUCT(s(i),a(i)) = EndReward;
    else %already encountered
    
    % Incrementing State Action Counters
    NStateActionCounts(s(i),a(i)) = NStateActionCounts(s(i),a(i)) + 1;
     % Updating UCT value
    NUCT(s(i),a(i)) = NUCT(s(i),a(i)) + (1/NStateActionCounts(s(i),a(i)))*(EndReward - NUCT(s(i),a(i)) );
    end

end


% UCT Rave %
s=NodesTraversed(1:end-1); %since we are interested in state-action..and need to remove last state reeached
a=AppliedMoves; %Real Moves Applied
RAVE(s,a,TreeMoves,TreeNodes,EndReward);



