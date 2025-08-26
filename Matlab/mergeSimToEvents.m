function [merged, groundTruth, idx] = mergeSimToEvents(simData, evData, simIdx, evTsLen)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FUNCTION: mergeSimToEvents -- Merge sim data with event camera data.    %
% ----------------------------------------------------------------------- %
% Parameters:                                                             %
%   simData : struct(fields=x, y, ts, p), required                        %
%       Simulation data.                                                  %
%   evData : struct(fields=x, y, ts, p), required                         %
%       Event camera data.                                                %
%   simIdx : double, required                                             %
%       Pointer to current index in the sim data.                         %
%   evTsLen : double, required                                            %
%       Event data frame window.                                          %
% Returns:                                                                %
%   merged : struct(fields=x, y, ts, p)                                   %
%       Structure containing merged sim and event camera data.            %
%   groundTruth : matrix[logical]                                         %
%       Ground truth array for the merged data.                           %
%   idx : double                                                          %
%       New simIdx value.                                                 %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EXAMPLES                                                                %
% ----------------------------------------------------------------------- %
% mergeSimToEvents(simData, evData, simIdx, evTsLen)                      %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
arguments
    simData (1, 1) struct {mustHaveFieldsXYTsP(simData)}
    evData (1, 1) struct {mustHaveFieldsXYTsP(evData)}
    simIdx (1, 1) double
    evTsLen (1, 1) double
end
    currSimTs = simData.ts(simIdx);
    maxSimTs = simData.ts(end);
    if (currSimTs + evTsLen) > maxSimTs
        tsOvershoot = (currSimTs + evTsLen) - maxSimTs;
        overshootIdx = simData.ts <= tsOvershoot;
        simSel.x = zeros(length(find(overshootIdx))+length(simData.x)+1-simIdx, 1);
        simSel.y = zeros(length(find(overshootIdx))+length(simData.y)+1-simIdx, 1);
        simSel.ts = zeros(length(find(overshootIdx))+length(simData.ts)+1-simIdx, 1);
        simSel.p = zeros(length(find(overshootIdx))+length(simData.p)+1-simIdx, 1);

        tmpIdx = length(simData.ts)+1-simIdx;
        simSel.x(1:tmpIdx) = simData.x(simIdx:end);
        simSel.y(1:tmpIdx) = simData.y(simIdx:end);
        simSel.ts(1:tmpIdx) = simData.ts(simIdx:end);
        simSel.p(1:tmpIdx) = simData.p(simIdx:end);
        simSel.x(tmpIdx+1:end) = sim_data.x(overshootIdx);
        simSel.y(tmpIdx+1:end) = sim_data.y(overshootIdx);
        simSel.ts(tmpIdx+1:end) = sim_data.ts(overshootIdx);
        simSel.p(tmpIdx+1:end) = sim_data.p(overshootIdx);

        idx = find(overshootIdx, 1, 'last') + 1;
    else
        data_idx = (simData.ts > currSimTs) & (simData.ts < currSimTs + evTsLen);
        simSel.x = simData.x(data_idx);
        simSel.y = simData.y(data_idx);
        simSel.ts = simData.ts(data_idx);
        simSel.p = simData.p(data_idx);

        idx = find(data_idx, 1, 'last') + 1;
    end

    if evData.ts(1) > simData.ts(end)
        simSel.ts = simSel.ts + (evData.ts(1) - simData.ts(end));
    end
    merged.x = zeros(length(simSel.x) + length(evData.x), 1);
    merged.y = zeros(length(simSel.y) + length(evData.y), 1);
    merged.ts = zeros(length(simSel.ts) + length(evData.ts), 1);
    merged.p = zeros(length(simSel.p) + length(evData.p), 1);

    merged.x(1:length(evData.x)) = evData.x;
    merged.y(1:length(evData.y)) = evData.y;
    merged.ts(1:length(evData.ts)) = evData.ts;
    merged.p(1:length(evData.p)) = evData.p;
    merged.x(length(evData.x)+1:end) = simSel.x;
    merged.y(length(evData.y)+1:end) = simSel.y;
    merged.ts(length(evData.ts)+1:end) = simSel.ts;
    merged.p(length(evData.p)+1:end) = simSel.p;

    groundTruth = ones(length(evData.x)+length(simSel.x), 1);
    groundTruth(1:length(evData.x)) = zeros(length(evData.x), 1);

    [~, sort_idx] = sort(merged.ts);
    merged.x = merged.x(sort_idx);
    merged.y = merged.y(sort_idx);
    merged.ts = merged.ts(sort_idx);
    merged.p = merged.p(sort_idx);
    groundTruth = groundTruth(sort_idx);
end

function mustHaveFieldsXYTsP(ev)
    % Test for ev.x
    if ~isfield(ev, 'x')
        error('Field "x" missing from event struct.')
    end
    % Test for ev.y
    if ~isfield(ev, 'y')
        error('Field "y" missing from event struct.')
    end
    % Test for ev.ts
    if ~isfield(ev, 'ts')
        error('Field "ts" missing from event struct.')
    end
    % Test for ev.p
    if ~isfield(ev, 'p')
        error('Field "p" missing from event struct.')
    end
end