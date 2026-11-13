function [Ft utExp sigtExp] = GPReward(ktexplores,Ct,yt,A,B)
% Gaussian Process Predictions

% Kernel Matrix Inverse
Ctinv = geninv(Ct);
% Predicted Posterior Mean
utExp = (ktexplores*(Ctinv*yt'))';
% Predicted Posterior Variance
h1=Ctinv*ktexplores';
sigtExp = 1 -  sum((ktexplores'.*(h1)),1);
clear h1;
Ft = A*utExp + B*sqrt(sigtExp);