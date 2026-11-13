function [FuncOut] = FuncExpand(s,func,Inputs,InputValues);
% FUNCTION:
% This function expands the function output of given the function with don't cares into a
% full function output.

% INPUTS
% 1. S: first element containes Node number, second element containes number 
%    of inputs, rest of elements are the actual inputs to this node 
%    e.g (6 2 5 19) where 6 is the node in question, which has two inputs 
%    which are 5 and 19. 
% 2. Node(n).StateSpace: contains the state space in .bns format 
%    e.g 
%    10 
%    0- 
%    -1
%
% 3. Inputs: The inputs of the network given they are inputs to the
%    function
% 4. InputValues: The SA values of the inputs of the network


% START
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Total Number of States
No_States = 2^s(2);
FuncOut = [];
if No_States == 2
    if str2num(func(1,1)) == 0
        FuncOut(1) = str2num(func(1,end));
        FuncOut(2) = str2num(func(2,end));
    else
        FuncOut(1) = str2num(func(2,end));
        FuncOut(2) = str2num(func(1,end));
    end
else

% Creating All Binary States
for i = 1:No_States
    %BinMat(i,:) =  dec2binvec(i-1,s(2));
    out = dec2bin(i-1,s(2));
    BinMat(i,:) = logical(str2num([fliplr(out);blanks(length(out))]')');
end
BinMat = fliplr(BinMat);

% if sum(Inputs) ~= 0
%     for i=1:length(Inputs)
%          BinMat(:,Inputs(i)) = InputValues(i)*ones(1,No_States);
%     end
%  end

FuncOut = [];
nMax=size(func);
nMax= nMax(1);
for n=1:nMax
    mask = zeros(1,s(2));
    cnt=0;
    ImpStates=0;
    OutState=0;
    MatchStates=0;
    for i=1:s(2)
        if func(n,i)~='-'
            cnt = cnt+1;
            ImpStates(cnt) = i;
            mask(i) = str2num(func(n,i));
        end
    end
    OutState = str2num(func(n,end));
    MatchStates = ~xor(BinMat,repmat(mask,No_States,1));
    for j = 1:No_States
        if MatchStates(j,ImpStates)==1
            FuncOut(j) = OutState;
        end
    end
end

end

% END
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
