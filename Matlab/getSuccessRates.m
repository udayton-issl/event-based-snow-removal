function rates = getSuccessRates(data, connectTo1_1)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FUNCTION: getSuccessRates -- Calculate TP, FP, TN, and FN percentages   %
% ----------------------------------------------------------------------- %
% Parameters:                                                             %
%   data : struct(fields=tp, fp, tn, fn, gtSnow, gtNoSnow), required      %
%       Prediction/ground truth data.                                     %
%   connectTo1_1 : double, positional optional                            %
%       Append 1.0 to TP and FP rates for ROC curve plotting? Causes 0.0  %
%       to be appended to TN and FN to maintain equal length/ratio.       %
% Returns:                                                                %
%   rates : struct(fields=TP, FP, TN, FN)                                 %
%       TP, FP, TN, and FN rates.                                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EXAMPLES                                                                %
% ----------------------------------------------------------------------- %
% getSuccessRates(data)                                                   %
% getSuccessRates(data, true)                                             %
% getSuccessRates(data, false)                                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
arguments
    data (1, 1) struct {validateFields(data)}
    connectTo1_1 (1, 1) logical = false
end
    TP = data.tp./data.gtSnow;
    FP = data.fp./data.gtNoSnow;
    TN = data.tn./data.gtNoSnow;
    FN = data.fn./data.gtSnow;

    if connectTo1_1
        TP = [TP, 1];
        FP = [FP, 1];
        TN = [FP, 0];
        FN = [FP, 0];
    end

    rates = struct("TP", TP, "FP", FP, "TN", TN, "FN", FN);
end

function validateFields(data)
    % Test for data.tp
    if ~isfield(data, 'tp')
        error('Field "tp" missing from predictionData struct.')
    end
    % Test for data.fp
    if ~isfield(data, 'fp')
        error('Field "fp" missing from predictionData struct.')
    end
    % Test for data.tn
    if ~isfield(data, 'tn')
        error('Field "tn" missing from predictionData struct.')
    end
    % Test for data.fn
    if ~isfield(data, 'fn')
        error('Field "fn" missing from predictionData struct.')
    end
    % Test for data.gtSnow
    if ~isfield(data, 'gtSnow')
        error('Field "gtSnow" missing from predictionData struct.')
    end
    % Test for data.gtNoSnow
    if ~isfield(data, 'gtNoSnow')
        error('Field "gtNoSnow" missing from predictionData struct.')
    end
end