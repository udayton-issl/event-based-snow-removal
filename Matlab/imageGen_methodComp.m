function img = imageGen_methodComp(events, mode, bgColor, options)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FUNCTION: imageGen -- Generate results images                           %
% ----------------------------------------------------------------------- %
% Parameters:                                                             %
%   events : matrix[struct(fields=x, y, ts, p, s)], positional required   %
%       1xN matrix of event structures to create an image from.           %
%   modes : double | matrix[double], positional required                  %
%       Desired output modes. Can be one or multiple. Options:            %
%           0 --> Original scene                                          %
%           1 --> Original scene, snow highlighted                        %
%           2 --> Filtered scene, snow removed                            %
%           3 --> Filtered scene, snow only                               %
%   bgColor : double, positional optional                                 %
%       Scene background color. Options:                                  %
%           0 --> White                                                   %
%           1 --> Grey                                                    %
%           2 --> Black                                                   %
%   camRes : matrix[double], named optional                               %
%       Camera resolution, given as [y,x]. Default is [720, 1280].        %
%   padding : double, named optional                                      %
%       Multi-mode only, spacing between images in pixels. Default is 10. %
% Returns:                                                                %
%   img : matrix[double]                                                  %
%       The generated image.                                              %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EXAMPLES                                                                %
% ----------------------------------------------------------------------- %
% imageGen(events, modes)                                                 %
% imageGen(events, modes, bgColor)                                        %
% imageGen(events, modes, camRes=[640,480])                               %
% imageGen(events, modes, padding=5)                                      %
% imageGen(events, modes, camRes=[640,480], padding=5)                    %
% imageGen(events, modes, bgColor, camRes=[640,480], padding=5)           %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
arguments
    events (1, :) struct {mustHaveFieldsXYTsPS(events),sizeCheck(events,4)}
    mode (1, 1) double
    bgColor (1, 1) double = 0
    options.camRes (1, 2) double = [720, 1280]
    options.padding (1, 1) double = 10
end
    camRes = options.camRes;
    framePad = options.padding;
    numImgs = length(events);
    yPad = [70, 10];
    xPad = [10, 10];

    if numImgs < 4
        sz_y = camRes(1) + yPad(1) + yPad(2);
        sz_x = camRes(2)*numImgs+xPad(1)+xPad(2)+framePad*(numImgs-1);
    else
        sz_y = camRes(1)*2 + yPad(1) + yPad(2) + framePad;
        sz_x = camRes(2)*2 + xPad(1) + xPad(2) + framePad;
    end
    img = ones(sz_y, sz_x, 3);
    posColor = [0, 0, 0];
    negColor = [0, 0, 1];
    snowColor = [1, 0, 0];
    switch bgColor
        case 0          % white background
            template = ones(camRes(1), camRes(2), 3);
        case 1          % grey background
            template = ones(camRes(1), camRes(2), 3)*0.2;
        case 2          % black background
            template = zeros(camRes(1), camRes(2), 3);
            posColor = [1, 1, 1];
    end
    for j=1:numImgs
        subImg = template;
        ev = events(j);
        ev.x = ev.x + 1;
        ev.y = ev.y + 1;
        switch mode
            case 0      % original scene
                for i=1:length(ev.x)
                    if ev.p(i) > 0
                        subImg(ev.y(i), ev.x(i), :) = posColor;
                    else
                        subImg(ev.y(i), ev.x(i), :) = negColor;
                    end
                end
            case 1      % snow highlighted
                for i=1:length(ev.x)
                    if ev.s(i) == 1
                        subImg(ev.y(i), ev.x(i), :) = snowColor;
                    elseif ev.p(i) > 0
                        subImg(ev.y(i), ev.x(i), :) = posColor;
                    else
                        subImg(ev.y(i), ev.x(i), :) = negColor;
                    end
                end
            case 2      % snow removed
                for i=1:length(ev.x)
                    if ev.s(i) == 1
                        continue;
                    elseif ev.p(i) > 0
                        subImg(ev.y(i), ev.x(i), :) = posColor;
                    else
                        subImg(ev.y(i), ev.x(i), :) = negColor;
                    end
                end
            case 3      % snow only
                for i=1:length(ev.x)
                    if ev.s(i) == 0
                        continue;
                    elseif ev.p(i) > 0
                        subImg(ev.y(i), ev.x(i), :) = posColor;
                    else
                        subImg(ev.y(i), ev.x(i), :) = negColor;
                    end
                end
        end
        if numImgs < 4
            pos_y = yPad(1) + 1;
            pos_x = xPad(1) + framePad*(j-1)+camRes(2)*(j-1)+1;
        else
            shift_y = double(j>2);
            shift_x = mod(j-1, 2);
            pos_y = yPad(1)+framePad*shift_y+camRes(1)*shift_y+1;
            pos_x = xPad(1)+framePad*shift_x+camRes(2)*shift_x+1;
        end
        img(pos_y:pos_y+camRes(1)-1, pos_x:pos_x+camRes(2)-1, :) = subImg;

        % Add outline for white background
        if bgColor == 0
            img(pos_y, pos_x:pos_x+camRes(2)-1, :) = zeros(1, camRes(2), 3);
            img(pos_y+camRes(1)-1, pos_x:pos_x+camRes(2)-1, :) = zeros(1, camRes(2), 3);
            img(pos_y:pos_y+camRes(1)-1, pos_x, :) = zeros(1, camRes(1), 3);
            img(pos_y:pos_y+camRes(1)-1, pos_x+camRes(2)-1, :) = zeros(1, camRes(1), 3);
        end
    end
end

function mustHaveFieldsXYTsPS(ev)
    for idx=1:length(ev)
        % Test for ev.x
        if ~isfield(ev(idx), 'x')
            error('Field "x" missing from event struct.')
        end
        % Test for ev.y
        if ~isfield(ev(idx), 'y')
            error('Field "y" missing from event struct.')
        end
        % Test for ev.ts
        if ~isfield(ev(idx), 'ts')
            error('Field "ts" missing from event struct.')
        end
        % Test for ev.p
        if ~isfield(ev(idx), 'p')
            error('Field "p" missing from event struct.')
        end
        % Test for ev.s
        if ~isfield(ev(idx), 's')
            error('Field "s" missing from event struct.')
        end
    end
end

function sizeCheck(ev, maxSz)
    if length(ev) > maxSz
        error('Too many event structures. Maximum is four.')
    end
end