function RAVE(s,a,TreeMoves,TreeNodes,EndReward);

global RStateActionCounts
global RUCT

%%%%%%%%%%%%%% UCT RAVE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
% Position of moves in current tree
if length(s)==1
     % No Difference
     for i=1:length(a);
         actuala(i) = find(TreeMoves(TreeNodes==s(i))==a(i));
     end
     a = actuala;
 
     for i=1:length(s)
 
         % if state action never encountered then initialize count to 1
         % and UCT value to reward value
         if size(RStateActionCounts,1) < s(i) || size(RStateActionCounts,2) < a(i)
             RStateActionCounts(s(i),a(i)) = 1;
             RUCT(s(i),a(i)) = EndReward;
         elseif RStateActionCounts(s(i),a(i)) == 0
             RStateActionCounts(s(i),a(i)) =1;
             RUCT(s(i),a(i)) = EndReward;
         else %already encountered
             % Incrementing State Action Counters
             RStateActionCounts(s(i),a(i)) = RStateActionCounts(s(i),a(i)) + 1;
             % Updating UCT value
             RUCT(s(i),a(i)) = RUCT(s(i),a(i)) + (1/RStateActionCounts(s(i),a(i)))*(EndReward - RUCT(s(i),a(i)) );
         end
     end
     
 elseif length(s)==2
     % s0 -> m2    
     for i=1:length(a);
         actuala(i) = find(TreeMoves(TreeNodes==s(i))==a(i));
     end
     if isempty(find(TreeMoves(TreeNodes==s(1))==a(2)))~=1
         actuala(i+1) = find(TreeMoves(TreeNodes==s(1))==a(2));
         a = actuala;
         s = [s s(1)];
     else
         a=actuala;
     end
     for i=1:length(s)
     
         % if state action never encountered then initialize count to 1
         % and UCT value to reward value
         if size(RStateActionCounts,1) < s(i) || size(RStateActionCounts,2) < a(i)
             RStateActionCounts(s(i),a(i)) = 1;
             RUCT(s(i),a(i)) = EndReward;
         elseif RStateActionCounts(s(i),a(i)) == 0
             RStateActionCounts(s(i),a(i)) =1;
             RUCT(s(i),a(i)) = EndReward;
         else %already encountered
     
             % Incrementing State Action Counters
             RStateActionCounts(s(i),a(i)) = RStateActionCounts(s(i),a(i)) + 1;
             % Updating UCT value
             RUCT(s(i),a(i)) = RUCT(s(i),a(i)) + (1/RStateActionCounts(s(i),a(i)))*(EndReward - RUCT(s(i),a(i)) );
         end
     end
     
 elseif length(s)==3
     % s0 -> m2, s0 -> m3, s1 -> m3
     for i=1:length(a);
         actuala(i) = find(TreeMoves(TreeNodes==s(i))==a(i));
     end
     cnt=i;
     if isempty(find(TreeMoves(TreeNodes==s(1))==a(2)))~=1
         cnt=cnt+1;
         actuala(cnt) = find(TreeMoves(TreeNodes==s(1))==a(2));
         s = [s s(1)];
     end
     if isempty(find(TreeMoves(TreeNodes==s(1))==a(3)))~=1
         cnt=cnt+1;
         actuala(cnt) = find(TreeMoves(TreeNodes==s(1))==a(3));
         s = [s s(1)];
     end
     if isempty(find(TreeMoves(TreeNodes==s(2))==a(3)))~=1
         cnt=cnt+1;
         actuala(cnt) = find(TreeMoves(TreeNodes==s(2))==a(3));
         s = [s s(2)];
     end
        
     a = actuala;
     
     
     for i=1:length(s)
 
         % if state action never encountered then initialize count to 1
         % and UCT value to reward value
         if size(RStateActionCounts,1) < s(i) || size(RStateActionCounts,2) < a(i)
             RStateActionCounts(s(i),a(i)) = 1;
             RUCT(s(i),a(i)) = EndReward;
         elseif RStateActionCounts(s(i),a(i)) == 0
             RStateActionCounts(s(i),a(i)) =1;
             RUCT(s(i),a(i)) = EndReward;
         else %already encountered
     
             % Incrementing State Action Counters
             RStateActionCounts(s(i),a(i)) = RStateActionCounts(s(i),a(i)) + 1;
             % Updating UCT value
             RUCT(s(i),a(i)) = RUCT(s(i),a(i)) + (1/RStateActionCounts(s(i),a(i)))*(EndReward - RUCT(s(i),a(i)) );
         end
     end
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
 
 end
 
end