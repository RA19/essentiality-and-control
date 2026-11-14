function y = bnNextStateGP(x,F,varF,nv)
%BNNEXTSTATEGP One synchronous Boolean update, in truth-table input order.
% Based on bnNextState by Ilya Shmulevich (28 Aug 2002), modified by HL
% (12 May 2003). Vectorized here; zero-input nodes retain their current value.
persistent cached_parents cached_nv parents weights
if isempty(cached_parents) || ~isequal(cached_parents,varF) || ~isequal(cached_nv,nv)
    cached_parents = varF; cached_nv = nv;
    parents = varF; parents(parents==0) = 1;
    exponents = repmat(nv(:)',size(varF,1),1) - repmat((1:size(varF,1))',1,length(nv));
    weights = 2.^exponents; weights(exponents<0) = 0;
end
indices = sum(double(x(parents)).*weights,1)+1;
y = F(sub2ind(size(F),indices,1:length(x)));
y(nv==0) = x(nv==0);
end
