%% RatingGUI(videoFn)
% INPUT
% videoFn: the video file including the path.
%
% Derived from VideoInCustomGUIExample
% --
% Kevin Tsai@yymmdd: 150910
% MATLAB version: R2014a(8.3.0.532)
% PsychtoolboxVersion: 3.0.12

function RatingGUI(videoFn)
setenv('PSYCH_ALLOW_DANGEROUS', '1');

%%
% Check the avalibility of the file
if nargin < 1
    videoFn = './atrium.avi';
end
if isempty(dir(videoFn))
    videoFn = './atrium.avi';
end

global rating
rating = [];

%%
% Initialize the video reader.
videoSrc = vision.VideoFileReader(videoFn);

%%
% Create a figure window and two axes to display the input video and the
% processed video.
[hFig, hAxes] = createFigureAndAxes();

%%
% Add buttons to control video playback.
insertButtons(hFig, videoSrc);

%% Result of Pressing the Start Button
% Now that the GUI is constructed, we trigger the play callback which
% contains the main video processing loop defined in the
% |getAndProcessFrame| function listed below. If you prefer to click on the
% |Start| button yourself, you can comment out the following line of code.
playCallback([],findobj('tag','Slider123'),videoSrc,hAxes);

%%
% Note that each video frame is centered in the axis box. If the axis size
% is bigger than the frame size, video frame borders are padded with
% background color. If axis size is smaller than the frame size scroll bars
% are added.

%% Create Figure, Axes, Titles
% Create a figure window and two axes with titles to display two videos.
    function [hFig, hAxes] = createFigureAndAxes()
        
        % Close figure opened by last run
        figTag = 'CVST_VideoOnAxis_9804532';
        close(findobj('tag',figTag));
        
        % Get the info of screen
        screensize = get( groot, 'Screensize' );
        screensize(1:2) = 0;
        
        % Create new figure
        hFig = figure('numbertitle', 'off', ...
            'name', 'Behavioral Rating GUI', ...
            'menubar','none', ...
            'toolbar','none', ...
            'resize', 'on', ...
            'tag',figTag, ...
            'renderer','painters', ...
            'position',screensize);
        
        % Create axes and titles
        hAxes.axis1 = createPanelAxisTitle(hFig,[0.01 0.01 0.98 0.98]); %[X Y W H]
    end

%% Create Axis and Title
% Axis is created on uipanel container object. This allows more control
% over the layout of the GUI. Video title is created using uicontrol.
    function hAxis = createPanelAxisTitle(hFig, pos)
        
        % Create panel
        hPanel = uipanel('parent',hFig,'Position',pos,'Units','Normalized',...
            'BackgroundColor',[0,0,0]);
        
        % Create axis
        hAxis = axes('position',[0 0 1 1],'Parent',hPanel);
        set(hAxis,'xtick',[],'ytick',[],'xcolor',[1 1 1],'ycolor',[1 1 1]);
    end

%% Insert Buttons
% Insert buttons to play, pause the videos.
    function insertButtons(hFig, videoSrc)
        % Exit button with text Exit
        uicontrol(hFig,'unit','Normalized','style','pushbutton','string','Exit',...
            'position',[0.9 0.01 0.09 0.05],'callback', ...
            {@exitCallback,videoSrc,hFig});
        
        % pasive slider bar
        uicontrol(hFig,'unit','Normalized','Style', 'slider','Min',1,'Max',9,'Value',5,...
            'Position', [0.7 0.35 0.1 0.3],'tag','Slider123');
    end

%% Play Button Callback
% This callback function rotates input video frame and displays original
% input video frame and rotated frame on axes. The function
% |showFrameOnAxis| is responsible for displaying a frame of the video on
% user-defined axis. This function is defined in the file
% <matlab:edit(fullfile(matlabroot,'toolbox','vision','visiondemos','showFrameOnAxis.m')) showFrameOnAxis.m>
    function playCallback(~,sObject,videoSrc,hAxes)
        try
            % setup mouse initial position
            screensize = get( groot, 'Screensize' );
            theX = screensize(RectRight);
            theY = screensize(RectBottom);
            SetMouse(theX/4*3,theY/2);
            
            % display video
            Value = 5; count = 0;
            frameIdle = ceil(5*videoSrc.info.VideoFrameRate); % 5 sec idle time is allowed
            while ~isDone(videoSrc)
                % Read input video frame
                frame = step(videoSrc);
                % Display input video frame on axis
                showFrameOnAxis(hAxes.axis1, frame);
                % catch the mouse movement
                [x,y,~] = GetMouse;
                % adjust the sensitivty of the slider
                sensi = 18;
                nowValue = (theY/2-y)/theY*sensi+5;
                % just in case that the mouse is out of screen
                if nowValue > 9
                    nowValue = 9;
                elseif nowValue < 1
                    nowValue = 1;
                end
                set(sObject,'Value', nowValue);
                % set the rating back to middle if idle time is too long
                rating = cat(1,rating,nowValue);
                if nowValue == Value;
                    count = count + 1;
                    if count == frameIdle
                        SetMouse(x,theY/2);
                        Value = 5;
                        count = 0;
                    end
                else
                    count = 0;
                    Value = nowValue;
                end
            end
            
            % Close the video file
            release(videoSrc);
            % save the rating
            c = clock;
            fn = sprintf('Rating%s-%d%d.mat',date,c(4),c(5));
            save(fn,'rating');
            figure,plot(rating)
            
        catch ME
            % Re-throw error message if it is not related to invalid handle
            if ~strcmp(ME.identifier, 'MATLAB:class:InvalidHandle')
                rethrow(ME);
            end
        end
    end

%% Exit Button Callback
% This callback function releases system objects and closes figure window.
    function exitCallback(~,~,videoSrc,hFig)
        
        % Close the video file
        release(videoSrc);
        % Close the figure window
        close(hFig);
        % save the raitng
        c = clock;
        fn = sprintf('Rating%s-%d%d.mat',date,c(4),c(5));
        save(fn,'rating');
        figure,plot(rating)
    end
end
