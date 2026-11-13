 function [FStats] = ErrorProp(s,bias,Inputs,Fout,InputValues)

% FUNCTION:
% This function creates all the neccessary fault statistics for the EPP-DP
% algorithm to run.

% INPUTS:
%
% 1. s: first element containes Node number, second element containes number 
%    of inputs, rest of elements are the actual inputs to this node 
%    e.g (6 2 5 19) where 6 is the node in question, which has two inputs 
%    which are 5 and 19. 
% 2. bias: the probability of this node being 'ON'
% 3. Inputs: The inputs of the network given they are inputs to the
%    function
% 4. Fout: The Vector of all possible outputs of the given function

% START
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% INITIALIZATIONS 
No_States = 2^s(2);
PropState1_0.SA0 = zeros(1,s(2));
PropState1_0.SA1 = zeros(1,s(2));
PropState0_1.SA0 = zeros(1,s(2));
PropState0_1.SA1 = zeros(1,s(2));
OnNodes1_0.SA0 = zeros(1,s(2),s(2));
OnNodes1_0.SA1 = zeros(1,s(2),s(2));
OnNodes0_1.SA0 = zeros(1,s(2),s(2));
OnNodes0_1.SA1 = zeros(1,s(2),s(2));
SumNodesOn_0to1.SA0 = zeros(s(2),s(2));
SumNodesOn_0to1.SA1 = zeros(s(2),s(2));
SumNodesOn_1to0.SA0 = zeros(s(2),s(2));
SumNodesOn_1to0.SA1 = zeros(s(2),s(2));
DefectiveOut.SA0 = 0;
DefectiveOut.SA1 = 0;
OriginalOut =0;
Change0_1.SA0 = zeros(1,s(2));
Change0_1.SA1 = zeros(1,s(2));
Change1_0.SA0 = zeros(1,s(2));
Change1_0.SA1 = zeros(1,s(2));
% INITIALIZATIONS END


% Creating a Matrix 'BinMat' which contains all the possible input states for
% the given function: 
% e.g for a 2-input function 
% 0 0
% 0 1
% 1 0 
% 1 1
for i = 1:No_States
 %  BinMat(i,:) =  dec2binvec(i-1,s(2));
    out = dec2bin(i-1,s(2));
    BinMat(i,:) = logical(str2num([fliplr(out);blanks(length(out))]')');
end
BinMat = fliplr(BinMat);
% if sum(Inputs) ~= 0
%     for i=1:length(Inputs)
%         % CHECK
%         BinMat(:,Inputs(i)) = InputValues(i)*ones(1,No_States);
%          BinMat(:,Inputs(i)) = ones(1,No_States);
%         % CHECK
%     end
% end


for i = 1:No_States
  x = BinMat(i,:) ;
  % [Fout] = FunCalc(x,s);
  OriginalOut(i) = Fout(i); 
  DefectiveOut.SA1(i,1:s(2)) = Fout(i); %Initializing Defective output to Original output
  DefectiveOut.SA0(i,1:s(2)) = Fout(i); %Initializing Defective output to Original output
  
  if Fout(i) == 0
       % Detecting Stuck-at-1 / Stuck-at-0 faults by given input vector which cause (0-->1 @ Output)
       for n = 1:s(2)
            if x(n) ~= 1 % Hence Stuck-at-1 fault may affect output
                x(n) = 1; % Simulate Stuck-at-1 fault
                % Replacement of binvec2dec
                %  DefectiveOut.SA1(i,n) = Fout(binvec2dec(fliplr(x))+1);
                vec = fliplr(x);
                vec = vec~=0;
                h = deblank(num2str(fliplr(vec)'))';
                out = bin2dec(h);
                % Calculating defective output
                DefectiveOut.SA1(i,n) = Fout(out+1);
                if DefectiveOut.SA1(i,n) == 1 % If SAF changes output from 0->1
                    % Updating Fault Statistics
                    SumNodesOn_0to1.SA1(n,:) = SumNodesOn_0to1.SA1(n,:) + x; 
                    Change0_1.SA1(n) = Change0_1.SA1(n) + 1;
                    PropState0_1.SA1(Change0_1.SA1(n),n) = i;
                    OnNodes0_1.SA1(Change0_1.SA1(n),:,n) = reshape(s(3:end),1,[]).*x  % Octave-compat: strread returns a column; force row to match x (MATLAB-broadcast-safe);
                end
                x(n) = 0; % resetting SAF 
                
            else %  Stuck-at-0 fault may affect output since x(n) = 1;
                x(n) = 0; % Simulate Stuck-at-0 fault
                % Replacement of binvec2dec
                % DefectiveOut.SA0(i,n) = Fout(binvec2dec(fliplr(x))+1);
                vec = fliplr(x);
                vec = vec~=0;
                h = deblank(num2str(fliplr(vec)'))';
                out = bin2dec(h);
                DefectiveOut.SA0(i,n) = Fout(out+1);
                if DefectiveOut.SA0(i,n) == 1 % If SAF changes output from 0->1
                    % Updating Fault Statistics
                    SumNodesOn_0to1.SA0(n,:) = SumNodesOn_0to1.SA0(n,:) + x; 
                    Change0_1.SA0(n) = Change0_1.SA0(n) + 1;
                    PropState0_1.SA0(Change0_1.SA0(n),n) = i;
                    OnNodes0_1.SA0(Change0_1.SA0(n),:,n) = reshape(s(3:end),1,[]).*x  % Octave-compat: strread returns a column; force row to match x (MATLAB-broadcast-safe);
                end
                x(n) = 1; % resetting SAF 

                

            end
       end
  else
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Detecting Stuck-at-1 / Stuck-at-0 faults by given input vector
 % which cause (1-->0 @ Output)
       for n = 1:s(2)
            if x(n) ~= 1
                x(n) = 1; % Simulating SA1 Fault
                % Replacement of binvec2dec 
                % DefectiveOut.SA1(i,n) = Fout(binvec2dec(fliplr(x))+1);
                vec = fliplr(x);
                vec = vec~=0;
                h = deblank(num2str(fliplr(vec)'))';
                out = bin2dec(h);
                DefectiveOut.SA1(i,n) = Fout(out+1);
                if DefectiveOut.SA1(i,n) == 0 % If SAF changes output from 1->0
                    % Updating Fault Statistics   
                    SumNodesOn_1to0.SA1(n,:) = SumNodesOn_1to0.SA1(n,:) + x;
                    Change1_0.SA1(n) = Change1_0.SA1(n) + 1;
                    PropState1_0.SA1(Change1_0.SA1(n),n) = i;
                    OnNodes1_0.SA1(Change1_0.SA1(n),:,n) = reshape(s(3:end),1,[]).*x  % Octave-compat: strread returns a column; force row to match x (MATLAB-broadcast-safe);
                end
                x(n) = 0;
            else % original input == 1 hence we stimulate SA0 fault and check for 1->0 transition at output 
                x(n) = 0; % Simulating SA0 Fault
                % Replacement of binvec2dec 
                % DefectiveOut.SA0(i,n)= Fout(binvec2dec(fliplr(x))+1);
                vec = fliplr(x);
                vec = vec~=0;
                h = deblank(num2str(fliplr(vec)'))';
                out = bin2dec(h);
                DefectiveOut.SA0(i,n) = Fout(out+1);
                if DefectiveOut.SA0(i,n) == 0 % If SAF changes output from 1->0
                    % updating Fault Statistics
                    SumNodesOn_1to0.SA0(n,:) = SumNodesOn_1to0.SA0(n,:) + x;
                    Change1_0.SA0(n) = Change1_0.SA0(n) + 1;
                    PropState1_0.SA0(Change1_0.SA0(n),n) = i;
                    OnNodes1_0.SA0(Change1_0.SA0(n),:,n) = reshape(s(3:end),1,[]).*x  % Octave-compat: strread returns a column; force row to match x (MATLAB-broadcast-safe);
                end
                x(n) = 1; % Resetting stuck-at-fault
            end
       end
   end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% THE GIVEN FUNCTION HAS BEEN CHECKED FOR ALL POSSIBLE FAULTS
% WE KNOW CALCULATE THE NECCESSARY FAULT STATISTICS FOR THAT FUNCTION

% 1. 
% Storing ORIGINAL FUNCTION OUTPUT 
FStats.OriginalOutput = OriginalOut;
if s(2) ==1
   % DefectiveOut = DefectiveOut';
    OriginalOut = OriginalOut';
end

% 2.
% Storing INPUTS
% Inputs
FStats.Inputs = s(3:end);

% 3. 
% Bias
FStats.Bias = bias;

for j = 1:s(2) % for each input to the function
    
    % 4.
    % NEW BIAS caused by SA-fault at input
    % New Bias of Function as a result of SAF on input node j
    FStats.SA1Input(j).NewBias = (sum(DefectiveOut.SA1(:,j)))/No_States;
    FStats.SA0Input(j).NewBias = (sum(DefectiveOut.SA0(:,j)))/No_States;
    
    
    % 5a.
    % Probability that SAF on input node j results in an output change from
    % 1 -> 0
    % TYPE 1: number of 1->0 changes / number of original 1's in input 
    if sum(OriginalOut)~=0 
        FStats.SA1Input(j).POutput1_0.val = Change1_0.SA1(j)/sum(OriginalOut);      %length(OriginalOut);  % CHANGING
        FStats.SA0Input(j).POutput1_0.val = Change1_0.SA0(j)/sum(OriginalOut);     % length(OriginalOut);  % CHANGING
    else
        FStats.SA1Input(j).POutput1_0.val =0;
        FStats.SA0Input(j).POutput1_0.val =0;
    end
    % TYPE 2: number of 1->0 changes / number of possible input states
    FStats.SA1Input(j).POutput1_0.Normval = Change1_0.SA1(j)/length(OriginalOut);
    FStats.SA0Input(j).POutput1_0.Normval = Change1_0.SA0(j)/length(OriginalOut);
    
    % 6
    % Rest of the Fault Statistics Explained in Documentation
    FStats.SA1Input(j).POutput1_0.PPropValueIs1 = SumNodesOn_1to0.SA1(j,:); %./SumNodesOn_1to0(j,j);
    FStats.SA1Input(j).POutput1_0.PropState =  PropState1_0.SA1(:,j);
    FStats.SA1Input(j).POutput1_0.OnNodes1_0 =  OnNodes1_0.SA1(:,:,j);
    
    FStats.SA0Input(j).POutput1_0.PPropValueIs1 = SumNodesOn_1to0.SA0(j,:); %./SumNodesOn_1to0(j,j);
    FStats.SA0Input(j).POutput1_0.PropState =  PropState1_0.SA0(:,j);
    FStats.SA0Input(j).POutput1_0.OnNodes1_0 =  OnNodes1_0.SA0(:,:,j);
    
    % 5b.
    % Probability that SAF on input node j results in an output change from
    % 0 -> 1
    % TYPE 1: number of 0->1 changes / number of original 0's in input 
    if (No_States-sum(OriginalOut))~=0
        FStats.SA1Input(j).POutput0_1.val = Change0_1.SA1(j)/ (No_States-sum(OriginalOut)); %length(OriginalOut); CHANGING
        FStats.SA0Input(j).POutput0_1.val = Change0_1.SA0(j)/ (No_States-sum(OriginalOut)); %length(OriginalOut); CHANGING
    else
        FStats.SA1Input(j).POutput0_1.val =0;
        FStats.SA0Input(j).POutput0_1.val =0;
    end
    % TYPE 2: number of 0->1 changes / number of possible input states
    FStats.SA1Input(j).POutput0_1.Normval = Change0_1.SA1(j)/ length(OriginalOut); %(No_States-sum(OriginalOut)); %CHANGING
    FStats.SA0Input(j).POutput0_1.Normval = Change0_1.SA0(j)/ length(OriginalOut); %(No_States-sum(OriginalOut)); %; CHANGING
    
    
    % 6b.
    % Rest of the Fault Statistics Explained in Documentation
    FStats.SA1Input(j).POutput0_1.PPropValueIs1 = SumNodesOn_0to1.SA1(j,:); %./SumNodesOn_0to1(j,j)
    FStats.SA1Input(j).POutput0_1.PropState =  PropState0_1.SA1(:,j);
    FStats.SA1Input(j).POutput0_1.OnNodes0_1 =  OnNodes0_1.SA1(:,:,j);
    
    
    FStats.SA0Input(j).POutput0_1.PPropValueIs1 = SumNodesOn_0to1.SA0(j,:); %./SumNodesOn_0to1(j,j);
    FStats.SA0Input(j).POutput0_1.PropState =  PropState0_1.SA0(:,j);
    FStats.SA0Input(j).POutput0_1.OnNodes0_1 =  OnNodes0_1.SA0(:,:,j);

end


