function snow = EBSnoR(ev, tWin, sWin, IE, TE, options)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FUNCTION: EBSnoR -- Perform EBSnoR filtering                            %
% ----------------------------------------------------------------------- %
% Parameters:                                                             %
%   ev : struct(fields=x, y, ts, p), required                             %
%       Events to filter.                                                 %
%   tWin : double, required                                               %
%       Time windowing threshold.                                         %
%   sWin : double, required                                               %
%       Spatial windowing threshold.                                      %
%   IE : matrix[logical], positional optional                             %
%       Logical matrix of IE indices.                                     %
%   TE : matrix[double], positional optional                              %
%       N events by M matrix of IE to TE pointers. Makes IE required.     %
%   camRes : matrix[double], named optional                               %
%       Camera resolution, given as [y,x]. Default is [720, 1280].        %
%   useAdaptiveWin : logical, named optional                              %
%       Use adaptive windowing technique? Default is false.               %
% Returns:                                                                %
%   snow : matrix[logical]                                                %
%       Logical matrix of snow indices.                                   %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EXAMPLES                                                                %
% ----------------------------------------------------------------------- %
% EBSnoR(ev,tWin,sWin);                                                   %
% EBSnoR(ev,tWin,sWin,IE);                                                %
% EBSnoR(ev,tWin,sWin,IE, TE);                                            %
% EBSnoR(ev,tWin,sWin,camRes=[480,640]);                                  %
% EBSnoR(ev,tWin,sWin,useAdaptiveWin=true);                               %
% EBSnoR(ev,tWin,sWin,camRes=[480,640],useAdaptiveWin=true)               %
% EBSnoR(ev,tWin,sWin,IE,useAdaptiveWin=true,camRes=[480,640])            %
% EBSnoR(ev,tWin,sWin,IE,TE,useAdaptiveWin=true,camRes=[480,640])         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
arguments
    ev (1, 1) struct {mustHaveFieldsXYTsP(ev)}
    tWin (1, 1) double
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

    snow = false(length(ptsX), 1);                      % Snow Events

    switch evalMethod
        case 0                      % IE and TE given
            for k = 1:length(ptsX)
                if IE(k) && ptsP(k) < 0
                    T = false;
                    if adaptiveWin
                        T = ptsTs(k)-pos_ts(ptsX(k),ptsY(k)) < tWin;
                        K = pos_idx(ptsX(k),ptsY(k));
                    end
                    if ~T
                        T = ptsTs(k)-pos_ts(ptsX(k)+win,ptsY(k)+win) < tWin;
                        K = pos_idx(ptsX(k)+win,ptsY(k)+win);
                    end

                    if sum(T(:)) > 0
                        snow(k) = true;
                        idx = TE(k, :);
                        snow(idx(idx(:) > 0)) = true;
                        snow(K(T(:))) = true;
                        idx = TE(K(T(:)), :);
                        snow(idx(idx(:) > 0)) = true;
                    end
                elseif IE(k)
                    pos_idx(ptsX(k),ptsY(k))=k;
                    pos_ts(ptsX(k),ptsY(k))=ptsTs(k);
                end
            end
        case 1                       % Only IE given
            for k = 1:length(ptsX)
                if IE(k) && ptsP(k) < 0
                    T = false;
                    if adaptiveWin
                        T = ptsTs(k)-pos_ts(ptsX(k),ptsY(k)) < tWin;
                        K = pos_idx(ptsX(k),ptsY(k));
                    end
                    if ~T
                        T = ptsTs(k)-pos_ts(ptsX(k)+win,ptsY(k)+win) < tWin;
                        K = pos_idx(ptsX(k)+win,ptsY(k)+win);
                    end

                    if sum(T(:)) > 0
                        snow(k) = true;
                        snow(K(T(:))) = true;
                    end
                elseif IE(k)
                    pos_idx(ptsX(k),ptsY(k)) = k;
                    pos_ts(ptsX(k),ptsY(k)) = ptsTs(k);
                end
            end
        case 2                      % No IE or TE given
            for k=1:length(ptsX)
                if ptsP(k) < 0
                    T = false;
                    if adaptiveWin
                        T = ptsTs(k)-pos_ts(ptsX(k),ptsY(k)) < tWin;
                        K = pos_idx(ptsX(k),ptsY(k));
                    end
                    if ~T
                        T = ptsTs(k)-pos_ts(ptsX(k)+win,ptsY(k)+win) < tWin;
                        K = pos_idx(ptsX(k)+win,ptsY(k)+win);
                    end

                    if sum(T(:)) > 0
                        snow(k) = true;
                        snow(K(T(:))) = true;
                    end
                else
                    pos_idx(ptsX(k),ptsY(k)) = k;
                    pos_ts(ptsX(k),ptsY(k)) = ptsTs(k);
                end
            end
        otherwise                   % Default, impossible
            snow = [];
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