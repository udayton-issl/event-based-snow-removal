function [tp, fp, tn, fn] = getTpFpTnFn(testData, groundTruth)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FUNCTION: getTpFpTnFn -- Get number of TPs, FPs, TNs and FNs            %
% ----------------------------------------------------------------------- %
% Parameters:                                                             %
%   testData : matrix[logical], required                                  %
%       Prediction data.                                                  %
%   groundTruth : matrix[logical], required                               %
%       Ground truth data.                                                %
% Returns:                                                                %
%   tp : double                                                           %
%       Number of true positive predictions.                              %
%   fp : double                                                           %
%       Number of false positive predictions.                             %
%   tn : double                                                           %
%       Number of true negative predictions.                              %
%   fn : double                                                           %
%       Number of false negative preditions.                              %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EXAMPLES                                                                %
% ----------------------------------------------------------------------- %
% getTpFpTnFn(testData, groundTruth)                                      %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
arguments
    testData (:, 1) logical
    groundTruth (:, 1) logical
end
    tp = length(find(groundTruth & testData));
    fp = length(find((~groundTruth) & testData));
    tn = length(find((~groundTruth) & (~testData)));
    fn = length(find(groundTruth & (~testData)));
end