function  [kt stop] = NewArmKernelCalc(ExpArms,TrainMoves,Knorm,TDepth,c,KxxTrain,KxxExp)
% Summation Kernel
stop=0;
ecnt = size(ExpArms,1);
tcnt  = size(TrainMoves,1);
kt=zeros(ecnt,tcnt);


for i=1:ecnt 
    
    for j=1:tcnt
        x=ExpArms(i,:);
        z=TrainMoves(j,:);
        Summy=0;
        for nx=1:TDepth
            for nz=1:TDepth
                Summy = Summy + Knorm(x(nx),z(nz))^c;
            end
        end
        kt(i,j) = Summy/sqrt(KxxExp(i)*KxxTrain(j));
        if kt(i,j) >1
            stop=1;
        end
    end
    
end

