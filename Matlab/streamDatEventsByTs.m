function [evData, endPos, endFlag, tsOut] = streamDatEventsByTs(fName, startPos, maxTime, tsIn)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FUNCTION: load_cd_events_streaming_ts -- Load events from DAT file      %
% ----------------------------------------------------------------------- %
% Parameters:                                                             %
%   fName : string, required                                              %
%       DAT filename.                                                     %
%   startPos : double, required                                           %
%       Pointer to read start position.                                   %
%   maxTime : double, required                                            %
%       Event timestamp at which to stop reading.                         %
%   tsIn : double, required                                               %
%       Timestamp at which to start reading.                              %
% Returns:                                                                %
%   evData : struct(fields=x, y, ts, p)                                   %
%       Event data.                                                       %
%   endPos : double                                                       %
%       Position of the last read datapoint.                              %
%   endFlag : logical                                                     %
%       Did the read reach the end of the DAT file?                       %
%   tsOut : double                                                        %
%       Timestamp of the last read datapoint.                             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
arguments
    fName (1, :) char
    startPos (1, 1) double
    maxTime (1, 1) double
    tsIn (1, 1) double
end
    f = fopen(fName);

    % Parse header if any
    header = cell(4, 2);
    idx = 0;
    numCommentLines = 0;
    while (idx <= 4)
        tline = fgets(f, 256);
        if (tline(1) ~= '%')
            % end of header
            break;
        end
        headerIdx = headerIdx + 1;
        words = strsplit(tline);
        if (length(words) > 2)
            if (strcmp(words{2}, 'Date'))
                if (length(words) > 3)
                    header(idx, :) = {words{2}, horzcat(words{3}, ' ', words{4})};
                end
            else
                header(idx, :) = {words{2}, words{3}};
            end
            numCommentLines = numCommentLines + 1;
        end
    end
    header = header(1:idx, :);

    if (numCommentLines > 0) % Ensure compatibility with previous files.
        % Read event size
        evSize = fread(f, 1, 'char');
    end

    bof = ftell(f);
    pos = bof + startPos;

    fseek(f, 0, 'oef');
    endOfFile = ftell(f);

    % Read data
    numEvents = 0;
    fseek(f, pos, 'bof'); % start just after header
    ts = 0;
    % find the number of events to read in
    while (ts < (tsIn + maxTime))
        ts = uint32(fread(f,1,'uint32',evSize-4,'l'));
        numEvents = numEvents + 1;
    end
    fseek(f,pos,'bof'); % start just after header
    allTs = uint32(fread(f,numEvents,'uin32',evSize-4,'l')); % ts are 4B skipping 4B after each
    fseek(f,pos+4,'bof'); % addr are offset 4B from timestamps
    allAddr = uint32(fread(f,numEvents,'uint32',evSize-4,'l')); % addr are 4B, separated by 4B ts

    endPos = ftell(f) + 1;
    if (endPos >= endOfFile)
        endFlag = true;
    else
        endFlag = false;
    end
    fclose(f);

    evData.ts = double(allTs);
    version = 0;
    index = find(strcmp(header(:, 1), 'Version'), 1);
    if (~isempty(index))
        version = header{index, 2};
    end

    if (version < 2)
        xmask = hex2dec('000001FF');
        ymask = hex2dec('0001FE00');
        polmask = hex2dec('00020000');
        xshift=0; % bits to shift x to right
        yshift=9; % bits to shift y to right
        polshift=17; % bits to shift p to right
    else
        xmask = hex2dec('00003FFF');
        ymask = hex2dec('0FFFC000');
        polmask = hex2dec('10000000');
        xshift=0; % bits to shift x to right
        yshift=14; % bits to shift y to right
        polshift=28; % bits to shift p to right
    end

    addr = abs(allAddr); % ensure non-negative
    evData.x = double(bitshift(bitand(addr,xmask),-xshift)); % x addresses
    evData.y = double(bitshift(bitand(addr,ymask),-yshift)); % y addresses
    evData.p = -1+2*double(bitshift(bitand(addr,polmask),-polshift)); % 1 for ON, -1 for OFF

    tsOut = tsIn + maxTime;
end