function [Exploit] = AllExploredF(CurrentState,NodeCount,depth,TreeNodes,TreeMoves,MoveToParent,ControlNode);
% Finding moves applied from current node - or rather, finding if node in
% tree has branced out maturely
if depth==0;
    SumOfBranches = length(unique(TreeMoves(TreeNodes==1)));
    %Finding branches of given node from current tree
    if (NodeCount-4) == SumOfBranches %then all moves from current node explored at least once
        % Exploit
        Exploit=1;
    else
        %Explore
        Exploit=0;
    end
elseif depth==1
    MovesAppFromState = unique(TreeMoves(TreeNodes==CurrentState));
    SumOfBranches = length(MovesAppFromState);
    counter=0;
    if ControlNode > MoveToParent  % So if MovetoParent = 5.. and we have 10 nodes. then  4 values are possible after 5, however if ControlNode > 5, then 3 values are left.
        counter=counter+1;
    end
    if (ControlNode+(NodeCount/2)) > MoveToParent;
            counter=counter+1;
    end
    if (NodeCount - counter - MoveToParent -1) == SumOfBranches
        % Exploit
        Exploit=1;
    else
        %Explore
        Exploit=0;
    end
    
elseif depth==2
    
    MovesAppFromState = unique(TreeMoves(TreeNodes==CurrentState));
    SumOfBranches = length(MovesAppFromState);
    counter=0;
    if ControlNode > MoveToParent  % So if MovetoParent = 5.. and we have 10 nodes. then  4 values are possible after 5, however if ControlNode > 5, then 3 values are left.
        counter=counter+1;
    end
    if (ControlNode+(NodeCount/2)) > MoveToParent;
            counter=counter+1;
    end
    if (NodeCount - counter - MoveToParent) == SumOfBranches
        % Exploit
        Exploit=1;
    else
        %Explore
        Exploit=0;
    end
    
end

    

