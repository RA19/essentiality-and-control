function [ProbMatrix SeqMatrix MLSeq FaultStats] = DPALGONEW(StartNode,SA_Value,FStats,P0_1MAT,P1_0MAT,NewBiasMAT,NodeCount,TimeSteps,TRemove)
[FaultStats] = FaultInit(NodeCount);
% Changing FStats of SA Node & Changes on Input Probabilities this may
% cause
% [FStats] = SAStats(FStats,SA_Value,StartNode);

    
Nodes = NodeCount*2;
% Transition Probabilities
% (i,j) represents the probability that the respective fault is propagated
% from node j to node i

TransMat0_1  = [P0_1MAT(:,:,1) P0_1MAT(:,:,2)]; 
TransMat1_0  = [P1_0MAT(:,:,1) P1_0MAT(:,:,2)]; 

IntTransProb = [P0_1MAT(:,StartNode,SA_Value);P1_0MAT(:,StartNode,SA_Value)];
ProbMatrix(:,1) = IntTransProb; 
%TESTING
if TRemove~=1   
if SA_Value==1
    ProbMatrix(StartNode)=1;
    ProbMatrix(StartNode+NodeCount)=0;
else
    ProbMatrix(StartNode)=0;
    ProbMatrix(StartNode+NodeCount)=1;
end
end
%TESTING

SeqMatrix(:,1) = ones(Nodes,1)*StartNode;
Involved=0;


for t = 2:TimeSteps
    for TargetNode = 1:Nodes;
        
        if TargetNode <= NodeCount % Then Consider 0 -> 1 Output Transitions
            % List all Transition Probabilities from all Nodes in TimeStep n
            % to TargetNode in TimeStep n+1
            FaultProbVec = TransMat0_1(TargetNode,:); 
            DirectEffect = FaultProbVec;
            ActualEffect=zeros(1,Nodes);
            
            if sum(DirectEffect) ~= 0 
            
            for InputNode=1:Nodes; % Running through each Input Node to Target Node
                
                if InputNode > NodeCount
                    TrueInputNode = mod(InputNode,NodeCount+1) + 1;
                else
                    TrueInputNode = InputNode;
                end

                if sum(FStats(TargetNode).Inputs==TrueInputNode) > 0 % If InputNode is actaully an input to TargetNode
                    % Find Position of InputNode in TargetNode inputs
                    SNodePos= find(FStats(TargetNode).Inputs==TrueInputNode);
                        if InputNode<=NodeCount %Hence InputNode SA1
                            if FStats(TargetNode).SA1Input(SNodePos).POutput0_1.val > 0 %Hence error prop can happen
                                % Finding non zero states (formatting issue)
                                v=FStats(TargetNode).SA1Input(SNodePos).POutput0_1.PropState > 0;
                                % Finding actual states
                                PropStates = FStats(TargetNode).SA1Input(SNodePos).POutput0_1.OnNodes0_1(v,:) >0;
                                                              
                                InState=0;
                                if length(FStats(TargetNode).Inputs) > 1
                                   
                                    for s=1:size(PropStates,1)
                                        PropStates(s,SNodePos)=0; %Since in OnNodes it is SA0;
                                        % InState(s) = binvec2dec(fliplr(PropStates(s,:))) +1 ;
                                        
                                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                        vec = fliplr(PropStates(s,:));
                                        vec = vec~=0;
                                        h = deblank(num2str(fliplr(vec)'))';
                                        out = bin2dec(h);
                                        InState(s) = out+1;
                                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                        
                                        
                                    end
                                 else
                                    InState= FStats(TargetNode).SA1Input(SNodePos).POutput0_1.PropState;
                                 end
                                 ActualEffect(InputNode) = sum(FStats(TargetNode).StateProb(InState));
                                
                                
                            else
%                                   if TrueInputNode ~= StartNode
                                     ActualEffect(InputNode)=0;
%                                  else
%                                     %considering 0->1 Transitions
%                                     if SA_Value == 1 % Then SA1
%                                         ActualEffect(InputNode) = 1 ;
%                                     elseif SA_Value == 2
%                                             ActualEffect(InputNode) = 0; % Since Source Node is SA0 therefore can never be SA1
%                                     end
%                                     
%                                  end
                            end
                         elseif InputNode>NodeCount %Hence InputNode SA0 
                            
                                 
                             if FStats(TargetNode).SA0Input(SNodePos).POutput0_1.val > 0
                                % Finding non zero states (formatting issue)
                                v=FStats(TargetNode).SA0Input(SNodePos).POutput0_1.PropState > 0;
                                % Finding actual states
                                PropStates = FStats(TargetNode).SA0Input(SNodePos).POutput0_1.OnNodes0_1(v,:) >0;
                                   InState=0;
                                if length(FStats(TargetNode).Inputs) > 1
                                  
                                    for s=1:size(PropStates,1)
                                        PropStates(s,SNodePos)=1; %Since in OnNodes it is SA0;
                                        %InState(s) = binvec2dec(fliplr(PropStates(s,:))) +1 ;
                                        
                                         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                        vec = fliplr(PropStates(s,:));
                                        vec = vec~=0;
                                        h = deblank(num2str(fliplr(vec)'))';
                                        out = bin2dec(h);
                                        InState(s) = out+1;
                                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                        
                                    end
                                 else
                                    InState= FStats(TargetNode).SA0Input(SNodePos).POutput0_1.PropState;
                                 end
                                 ActualEffect(InputNode) = sum(FStats(TargetNode).StateProb(InState));
                            else
%                                   if TrueInputNode ~= StartNode
                                     ActualEffect(InputNode)=0;
%                                  else
%                                     %considering 0->1 Transitions
%                                     if SA_Value == 1 % Then SA1
%                                         ActualEffect(InputNode) = 1 ;
%                                     elseif SA_Value == 2
%                                             ActualEffect(InputNode) = 0; % Since Source Node is SA0 therefore can never be SA1
%                                     end
%                                     
%                                  end
                             end
                         end
                else
                    ActualEffect(InputNode)=0;
                end
            end
                    
            % Finding SourceNode which has highest fault propgation probability to
            % TargetNode
            if sum(ActualEffect) == 0 %Hence Fault Transition Impossible from ALL source nodes
                ProbMatrix(TargetNode,t) = 0;
                SeqMatrix(TargetNode,t) = 0;
            else
                [Val Ind] = max(ActualEffect.*ProbMatrix(:,t-1)');
                ProbMatrix(TargetNode,t) = Val;
                SeqMatrix(TargetNode,t) = Ind;
            end

            else
                ProbMatrix(TargetNode,t) = 0;
                SeqMatrix(TargetNode,t) = 0;
            end 
            %TESTING
            if t <= TRemove
                if SA_Value==1
                    ProbMatrix(StartNode,t)=1;
                    ProbMatrix(StartNode+NodeCount,t)=0;
                else
                    ProbMatrix(StartNode,t)=0;
                    ProbMatrix(StartNode+NodeCount,t)=1;
                end
            end
                
            %TESTING
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5

            
        elseif TargetNode > NodeCount % Then Consider 1 -> 0 Output Transitions
        
            FaultProbVec = TransMat1_0( mod(TargetNode,NodeCount+1) + 1,:);
            DirectEffect = FaultProbVec;
            DPTargetNode= TargetNode;
            TargetNode = mod(TargetNode,NodeCount+1) + 1;
            
            ActualEffect=zeros(1,Nodes);
            if sum(DirectEffect) ~= 0 
                
                for InputNode=1:Nodes; % Running through each Input Node to Target Node
                     if InputNode>NodeCount
                        TrueInputNode = mod(InputNode,NodeCount+1) + 1;
                     else
                        TrueInputNode = InputNode;
                    end
                    
                    if sum(FStats(TargetNode).Inputs==TrueInputNode) > 0 % If InputNode is actaully an input to TargetNode
                    
                        % Find Position of InputNode in TargetNode inputs
                        SNodePos= find(FStats(TargetNode).Inputs==TrueInputNode);
                        
                        if InputNode<=NodeCount %Hence InputNode SA1
                             if FStats(TargetNode).SA1Input(SNodePos).POutput1_0.val > 0 
                                % Finding non zero states (formatting issue)
                                v=FStats(TargetNode).SA1Input(SNodePos).POutput1_0.PropState > 0;
                                % Finding actual states
                                PropStates = FStats(TargetNode).SA1Input(SNodePos).POutput1_0.OnNodes1_0(v,:) >0;
                                 InState=0;
                                if length(FStats(TargetNode).Inputs) > 1
                                   
                                    for s=1:size(PropStates,1)
                                        PropStates(s,SNodePos)=0; %Since in OnNodes it is SA1;
                                      %  InState(s) = binvec2dec(fliplr(PropStates(s,:))) +1 ;
                                        
                                         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                        vec = fliplr(PropStates(s,:));
                                        vec = vec~=0;
                                        h = deblank(num2str(fliplr(vec)'))';
                                        out = bin2dec(h);
                                        InState(s) = out+1;
                                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                    end
                                 else
                                    InState= FStats(TargetNode).SA1Input(SNodePos).POutput1_0.PropState;
                                 end
                                ActualEffect(InputNode) = sum(FStats(TargetNode).StateProb(InState));
                             else
%                                  if TrueInputNode ~= StartNode
                                     ActualEffect(InputNode)=0;
%                                  else
%                                      %  considering 1->0 Transitions
%                                         if SA_Value == 1 % Then SA1
%                                             ActualEffect(InputNode) = 0 ;% Since Source Node is SA1 therefore can never be SA0
%                                         elseif SA_Value == 2
%                                             ActualEffect(InputNode) = 1;
%                                         end
%                                  end
                                
                             end
                        elseif InputNode>NodeCount %Hence InputNode SA0   
                            
                            if FStats(TargetNode).SA0Input(SNodePos).POutput1_0.val > 0 
                                % Finding non zero states (formatting issue)
                                v=FStats(TargetNode).SA0Input(SNodePos).POutput1_0.PropState > 0;
                                % Finding actual states
                                PropStates = FStats(TargetNode).SA0Input(SNodePos).POutput1_0.OnNodes1_0(v,:) >0;
                               InState=0;
                               if length(FStats(TargetNode).Inputs) > 1
                                    
                                    for s=1:size(PropStates,1)
                                        PropStates(s,SNodePos)=1; %Since in OnNodes it is SA0;
                                        %InState(s) = binvec2dec(fliplr(PropStates(s,:))) +1 ;
                                         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                        vec = fliplr(PropStates(s,:));
                                        vec = vec~=0;
                                        h = deblank(num2str(fliplr(vec)'))';
                                        out = bin2dec(h);
                                        InState(s) = out+1;
                                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                    end
                                else
                                    InState= FStats(TargetNode).SA0Input(SNodePos).POutput1_0.PropState;
                                end
                                ActualEffect(InputNode) = sum(FStats(TargetNode).StateProb(InState));
                            else
%                                  if TrueInputNode ~= StartNode
                                     ActualEffect(InputNode)=0;
%                                  else
%                                       %  considering 1->0 Transitions
%                                         if SA_Value == 1 % Then SA1
%                                             ActualEffect(InputNode) = 0 ;% Since Source Node is SA1 therefore can never be SA0
%                                         elseif SA_Value == 2
%                                             ActualEffect(InputNode) = 1;
%                                         end
%                                  end
                            end
                       end

                    else
                        ActualEffect(InputNode)=0;
                    end
                end
            
             
           % Finding SourceNode which has highest fault propgation probability to
            % TargetNode
            if sum(ActualEffect) == 0 %Hence Fault Transition Impossible from ALL source nodes
                ProbMatrix(DPTargetNode,t) = 0;
                SeqMatrix(TargetNode,t) = 0;
            else
                [Val Ind] = max(ActualEffect.*ProbMatrix(:,t-1)');
                ProbMatrix(DPTargetNode,t) = Val;
                SeqMatrix(DPTargetNode,t) = Ind;
            end
            
            else
                ProbMatrix(DPTargetNode,t) = 0;
                SeqMatrix(DPTargetNode,t) = 0;
            end
            %TESTING
            if  t <= TRemove
                if SA_Value==1
                    ProbMatrix(StartNode,t)=1;
                    ProbMatrix(StartNode+NodeCount,t)=0;
                else
                    ProbMatrix(StartNode,t)=0;
                    ProbMatrix(StartNode+NodeCount,t)=1;
                end
            end
            %TESTING
            
        end
        
    end
         
    
        
    end

            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
% Back-Tracking for Most Likely Sequence
 MLSeq = zeros(1,TimeSteps+1);
 if sum(ProbMatrix(:,end)) ~=0
     [Val MLSeq(end)] = max(ProbMatrix(:,end));
 else
     Val = 0;
     MLSeq(end)=0;
 end
 
 for t = TimeSteps:-1:2
     if sum(ProbMatrix(:,t)) ~= 0
       % [Val Ind] = max(ProbMatrix(:,t));
       % MLSeq(t) = SeqMatrix(Ind,t);
         if MLSeq(t+1) ~=0
            MLSeq(t) = SeqMatrix(MLSeq(t+1),t);
         else
            [ val MLSeq(t)] = max(ProbMatrix(:,t));
         end
         
     else
         MLSeq(t) =0;
     end
     
 end

 if sum(ProbMatrix(:,1))~=0
     [val MLSeq(2)] = max(ProbMatrix(:,1));
 else
     MLSeq(2)=0;
 end
 MLSeq(1) = StartNode;

 
% Normalization of Fault Statistics
[NormOut]= FaultNorm(FaultStats,StartNode,TimeSteps,SA_Value);
FaultStats(StartNode) = NormOut;
FaultStats(StartNode).Involved = Involved;
end