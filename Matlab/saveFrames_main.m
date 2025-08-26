clear; close all; clc;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SCRIPT: saveFrames_main -- Save event data as frames.                   %
% ----------------------------------------------------------------------- %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Script is used load and save event data as frames. This process can be  %
% started either from the first frame in the sequence, or from any later  %
% frame. The number of frames saved is determined by the declared frame   %
% window and number of seconds worth of events to save. After generation  %
% is complete, the frames are saved to the indicated MAT file.            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% FILENAMES
ev_fName = "";
save_fName = "";

%% SETTINGS
start_frame = 0;            % Frame at which to start recording
frame_win = 33333;          % Number of microseconds per frame
num_seconds = 5;            % Number of seconds to record.

%% INITIALIZATION
% Initialize parameters needed for event reading
start_pos = 0;
ts_in = 0;

% Calculate number of frames needed
num_frames = round((num_seconds*1000000)/frame_win);

% Initialize frames container
frame_data = struct.empty(0, num_frames);

% Iterate over events until the desired starting frame is reached
for i=1:start_frame-1
    [~, start_pos, ~, ts_in] = streamDatEventsByTs(ev_fName, start_pos, frame_win, ts_in);
    fprintf("Initializing -- %.2f%% ...\r", (i/start_frame)*100);
end

%% MAIN LOOP
for i=1:num_frames
    [events, start_pos, ~, ts_in] = streamDatEventsByTs(ev_fName, start_pos, frame_win, ts_in);
    frame_data(i).ts = events.ts;
    frame_data(i).x = events.x;
    frame_data(i).y = events.y;
    frame_data(i).p = events.p;

    fprintf("Recording %d/%d -- %.2f%% complete.\n", i, num_frames, (i/num_frames)*100);
end

%% SAVE DATA
save(save_fName, "frame_data", "-v7.3");