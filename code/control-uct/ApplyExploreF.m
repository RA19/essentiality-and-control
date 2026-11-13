function [Newstate MoveApplied TreeNodes TreeMoves] = ApplyExploreF(state,PreviousMoves,MoveList,TreeNodes,TreeMoves,NodeCount,depth,RankedList);
% UCT EXPLORE MOVE STAGE


%Finding branches of given node from current tree
[val MovesApplied] = find(state==TreeNodes);

%Finding Moves applied to reach current leaf (PreviousMoves)
% & moves already explored once from this leaf (MovesApplied)

CurrentMoves = [PreviousMoves TreeMoves(MovesApplied)];

if depth==0
    TempMoveList = setdiff(MoveList,[NodeCount NodeCount-1]);% Hence we cannot apply last two nodes!
elseif depth==1
    TempMoveList = setdiff(MoveList,[NodeCount]); % Hence We Cannot Apply Last Node
else
    TempMoveList = MoveList;

end
% Assumption is that Highest Depth is 3. Thereofre we can apply anything
% from depth 2.

if isempty(CurrentMoves)==1
    % No Moves to get to state - No Moves Explored from state (VERY START)
    NewVec = TempMoveList; 
elseif isempty(TreeMoves(MovesApplied))==1
    % Nothing Explored YET from current state, but move has been applied to
    % get to state. Therefore we are free in choosing the next move
    % randomly from a movelist > then previous move applied
    NewVec = intersect(TempMoveList,[PreviousMoves(end)+1:NodeCount]);
elseif isempty(PreviousMoves)==1
    % NO Previous moves applied to get to state, however we have explored
    % already some moves from this state, therefore only restraint is not
    % to repeat exploratory moves
    NewVec = setdiff(TempMoveList,TreeMoves(MovesApplied));
else
    % Previous move applied to get to state AND some moves already explored
    NewVec = intersect(TempMoveList,[PreviousMoves(end)+1:NodeCount]);
    NewVec = setdiff(NewVec,TreeMoves(MovesApplied));
end
if isempty(NewVec)==1
    stop=1;
end

% UNIFORM RANDOM SELECTION OF ARM TO EXPLORE
% Choosing one move Randomly (Uniform) to apply
RandMoveIndex = randperm(length(NewVec));
Move = NewVec(RandMoveIndex(1));

% Find Next state
TreeNodes = [TreeNodes state];
Newstate = length(TreeNodes);

TreeMoves = [TreeMoves  Move];
MoveApplied = Move;

