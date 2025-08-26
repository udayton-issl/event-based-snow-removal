clear; close all; clc;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SCRIPT: getTimewidthsSimOnly_main -- Get/save EBSnoR timewidths.        %
% ----------------------------------------------------------------------- %
% Script is used to generate EBSnoR timewidths for the indicated event    %
% sequence. The event sequence should contain simulation data only. For   %
% ablation study use, timewidths are generated for all pre-processing and %
% all EBSnoR processing methods. For pre-processing, these include:       %
%   - No Inceptive Event filtering                                        %
%   - No IE label propagation (Trailing Events)                           %
% For EBSnoR processing, these include:                                   %
%   - EBSnoR using constant spatial windowing                             %
%   - EBSnoR using adaptive spatial windowing                             %
%   - EBSnoR using no spatial windowing                                   %
% The generated timewidths are saved to the indicated MAT file.           %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% FILENAMES
sim_fName = "";
save_fName = "";

%% SETTINGS
IE_tWin = 10000;
TE_depth = 10;
frameWin = 33333;
numSeconds = 3.6;
sWin = 2;
camRes = [720, 1280];

%% INITIALIZATION
startPos = 0;
tsIn = 0;
arrIdx = 1;
numLoops = round((numSeconds*1e6)/frameWin);

if useSimData
    simData = load(sim_fName);
    simIdx = 1;
end

tWidths_noIE = zeros(100000000, 1);
tWidths_noLabelPropagation = zeros(100000000, 1);
tWidths_spatialWindow = zeros(100000000, 1);
tWidths_adaptiveWindow = zeros(100000000, 1);
tWidths_noWindow = zeros(100000000, 1);
groundTruth = zeros(100000000, 1);

%% MAIN LOOP
for loop=1:numLoops
    simIdx = simData.ts >= tsIn & simData.ts < tsIn + frameWin;
    evData.x = simData.x(simIdx);
    evData.y = simData.y(simIdx);
    evData.p = simData.p(simIdx);
    evData.ts = simData.ts(simIdx);
    gt_temp = ones(length(evData.x), 1);
    tsIn = tsIn + frameWin;

    [IE, TE, ~] = IE_filter(evData,IE_tWin,TE_depth=TE_depth);

    % No Inceptive Event filtering
    temp_tWidths = EBSnoR_timewidths(evData,0,camRes=camRes);
    tWidths_noIE(arrIdx:arrIdx+length(evData.x)-1) = temp_tWidths;

    % Use Inceptive Event filtering, but no label propagation
    temp_tWidths = EBSnoR_timewidths(evData, 0, IE, camRes=camRes);
    tWidths_noLabelPropagation(arrIdx:arrIdx+length(evData.x)-1) = temp_tWidths;

    % Use Inceptive Event filtering, label propagation, and spatial window
    temp_tWidths = EBSnoR_timewidths(evData, sWin, IE, TE, camRes=camRes);
    tWidths_spatialWindow(arrIdx:arrIdx+length(evData.x)-1) = temp_tWidths;

    % Use Inceptive Event filtering and label propagation, but no spatial window
    temp_tWidths = EBSnoR_timewidths(evData, 0, IE, TE, camRes=camRes);
    tWidths_noWindow(arrIdx:arrIdx+length(evData.x)-1) = temp_tWidths;

    % Use Inceptive Event filtering, label propagation and adaptive window
    temp_tWidths = EBSnoR_timewidths(evData, sWin, IE, TE, camRes=camRes, useAdaptiveWin=true);
    tWidths_adaptiveWindow(arrIdx:arrIdx+length(evData.x)-1) = temp_tWidths;

    if useSimData
        groundTruth(arrIdx:arrIdx+length(evData.x)-1) = gt_temp;
    end
    arrIdx = arrIdx + length(evData.x);

    fprintf('Loop %i/%i Finished -- %.2f%% Done.\n', loop, numLoops, (loop/numLoops)*100);
end

%% SAVE DATA
if arrIdx < 100000000
    tWidths_noIE = tWidths_noIE(1:arrIdx);
    tWidths_noLabelPropagation = tWidths_noLabelPropagation(1:arrIdx);
    tWidths_noWindow = tWidths_noWindow(1:arrIdx);
    tWidths_adaptiveWindow = tWidths_adaptiveWindow(1:arrIdx);
    tWidths_spatialWindow = tWidths_spatialWindow(1:arrIdx);
    groundTruth = groundTruth(1:arrIdx);
end

save(save_fName, ...
    "tWidths_noIE", ...
    "tWidths_noLabelPropagation", ...
    "tWidths_noWindow", ...
    "tWidths_adaptiveWindow", ...
    "tWidths_spatialWindow", ...
    "groundTruth", ...
    "-v7.3");

