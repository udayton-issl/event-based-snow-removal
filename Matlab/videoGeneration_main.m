clear; close all; clc;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SCRIPT: videoGeneration_main -- Generate/save results videos.           %
% ----------------------------------------------------------------------- %
% Script is used to generate and save EBSnoR results videos. Videos can   %
% be created using several modes and background colors. Additionally,     %
% videos can be created in "multi-mode" format, which displays multiple   %
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
vid_fName = "";

%% METHOD TYPES
% Pre-processing method types
FULL = 0;
NOINCEPTIVEEVENT = 1;
NOLABELPROPAGATION = 2;

% EBSnoR method types
NOPROCESSING = 0;
PERPIXEL = 1;
ADAPTIVEWINDOW = 2;
SPATIALWINDOW = 3;

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
% Video settings
modes = [ORIGINAL, SNOWHIGHLIGHTED, SNOWREMOVED, SNOWONLY];
bg_color = WHITE;
padding = 10;
seq_name = "";

% Algorithm settings
method_preProcessing = FULL;
method_EBSnoR = PERPIXEL;
IE_tWindow = 10000;
TE_depth = 10;
tWindow = 10000;
sWindow = 2;
camera_res = [720, 1280];

%% INITIALIZATION
vid = VideoWriter(vid_fName);
open(vid);

load(mat_fName);
txt_str = [seq_name,', Threshold = ',num2str(tWindow/1000, '%.2f'),'ms'];

%% MAIN LOOP
for i=1:length(frame_data)
    ev = frame_data(i);
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
    frame_img = imageGen(ev,modes,bg_color,camRes=camera_res,padding=padding);
    frame_img = insertText(frame_img,[10, 10],txt_str,FontSize=18);
    frame = im2frame(frame_img);
    writeVideo(vid, frame);

    fprintf("%d/%d -- %.2f complete.\n",i,length(frame_data),(i/length(frame_data))*100);
end

%% SAVE VIDEO
close(vid);
