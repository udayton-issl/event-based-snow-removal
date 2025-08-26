function [IE, TE, IEm] = IE_filter(ev, tWin, options)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FUNCTION: IE_filter -- Perform Inceptive Event filtering                %
% ----------------------------------------------------------------------- %
% Parameters:                                                             %
%   events : struct(fields=x, y, ts, p), positional required              %
%       Events to filter.                                                 %
%   tWin : double, positional optional                                    %
%       Time windowing threshold.                                         %
%   TE_depth : double, named optional                                     %
%       Max amount of Trailing Events to record per Inceptive Event.      %
%   camRes : matrix[double], named optional                               %
%       Camera resolution, given as [y,x]. Default is [720, 1280].        %
% Returns:                                                                %
%   IE : matrix[logical]                                                  %
%       Logical matrix of Inceptive Event indices.                        %
%   TE : matrix[double]                                                   %
%       N events by TE_depth matrix of IE to TE pointers.                 %
%   IEm : matrix[double]                                                  %
%       N events by 1 matrix of Inceptive Event magnitudes.               %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EXAMPLES                                                                %
% ----------------------------------------------------------------------- %
% IE_filter(events)                                                       %
% IE_filter(events, TE_depth=5)                                           %
% IE_filter(events, tWindow)                                              %
% IE_filter(events, tWindow, TE_depth=5)                                  %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
arguments
    ev (1, 1) struct {mustHaveFieldsXYTsP(ev)}
    tWin (1, 1) double = 10000
    options.TE_depth (1, 1) double = 1
    options.camRes (1, 2) double = [720, 1280]
end
    TE_depth = options.TE_depth;
    camRes = options.camRes;
    ptsX = ev.x + 1;
    ptsY = ev.y + 1;
    ptsTs = ev.ts;
    ptsP = ev.p;

    % FIFO
    IE_idx = zeros(camRes(2), camRes(1)+2);     % FIFO -- Current Index
    prevTs = zeros(camRes(2), camRes(1)+2);     % FIFO -- Prev Timestamp
    prevIdx = zeros(camRes(2), camRes(1)+2);    % FIFO -- Prev Index

    IE = false(length(ptsX), 1);
    TE = zeros(length(ptsX), TE_depth);
    IEm = zeros(length(ptsX), 1);
    TE_idx = ones(length(ptsX), 1);

    for k=1:length(ptsX)
        if (ptsP(k)~=prevIdx(ptsX(k),ptsY(k))) || (ptsTs(k)-prevTs(ptsX(k),ptsY(k))>tWin)
            IE(k) = true;
            IEm(k) = 1;
            IE_idx(ptsX(k), ptsY(k)) = k;
        else
            if TE_idx(IE_idx(ptsX(k), ptsY(k))) > TE_depth
                continue;
            end
            TE(IE_idx(ptsX(k),ptsY(k)), TE_idx(IE_idx(ptsX(k),ptsY(k)))) = k;
            TE_idx(IE_idx(ptsX(k),ptsY(k))) = TE_idx(IE_idx(ptsX(k),ptsY(k)))+1;
            IEm(IE_idx(ptsX(k),ptsY(k))) = IEm(IE_idx(ptsX(k),ptsY(k)))+1;
        end
        prevTs(ptsX(k),ptsY(k)) = ptsTs(k);
        prevIdx(ptsX(k),ptsY(k)) = ptsP(k);
    end
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