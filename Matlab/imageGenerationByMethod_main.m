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

% EBSNoR method types
NOPROCESSING = 1;
PERPIXEL = 2;
ADAPTIVEWINDOW = 3;
SPATIALWINDOW = 4;

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
seq_name = "";
mode = SNOWREMOVED;
bg_color = WHITE;
padding = 10;
frames = [];
methods = [NOPROCESSING, PERPIXEL, SPATIALWINDOW, ADAPTIVEWINDOW];

% Algorithm settings
method_preProcessing = FULL;
IE_tWindow = 10000;
TE_depth = 10;
tWindow = 10000;
sWindow = 2;
camera_res = [720, 1280];

%% INITIALIZATION
load(mat_fName);
if isempty(frames)
    frames = 1:length(frame_data);
end
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
for i=1:length(frames)
    for j=1:length(methods)
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
        switch methods(j)
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
        events(j) = ev;
    end
    img = imageGen_methodComp(events,mode,bg_color,camRes=camera_res,padding=padding);
    img = insertText(img,[10, 10],title_str,FontSize=18);
    if length(methods) < 4
        for m=1:length(methods)
            xpos = 10+padding*(m-1)+camera_res(2)*(m-1)+11;
            img =  insertText(img,[xpos, 81],method_strs(m),FontSize=18);
        end
    else
        for m=1:length(method)
            shift_y = double(m > 2);
            shift_x = mod(m-1 ,2);
            ypos = 70+padding*shift_y+camera_res(1)*shift_y+11;
            xpos = 10+padding*shift_x+camera_res(2)*shift_x+11;
            img = insertText(img,[xpos, ypos],method_strs(m),FontSize=18);
        end
    end
    img_saveName = [img_baseName,'frame',num2str(frames(i)),'.png'];
    imwrite(img, img_saveName);
    fprintf("Saved: %s\n", img_saveName);
end
