function [ProbMatrix, SeqMatrix, MLSeq, FaultStats] = DPALGONEW(varargin)
%DPALGONEW Compatibility entry point for the GSK-derived EPP-DP engine.
% See EPPDPALGOR for the recurrence, fault encoding and predecessor traceback.
[ProbMatrix, SeqMatrix, MLSeq, FaultStats] = EPPDPALGOR(varargin{:});
end
