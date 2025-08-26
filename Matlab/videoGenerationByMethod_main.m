clear; close all; clc;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SCRIPT: videoGenerationByMethod_main -- Generate/save results videos.   %
% ----------------------------------------------------------------------- %
% Script is used to generate and save EBSnoR results videos. Videos can   %
% be created using several modes and background colors. Additionally,     %
% videos can be created in "multi-method" format, which displays multiple %
% processing methods on the same plot. To enable "multi-method" format,   %
% submit a matrix of event structures. Modes and background colors are    %
% assigned integers in                                                    %
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
NOPROCESSING = 1;
PERPIXEL = 2;
ADAPTIVEWINDOW = 3;
SPATIALWINDOW = 4;

% Video mode method types
ORIGINAL = 0;
SNOWHIGHLIGHTED = 1;
SNOWREMOVED = 2;
SNOWONLY = 3;

% Video background color method types
WHITE = 0;
GREY = 1;
BLACK = 2;

%% SETTINGS
% Video settings
mode = SNOWREMOVED;
bg_color = WHITE;
padding = 10;
seq_name = "";
methods = [NOPROCESSING, PERPIXEL, SPATIALWINDOW, ADAPTIVEWINDOW];

% Algorithm settings
method_preProcessing = FULL;
IE_tWindow = 10000;
TE_depth = 10;
tWindow = 10000;
sWindow = 2;
camera_res = [720, 1280];

%% INITIALIZATION
vid = VideoWriter(vid_fName);
open(vid);

load(mat_fName);
title_str = [seq_name,', Threshold = ',num2str(tWindow/1000, '%.2f'),'ms'];
method_strs = ["Original","Per Pixel","Adaptive Window","Spatial Window"];
for i=1:length(method_strs)
    if isempty(find(methods == 1,1))
        method_strs(i) = "";
    end
end
method_strs = method_strs(method_strs ~= "");
events(length(methods)) = struct("x",[],"y",[],"ts",[],"p",[],"s",[]);
%% MAIN LOOP
for i=1:length(frame_data)
    for j=1:length(methods)
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
        switch methods(j)
            case PERPIXEL
                sWin = 0;
                ev.s = EBSnoR(ev,tWindow,sWin,IE,TE,camRes=camera_res,useAdaptiveWin=false);
            case ADAPTIVEWIN
                sWin = sWindow;
                ev.s = EBSnoR(ev,tWindow,sWin,IE,TE,camRes=camera_res,useAdaptiveWin=true);
            case SPATIALWINDOW
                sWin = sWindow;
                ev.s = EBSnoR(ev,tWindow,sWin,IE,TE,camRes=camera_res,useAdaptiveWin=false);
            otherwise
                ev.s = false(length(ev.x), 1);
        end
        events(j) = ev;
    end
    frame_img = imageGen_methodComp(events,mode,bg_color,camRes=camera_res,padding=padding);
    frame_img = insertText(frame_img,[10, 10],title_str,FontSize=18);
    if length(methods) < 4
        for m=1:length(methods)
            xpos = 10 + padding*(m-1)+camera_res(2)*(m-1)+11;
            frame_img = insertText(frame_img, [xpos, 81], method_strs(m), FontSize=18);
        end
    else
        for m=1:length(methods)
            shift_y = double(m>2);
            shift_x = mod(m-1, 2);
            ypos = 70+padding*shift_y+camera_res(1)*shift_y+11;
            xpos = 10+padding*shift_x+camera_res(2)*shift_x+11;
            frame_img = insertText(frame_img, [xpos, ypos], method_strs(m), FontSize=18);
        end
    end
    frame = im2frame(frame_img);
    writeVideo(vid, frame);

    fprintf("%d/%d -- %.2f complete.\n",i,length(frame_data),(i/length(frame_data))*100);
end

%% SAVE VIDEO
close(vid);


