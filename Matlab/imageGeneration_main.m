clear; close all; clc;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SCRIPT: imageGeneration_main -- Generate/save results images.           %
% ----------------------------------------------------------------------- %
% Script is used to generate and save EBSnoR results images. Images can   %
% be created using several modes and background colors. Additionally,     %
% images can be created in "multi-mode" format, which displays multiple   %
% modes on the same plot. To enable "multi-mode" format, submit a matrix  %
% of mode options. Modes and background colors are assigned integers in   %
% following manner:                                                       %
% Modes:                                                                  %
%   0 --> Original scene                                                  %
%   1 --> Original scene, snow highlighted                                %
%   2 --> Filtered scene, snow removed                                    %
%   3 --> Filtered scene, snow only                                       %
% Background Colors:                                                      %
%   0 --> White                                                           %
%   1 --> Grey                                                            %
%   2 --> Black                                                           %
% Prior to running this script, the saveFrames_main script must be run in %
% order to obtain frame data for use in this script.                      %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% FILENAMES
mat_fName = "";
img_baseName = '';

%% METHOD TYPES
% Pre-processing method types
FULL = 0;
NOINCEPTIVEEVENT = 1;
NOLABELPROPAGATION = 2;

% EBSnoR method types
PERPIXEL = 0;
ADAPTIVEWINDOW = 1;
SPATIALWINDOW = 2;
NOPROCESSING = 3;

% Image mode method types
ORIGINAL = 0;
SNOWHIGHLIGHTED = 1;
SNOWREMOVED = 2;
SNOWONLY = 3;

% Image background color method types
WHITE = 0;
GREY = 1;
BLACK = 2;

%% SETTINGS
% Image settings
modes = [ORIGINAL, SNOWHIGHLIGHTED, SNOWREMOVED, SNOWONLY];
bg_color = WHITE;
padding = 10;
frames = [];

% Algorithm settings
method_preProcessing = FULL;
method_EBSnoR = PERPIXEL;
IE_tWindow = 10000;
TE_depth = 10;
tWindow = 10000;
sWindow = 2;
camera_res = [720, 1280];

%% INITIALIZATION
load(mat_fName, 'frame_data');
if isempty(frames)
    frames = 1:length(frame_data);
end

%% MAIN LOOP
for i=1:length(frames)
    ev = frame_data(frames(i));
    switch method_preProcessing
        case FULL
            [IE, TE, ~] = IE_filter(ev,IE_tWindow,TE_depth=TE_depth);
        case NOLABELPROPAGATION
            [IE, ~, ~] = IE_filter(ev,IE_tWindow);
            TE = [];
        case NOINCEPTIVEEVENT
            IE = [];
            TE = [];
    end
    switch method_EBSnoR
        case PERPIXEL
            sWin = 0;
            ev.s = EBSnoR(ev,tWindow,sWin,IE,TE,camRes=camera_res,useAdaptiveWin=false);
        case ADAPTIVEWINDOW
            sWin = sWindow;
            ev.s = EBSnoR(ev,tWindow,sWin,IE,TE,camRes=camera_res,useAdaptiveWin=true);
        case SPATIALWINDOW
            sWin = sWindow;
            ev.s = EBSnoR(ev,tWindow,sWin,IE,TE,camRes=camera_res,useAdaptiveWin=false);
        otherwise
            ev.s = false(length(ev.x), 1);
    end
    img = imageGen(ev,modes,bg_color,camRes=camera_res,padding=padding);
    img_saveName = [img_baseName,'frame',num2str(frames(i)),'.png'];
    imwrite(img,img_saveName);
    fprintf("Saved: %s\n", img_saveName);
end
