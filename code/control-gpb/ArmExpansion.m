function [NewArms] = ArmExpansion(NewNodes,RealNodeCount,ControlNode,CurrentNodes,TDepth); 

% Finding New Set of Arms possible between New Nodes Added and Current
% Nodes

NExpArms=Mycombntns([CurrentNodes NewNodes],TDepth);

FlagMat = ones(size(NExpArms,1),3);
for n=1:length(CurrentNodes);
    nd = CurrentNodes(n);
        FlagMat(:,1) = FlagMat(:,1).*(NExpArms(:,1) ~= nd);
        FlagMat(:,2) = FlagMat(:,2).*(NExpArms(:,2) ~= nd);
        FlagMat(:,3) = FlagMat(:,3).*(NExpArms(:,3) ~= nd);
end

FlagVec=ones(size(NExpArms,1),1);

for n=1:size(NExpArms,1);
    if sum(FlagMat(n,:))==0;
        FlagVec(n)=0;
    end
end

NewArms = NExpArms(logical(FlagVec),:);

% Checking for illegal Combinations
ind = ones(1,size(NewArms,1));
for n=1:size(NewArms,1)
    x=NewArms(n,:);
    illegal=0;
    vecs = abs([x(1)-x(2);x(1)-x(3);x(2)-x(3)]);
    CheckVec = RealNodeCount*ones(1,TDepth);
    if sum(vecs == CheckVec') > 0
        ind(n) =0;
    end
end
% Removing Illegal Arms
NewArms = NewArms(logical(ind),:);


    