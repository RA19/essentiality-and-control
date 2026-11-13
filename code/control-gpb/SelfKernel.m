function [KxxExp] = SelfKernel(ExpArms,Knorm,c,TDepth)
% Self Kernel between New Exploratory Arms
KxxExp=zeros(size(ExpArms,1),1);
for i=1:size(ExpArms,1) 
    x=ExpArms(i,:);
    Summy=0;
    for nx=1:TDepth
        for nz=1:TDepth
            Summy = Summy + Knorm(x(nx),x(nz))^c;
        end
    end
    KxxExp(i)=Summy;
end
