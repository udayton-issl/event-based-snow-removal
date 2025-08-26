function tWidths = EBSnoR_timewidths(ev, sWin, IE, TE, options)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FUNCTION: EBSnoR_timewidths -- perform EBSnoR timewidth calculation     %
% ----------------------------------------------------------------------- %
% Parameters:                                                             %
%   ev : struct(fields=x, y, ts, p), required                             %
%       Events to filter                                                  %
%   sWin : double, required                                               %
%       Spatial windowing threshold                                       %
%   IE : matrix[logical], positional optional                             %
%       Logical matrix of IE indices.                                     %
%   TE : matrix[double], positional optional                              %
%       N events by M matrix of IE to TE pointers. Makes IE required.     %
%   camRes : matrix[double], named optional                               %
%       Camera resolution, given as [y,x]. Default is [720, 1280].        %
%   useAdaptiveWin : logical, named optional                              %
%       Use adaptive windowing technique? Default is false.               %
% Returns:                                                                %
%   tWidths : matrix[double]                                              %
%       The timewidth values for the given events.                        %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EXAMPLES                                                                %
% ----------------------------------------------------------------------- %
% EBSnoR_timewidths(ev,sWin);                                             %
% EBSnoR_timewidths(ev,sWin,IE);                                          %
% EBSnoR_timewidths(ev,sWin,IE,TE);                                       %
% EBSnoR_timewidths(ev,sWin,camRes=[480,640]);                            %
% EBSnoR_timewidths(ev,sWin,useAdaptiveWin=true);                         %
% EBSnoR_timewidths(ev,sWin,camRes=[480,640],useAdaptiveWin=true)         %
% EBSnoR_timewidths(ev,sWin,IE,useAdaptiveWin=true,camRes=[480,640])      %
% EBSnoR_timewidths(ev,sWin,IE,TE,useAdaptiveWin=true,camRes=[480,640])   %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
arguments
    ev (1, 1) struct {mustHaveFieldsXYTsP(ev)}
    sWin (1, 1) double
    IE (:, 1) logical = []
    TE (:, :) double = []
    options.camRes (1, 2) double = [720, 1280]
    options.useAdaptiveWin (1, 1) logical = false
end
    res = options.camRes;                       % Camera Resolution
    adaptiveWin = options.useAdaptiveWin;       % Adaptive Window Enable
    evalMethod = isempty(IE) + isempty(TE);     % Evaluation Method
    ptsX = ev.x + 1 + sWin;                     % Event X-positions
    ptsY = ev.y + 1 + sWin;                     % Event Y-positions
    ptsTs = ev.ts;                              % Event Timestamps
    ptsP = ev.p;                                % Event Polarity
    win = -sWin:sWin;                           % Spatial Window

    % Positive Event FIFOs
    pos_ts = ones(res(2)+2*sWin, res(1)+2*sWin)*-inf;   % FIFO -- Time
    pos_idx = zeros(res(2)+2*sWin, res(1)+2*sWin);      % FIFO -- Index

    tWidths = ones(length(ptsX), 1)*-1;                 % Event Timewidths

    switch evalMethod
        case 0                      % IE and TE given
            for k = 1:length(ptsX)
                if IE(k) && ptsP(k) < 0
                    if pos_ts(ptsX(k), ptsY(k)) > 0 && adaptiveWin
                        T = ptsTs(k)-pos_ts(ptsX(k),ptsY(k));
                        K = pos_idx(ptsX(k),ptsY(k));
                    else
                        T = ptsTs(k)-pos_ts(ptsX(k)+win,ptsY(k)+win);
                        K = pos_idx(ptsX(k)+win,ptsY(k)+win);
                    end
                    tWidths(k) = min(T(:));
                    tWidths(TE(k, TE(k, :) > 0)) = min(T(:));

                    for x = 1:length(K(:))
                        if K(x) > 0
                            if (tWidths(K(x))==-1 || tWidths(K(x))==inf)
                                tWidths(K(x)) = T(x);
                            else
                                tWidths(K(x)) = min(tWidths(K(x)), T(x));
                            end

                            TE_K = TE(K(x), :);
                            for y = 1:length(TE_K(:))
                                if TE_K(y) > 0
                                    if (tWidths(TE_K(y))==-1 || tWidths(TE_K(y))==inf)
                                        tWidths(TE_K(y)) = T(x);
                                    else
                                        tWidths(TE_K(y)) = min(tWidths(TE_K(y)), T(x));
                                    end
                                end
                            end
                        end
                    end
                elseif IE(k)
                    pos_idx(ptsX(k),ptsY(k)) = k;
                    pos_ts(ptsX(k),ptsY(k)) = ptsTs(k);

                    if tWidths(k) == -1
                        tWidths(k) = inf;
                        tWidths(TE(k, TE(k, :) > 0)) = inf;
                    end
                end
            end
        case 1                      % Only IE given
            for k = 1:length(ptsX)
                if IE(k) && ptsP(k) < 0
                    if pos_ts(ptsX(k), ptsY(k)) > 0 && adaptiveWin
                        T = ptsTs(k)-pos_ts(ptsX(k),ptsY(k));
                        K = pos_idx(ptsX(k),ptsY(k));
                    else
                        T = ptsTs(k)-pos_ts(ptsX(k)+win,ptsY(k)+win);
                        K = pos_idx(ptsX(k)+win,ptsY(k)+win);
                    end

                    tWidths(k) = min(T(:));

                    for x = 1:length(K(:))
                        if K(x) > 0
                            if (tWidths(K(x))==-1 || tWidths(K(x))==inf)
                                tWidths(K(x)) = T(x);
                            else
                                tWidths(K(x)) = min(tWidths(K(x)), T(x));
                            end
                        end
                    end
                elseif IE(k)
                    pos_idx(ptsX(k),ptsY(k)) = k;
                    pos_ts(ptsX(k),ptsY(k)) = ptsTs(k);

                    if tWidths(k)==-1
                        tWidths(k) = inf;
                    end
                end
            end
        case 2                      % No IE or TE given
            for k = 1:length(ptsX)
                if ptsP(k) < 0
                    if pos_ts(ptsX(k), ptsY(k)) > 0 && adaptiveWin
                        T = ptsTs(k)-pos_ts(ptsX(k),ptsY(k));
                        K = pos_idx(ptsX(k),ptsY(k));
                    else
                        T = ptsTs(k)-pos_ts(ptsX(k)+win,ptsY(k)+win);
                        K = pos_idx(ptsX(k)+win,ptsY(k)+win);
                    end

                    tWidths(k) = min(T(:));

                    for x = 1:length(K(:))
                        if K(x) > 0
                            if (tWidths(K(x))==-1 || tWidths(K(x))==inf)
                                tWidths(K(x)) = T(x);
                            else
                                tWidths(K(x)) = min(tWidths(K(x)), T(x));
                            end
                        end
                    end
                else
                    pos_idx(ptsX(k),ptsY(k)) = k;
                    pos_ts(ptsX(k),ptsY(k)) = ptsTs(k);

                    if tWidths(k)==-1
                        tWidths(k) = inf;
                    end
                end
            end
        otherwise                    % Default, impossible
            tWidths = [];
    end
    tWidths(tWidths(:)==-1) = inf;
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