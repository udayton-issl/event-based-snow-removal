function [precision, recall, accuracy] = getSuccessMetrics(data)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FUNCTION: getSuccessMetrics -- Get precision, recall, and accuracy      %
% ----------------------------------------------------------------------- %
% Parameters:                                                             %
%   data : struct(fields=tp, fp, tn, fn), required                        %
%       Prediction data.                                                  %
% Returns:                                                                %
%   precision : double                                                    %
%       Precision value.                                                  %
%   recall : double                                                       %
%       Recall value.                                                     %
%   accuracy : double                                                     %
%       Accuracy value.                                                   %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EXAMPLES                                                                %
% ----------------------------------------------------------------------- %
% getSuccessMetrics(predictionData)                                       %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
arguments
    data (1, 1) struct {validateFields(data)}
end
    precision = data.tp./(data.tp+data.fp);
    recall = data.tp./(data.tp+data.fn);
    total = data.tp+data.fp+data.tn+data.fn;
    accuracy = (data.tp+data.tn)./total;
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
end