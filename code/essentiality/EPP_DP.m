function result = EPP_DP(varargin)
%EPP_DP Convenience entry point for both-direction essentiality examples.
root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(root,'examples'));
result = run_essentiality(varargin{:});
end
