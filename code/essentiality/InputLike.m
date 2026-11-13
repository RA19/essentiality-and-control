function [FStats] = InputLike(FStats,Inputs)

% FUNCTION:
% This function calculates the likelihood of each input state occurring
% w.r.t the bias of the inputs. So rather than having an equal likelihood
% of each input state occurring, we have different likelihoods of each input
% state occurring.

for Fcount = 1:length(FStats)
    if sum(Fcount==Inputs)==0
        BinMat=[];
        s = FStats(Fcount).Inputs;
        No_States = 2^length(s);
        for i = 1:No_States
            %BinMat(i,:) =  dec2binvec(i-1,length(s));
            out = dec2bin(i-1,length(s));
            BinMat(i,:) = logical(str2num([fliplr(out);blanks(length(out))]')');
        end
        BinMat = fliplr(BinMat);
        for i = 1:No_States
            x = BinMat(i,:);
            InputProbs = x.*([FStats(s(1:end)).Bias]) + (~x).*(1-[FStats(s(1:end)).Bias]);
            FStats(Fcount).StateProb(i) = prod(InputProbs);
        end
     end
end
        

