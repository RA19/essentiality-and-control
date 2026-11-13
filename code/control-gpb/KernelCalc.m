function  [ktexplores KxxTrain stop] = KernelCalc(ExpArms,TrainMoves,Knorm,TDepth,c,Ct,KxxTrain,Oldktexplores,KxxExp)
% Summation Kernel

stop=0;
ecnt = size(ExpArms,1);
tcnt  = size(TrainMoves,1);
kt=zeros(ecnt,1);
ktexplores=zeros(ecnt,tcnt);

% Self Kernel of Latest arm added K(xt,xt)
z=TrainMoves(end,:);
Summy=0;
for nx=1:TDepth
    for nz=1:TDepth
        Summy = Summy + Knorm(z(nx),z(nz))^c;
    end
end
KxxTrain = [KxxTrain;Summy];


% Kernel of Exploratory Arms with Latest arm added to training set
for i=1:ecnt 
    x=ExpArms(i,:);
    z=TrainMoves(end,:);
    Summy=0;
    for nx=1:TDepth
        for nz=1:TDepth
            Summy = Summy + Knorm(x(nx),z(nz))^c;
        end
    end
    % Normalization
    kt(i) = Summy/sqrt(KxxExp(i)*KxxTrain(end));
    if kt(i) >1
        stop=1;
    end
end

ktexplores = [Oldktexplores kt];