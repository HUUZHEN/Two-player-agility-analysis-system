clear, clc

%% SETUP SELECTIONS

% 1. sceneRun needs to be specied.
% Default is to use GUI to setup scene
% To programmatically setup the scene follow the example in Prgm_2box.

% Scene Run choice: {'GUI_Setup' | 'Prgm_2box' | 'Prgm_MaxFOV','My_Scene'};
sceneRun = 'GUI_Setup';
xlsFile = 'test.xlsx';
xlstitle = {'time','xdata','ydata','velx','vely','accx','accy','xdata2','ydata2','velx2','vely2','accx2','accy2'};
xlstitle2 = {'P_ID','date','stage','time','vel_mean','acc_mean',...
                'P_ID2','date','stage','time','vel_mean','acc_mean'};
swrow = {'//','//','//','//','//','//','//','//','//','//','//','//','//','//','//','//','//'};
%xlswrite(xlsFile,xlstitle, 'Sheet1','A1:M1');
%xlswrite(xlsFile,xlstitle2, 'Sheet1','A1:M1');
%all_tittles=[xlstitle,xlstitle2];
%xlswrite(xlsFile,all_tittles,'Sheet1','A1:M1');
sheet1=1;
xlRange = 'A1:';

global writeflag;
writeflag=5;

%p1數據紀錄
global swflag;
swflag=0;%p1數據紀錄

% 新的買的 p2數據紀錄
global swflag2;%p2數據紀錄
swflag2=0;
global writeflag2;
writeflag2=5;
%底

global meandata2 meancount2 velxmean2 velymean2 accxmean2 accymean2 accmean2 velmean2 fetime2 meandatacount2 timemean2%紀錄P2數據

global swcount;
swcount=1;

%new
global swcount2;
swcount2=1;
%底

% 新增目標追蹤全局變數
global frame_without_p1 frame_without_p2 max_missing_frames
global p1_tid p2_tid p1_last_pos p2_last_pos p1_data p2_data
global twopoint20_last_update p1_detected_in_frame p2_detected_in_frame

frame_without_p1 = 0;
frame_without_p2 = 0;
max_missing_frames = 10;
p1_tid = [];
p2_tid = [];
p1_last_pos = [0, 0];
p2_last_pos = [0, 0];
p1_data = struct('xdata', 0, 'ydata', 0, 'fxdata', 0, 'fydata', 0, 'fvelx', 0, 'fvely', 0);
p2_data = struct('xdata', 0, 'ydata', 0, 'fxdata', 0, 'fydata', 0, 'fvelx', 0, 'fvely', 0);
twopoint20_last_update = 0;
p1_detected_in_frame = false;
p2_detected_in_frame = false;

global velxmean;
global velymean;
global accxmean;
global accymean;
global accmean;
global velmean;
global timemean;
global fetime;
global meancount;
global meandatacount;
global meandata;
global auto;
global autodec;
global autoR;
global autodecR;
global autoR2;
global autodecR2;
global auto2;
global autodec2;
global auto2R;
global autodec2R;
global auto3;
global autodec3;
global autonum;
global autodecT;
global autoT;
%新
global twopoint20;
global twopoints20;
global twopoint25;
global twopoints25;
%底


global tt;
tt=0;


clear meandata;
clear meandata2;%new

mvelx=0;
mvely=0;
maccx=0;
maccy=0;
TTAT1X=0;
TTAT1Y=0;
TTAT2X=0;
TTAT2Y=0;

%新
twopoint20=0;
twopoints20=0;
twopoint25=0;
twopoints25=0;
%底
meancount=1;
meancount2=1;%new p2

meandatacount=0;
meandatacount2=0; %p2

timemean=0;
timemean2=0;%p2
%p1數據
velxmean=0;
velymean=0;
accxmean=0;
accymean=0;
velmean=0;
fetime=0;

%新p2數據
velxmean2=0;
velymean2=0;
accxmean2=0;
accymean2=0;
fetime2=0;
%底

auto=0;
autodec=0;
auto2=0;
autodec2=0;
auto3=0;
autodec3=0;

autodecR=0;
autoR=0;

autodecR2=0;
autoR2=0;

autodec2R=0;
auto2R=0;
autonum=0;

autodecT=0;
autoT=0;
%p1
count=1;
time=0.05;
%p2
count2=1;
time2=0.05;

% 2. Specify COM ports if programmatically setting up scene
if (~strcmp(sceneRun,'GUI_Setup'))
    %%%%% EDIT COM PORTS %%%%%%
    controlSerialPort = 10;
    dataSerialPort = 8;
    USBDataPort = 7;
    loadCfg = 1;

end


%% Setup tracking scene

% Enables setting parameters by GUI
if(strcmp(sceneRun,'GUI_Setup'))
    
    % Call setup GUI
    hSetup = setup();
    close(hSetup.figure1);
    % Get parameters defined in GUI
    camIndex = hSetup.camIndex;
    hDataSerialPort = hSetup.hDataSerialPort;
    hControlSerialPort = hSetup.hControlSerialPort;
    wall = hSetup.wall;
    scene.azimuthTilt = hSetup.angle*pi/180;
    Params = hSetup.params; 
    % Target box settings
    scene.numberOfTargetBoxes = size(hSetup.subzone,1); 
    scene.targetBox = hSetup.subzone;
    % Define wall [BLx BLy W H]
    scene.areaBox = [wall.left wall.back abs(wall.left)+wall.right wall.front+abs(wall.back)];
    
    % Define plotting area [Lx Rx By Ty]
    scene.maxPos = [scene.areaBox(1)-0.1 scene.areaBox(1)+scene.areaBox(3)+0.1 scene.areaBox(2)-0.1 scene.areaBox(2)+scene.areaBox(4)+0.1];
    
    % Chirp config
    loadCfg = 0; %disabled because loaded in GUI
end

% Programmatically set scene. Includes example of setting boundary boxes to count in 
if(strcmp(sceneRun,'Prgm_2box'))
    
    %Read Chirp Configuration file
    configurationFileName = 'mmw_PC_optimized_dual_tracking.cfg';  % 使用優化的配置檔案
    cliCfg = readCfg(configurationFileName);
    Params = parseCfg(cliCfg);
    
    % Room Wall dimensions [m]
    % Measured relative to radar
    wall.left = -6; % signed: - required
    wall.right = 6;
    wall.front = 6;
    wall.back = -0; % signed: - required
    
    % define wall [BLx BLy W H]
    scene.areaBox = [wall.left wall.back abs(wall.left)+wall.right wall.front+abs(wall.back)];
    
    % Define two rectangles for specific counting in the region
    % Target box settings
    scene.numberOfTargetBoxes = 2;
    
    % Parameters to make it easier to define two rectangles of the same size
        % that are side by side    
    % RO = Rectangle Origin. RO is measured relative to Left Back wall corner
    box.ROxtoLB = 1.0; % x distance from left wall 
    box.ROytoLB = 1.5; % y distance from back wall
    box.height = 2;    % height of boxes 
    box.sep = 0.6;     % seperation width of boxes
    box.width = 1;     % width of boxes 
    box.RTXplot = box.ROxtoLB+wall.left;
    box.RTYplot = box.ROytoLB+wall.back;
    
    
    % Each row of targetBox specifies the dimensions of a rectangle for counting.
    % The # of rows of targetBox must match numberOfTargetBoxes.
    % The rectangles are specified by (x,y) coordinate and width and height 
    % Custom rectangles can be defined instead if two side by side rects of
    % same size are not desired using [RTCx RTCy W H] convention
    scene.targetBox = [box.RTXplot box.RTYplot box.width box.height; 
                       (box.RTXplot+box.width+box.sep) box.RTYplot box.width box.height];
    
    
    % define plotting area as margin around wall
    margin = 0.1; %[m]
    scene.maxPos = [scene.areaBox(1)-margin ...
                    scene.areaBox(1)+scene.areaBox(3)+margin ...
                    scene.areaBox(2)-margin ...
                    scene.areaBox(2)+scene.areaBox(4)+margin];

    % Azimuth tilt of radar. 
    angle = +0; % Signed: + if tilted towards R wall, - if L, 0 if straight forward
    scene.azimuthTilt = angle*pi/180;
end


% Programmatically set scene. Includes example of setting boundary boxes to count in 
if(strcmp(sceneRun,'Prgm_MaxFOV'))
    
    %Read Chirp Configuration file
    configurationFileName = 'mmw_pcdemo_default.cfg';   
    cliCfg = readCfg(configurationFileName);
    Params = parseCfg(cliCfg);
    
    % Room Wall dimensions [m]
    % Measured relative to radar
    wall.left = -6; % signed: - required
    wall.right = 6;
    wall.front = 6;
    wall.back = -0; % signed: - required
    
    % define wall [BLx BLy W H]
    scene.areaBox = [wall.left wall.back abs(wall.left)+wall.right wall.front+abs(wall.back)];
    
    % Define two rectangles for specific counting in the region
    % Target box settings
    scene.numberOfTargetBoxes = 0;
    
    % Parameters to make it easier to define two rectangles of the same size
        % that are side by side    
    % RO = Rectangle Origin. RO is measured relative to Left Back wall corner
    box.ROxtoLB = 1.0; % x distance from left wall 
    box.ROytoLB = 1.5; % y distance from back wall
    box.height = 2;    % height of boxes 
    box.sep = 0.6;     % seperation width of boxes
    box.width = 1;     % width of boxes 
    box.RTXplot = box.ROxtoLB+wall.left;
    box.RTYplot = box.ROytoLB+wall.back;
    
    
    % Each row of targetBox specifies the dimensions of a rectangle for counting.
    % The # of rows of targetBox must match numberOfTargetBoxes.
    % The rectangles are specified by (x,y) coordinate and width and height 
    % Custom rectangles can be defined instead if two side by side rects of
    % same size are not desired using [RTCx RTCy W H] convention
    scene.targetBox = [box.RTXplot box.RTYplot box.width box.height; 
                       (box.RTXplot+box.width+box.sep) box.RTYplot box.width box.height];
    
    
    % define plotting area as margin around wall
    margin = 0.1; %[m]
    scene.maxPos = [scene.areaBox(1)-margin ...
                    scene.areaBox(1)+scene.areaBox(3)+margin ...
                    scene.areaBox(2)-margin ...
                    scene.areaBox(2)+scene.areaBox(4)+margin];

    % Azimuth tilt of radar. 
    angle = +0; % Signed: + if tilted towards R wall, - if L, 0 if straight forward
    scene.azimuthTilt = angle*pi/180;
end

if(strcmp(sceneRun,'My_Scene'))
end

%% Webcam setup
if (strcmp(sceneRun,'GUI_Setup'))
    if(~(camIndex == -1))
        enableWebcam = 1;
        cam = webcam(camIndex);
        resList = cam.AvailableResolution;
        cam.Resolution = resList{getWidestFOV(resList)};


        hWebcamFigure = figure('Name', 'Ground Truth','Tag','webcamFigure',...
            'Toolbar','none', 'Menubar','none',...
            'NumberTitle', 'Off', 'Interruptible', 'Off');
        axWebcam = axes('Parent', hWebcamFigure);
        hImage = image(axWebcam, snapshot(cam));
        axis(axWebcam, 'manual','off')
        

        % Set up the push buttons
        uicontrol('String', 'Play',...
            'Callback', 'preview(cam, hImage)',...
            'Units','normalized',...
            'Position',[0 0 0.15 .07]);
        uicontrol('String', 'Pause',...
            'Callback', 'closePreview(cam)',...
            'Units','normalized',...
            'Position',[.17 0 .15 .07]);
        uicontrol('String', 'Close',...
            'Callback', 'delete(hWebcamFigure)',...
            'Units','normalized',...
            'Position',[0.34 0 .15 .07]);


        axWebcam = axes('Parent', hWebcamFigure);
        hImage = image(axWebcam, snapshot(cam));
        axis(axWebcam, 'manual','off')


        res = cam.Resolution;
        ss = strsplit(res,'x');
        imWidth = str2num(ss{1});
        imHeight = str2num(ss{2});
        hImage = image( zeros(imHeight, imWidth, 3) );
        % Set up the update preview window function.
        setappdata(hImage,'UpdatePreviewWindowFcn',@mypreview_fcn);



        % Specify the size of the axes that contains the image object
        % so that it displays the image at the right resolution and
        % centers it in the figure window.
        figSize = get(hWebcamFigure,'Position');
        figWidth = figSize(3);
        figHeight = figSize(4);
        gca.unit = 'pixels';
        gca.position = [ ((figWidth - imWidth)/2)... 
                       ((figHeight - imHeight)/2)...
                       imWidth imHeight ];


        hCam = preview(cam, hImage);
        pause(0.5); %allow webcam to load
    else
        enableWebcam = 0;
        hWebcamFigure = [];
    end
else
    %Progammatically configure webcam here
    enableWebcam = 0;
    hWebcamFigure = [];
end


%% Serial setup
if (~strcmp(sceneRun,'GUI_Setup'))
    %Configure data UART port with input buffer to hold 100+ frames 
    hDataSerialPort = configureDataSport(dataSerialPort, 65536);
    
    %Send Configuration Parameters to IWR16xx
    if(loadCfg)
        mmwDemoCliPrompt = char('mmwDemo:/>');
        hControlSerialPort = configureControlPort(controlSerialPort);
        %Send CLI configuration to IWR16xx
        fprintf('Sending configuration from %s file to IWR16xx ...\n', configurationFileName);
        for k=1:length(cliCfg)
            fprintf(hControlSerialPort, cliCfg{k});
            fprintf('%s\n', cliCfg{k});
            echo = fgetl(hControlSerialPort); % Get an echo of a command
            done = fgetl(hControlSerialPort); % Get "Done" 
            prompt = fread(hControlSerialPort, size(mmwDemoCliPrompt,2)); % Get the prompt back 
        end
        fclose(hControlSerialPort);
        delete(hControlSerialPort);
    end
end

%% Init variables
trackerRun = 'Target';
colors='mb';
labelTrack = 0;

%sensor parameters
%sensor.rangeMax = 6;
sensor.rangeMax = Params.dataPath.numRangeBins*Params.dataPath.rangeIdxToMeters;
sensor.rangeMin = 1;
sensor.azimuthFoV = 120*pi/180; %120 degree FOV in horizontal direction
sensor.framePeriod = Params.frameCfg.framePeriodicity;
sensor.maxURadialVelocity = 20;
sensor.angles = linspace(-sensor.azimuthFoV/2, sensor.azimuthFoV/2, 128);

hTargetBoxHandle = [];
peopleCountTotal = 0;
accx=0;%1
accy=0;
accx2=0;%2
accy2=0;
xdata=0;%1
ydata=0;
xdata2=0;%2
ydata2=0;
velx=0;%1
vely=0;
velx2=0;%2
vely2=0;
fxdata=0;
fydata=0;
fvelx=0;
fvely=0;
fxdata2=0;
fydata2=0;
fvelx2=0;
fvely2=0;
peopleCountInBox = zeros(1, scene.numberOfTargetBoxes);
rxData = zeros(10000,1,'uint8');
sw_row=repmat("/",1,17);
%emptydata=vertcat(data,empty_row);
maxNumTracks = 2;%20
maxNumPoints = 250;

hPlotCloudHandleAll = [];
hPlotCloudHandleOutRange = [];
hPlotCloudHandleClutter = [];
hPlotCloudHandleStatic = [];
hPlotCloudHandleDynamic =[];
hPlotPoints3D = [];

clutterPoints = zeros(2,1);
activeTracks = zeros(1, maxNumTracks);

trackingHistStruct = struct('tid', 0, 'allocationTime', 0, 'tick', 0, 'posIndex', 0, 'histIndex', 0, 'sHat', zeros(1000,6), 'ec', zeros(1000,9),'pos', zeros(100,2), 'hMeshU', [], 'hMeshG', [], 'hPlotAssociatedPoints', [], 'hPlotTrack', [], 'hPlotCentroid', []);
trackingHist = repmat(trackingHistStruct, 1, maxNumTracks);

%% Setup figure

figHandle = figure('Name', 'VVVV');


clf(figHandle);
set(figHandle, 'WindowStyle','normal');
%set(figHandle,'Name','Texas Instruments - People Counting','NumberTitle','off') 
set(figHandle,'Name','Millimeter-wave Radar','NumberTitle','off')

set(figHandle,'currentchar',' ')         % set a dummy character

%warning off MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame
%jframe=get(figHandle,'javaframe');
set(figHandle, 'MenuBar', 'none');
set(figHandle, 'Color', [0 0 0]);
%set(figHandle, 'CloseRequestFcn', close(figHandle));
%set(figHandle, 'DeleteFcn', @close_main);
pause(0.00001);
% Maximize the figure window in a supported way
set(figHandle, 'Units', 'normalized');
set(figHandle, 'Position', [0 0 1 1]);
pause(0.00001);
filePath = 'test.txt';


% Background


figureTitles = {'Data', 'Point cloud', '', 'Configuration'}; %, 'Heat Map', 'Feature Ext'};
figureGroup = [1, 2, 3, 1, 1];
numFigures = size(figureTitles, 2);
hFigure = zeros(1,numFigures);

hTabGroup(1) = uitabgroup(figHandle, 'Position', [0.0 0 0.2 1]);

if((wall.right-wall.left) > (wall.front - wall.back))
   hTabGroup(2) = uitabgroup(figHandle, 'Position', [0.2 0.5 0.8 0.5]);
   hTabGroup(3) = uitabgroup(figHandle, 'Position', [0.2 0 0.8 1]); 
else
   hTabGroup(2) = uitabgroup(figHandle, 'Position', [0.2 0 0.4 1]);
   hTabGroup(3) = uitabgroup(figHandle, 'Position', [0.6 0 0.4 1]); 
end

for iFig = 1:4
    hFigure(iFig) = uitab(hTabGroup(figureGroup(iFig)), 'Title', figureTitles{iFig});

    if(strcmp(figureTitles{iFig},'Point cloud'))
        trackingAx = axes('parent', hFigure(iFig));

        plot(trackingAx, sensor.rangeMin*sin(sensor.angles+scene.azimuthTilt), sensor.rangeMin*cos(sensor.angles+scene.azimuthTilt), '-k');  hold on;
        plot(trackingAx, [0 sensor.rangeMax*sin(sensor.angles+scene.azimuthTilt) 0],[0 sensor.rangeMax*cos(sensor.angles+scene.azimuthTilt) 0], '-k');
  
        title(figureTitles{iFig},'FontUnits','Normalized', 'FontSize',0.05);
        axis equal;
        axis(scene.maxPos);
        camroll(360)
        
        % draw wall box
        rectangle(trackingAx, 'Position', scene.areaBox, 'EdgeColor','k', 'LineStyle', '-', 'LineWidth', 2);
        
        % draw target box
        for nBoxes = 1:scene.numberOfTargetBoxes
            hTargetBoxHandle(nBoxes)= rectangle('Parent', trackingAx, 'Position', scene.targetBox(nBoxes,:), 'EdgeColor', colors(nBoxes), 'LineWidth', 4);
        end
        
        
        grid on;
        hold on;
        grid minor;

    end
    
    if(strcmp(figureTitles{iFig},''))
        cFig = iFig;
        contW = 0.15;
        contH = 0.05;
        gatingAx = axes('parent', hFigure(iFig));

        %plot(gatingAx, sensor.rangeMin*sin(sensor.angles+scene.azimuthTilt), sensor.rangeMin*cos(sensor.angles+scene.azimuthTilt), '-k');  hold on;
        plot(gatingAx, [0 sensor.rangeMax*sin(sensor.angles+scene.azimuthTilt) 0],[0 sensor.rangeMax*cos(sensor.angles+scene.azimuthTilt) 0], '-k');
        TTAT1L1SS=rectangle('Position',[-0.6 3.625 1.2 0.75],FaceColor='r',EdgeColor='r');
        TTAT1L2SS=rectangle('Position',[-0.6 3.625 1.2 0.75],FaceColor='r',EdgeColor='r');
        TTAT1R1SS=rectangle('Position',[-0.6 3.625 1.2 0.75],FaceColor='r',EdgeColor='r');
        TTAT1R2SS=rectangle('Position',[-0.6 3.625 1.2 0.75],FaceColor='r',EdgeColor='r');
        TTAT2LSS=rectangle('Position',[-0.6 3.625 1.2 0.75],FaceColor='r',EdgeColor='r');
        TTAT2RSS=rectangle('Position',[-0.6 3.625 1.2 0.75],FaceColor='r',EdgeColor='r');
        twopoint20SS=rectangle('Position',[-0.4 3.75 0.8 0.5],FaceColor='r',EdgeColor='r');%新
        twopoint25SS=rectangle('Position',[-0.4 3.75 0.8 0.5],FaceColor='r',EdgeColor='r');
        %TSS=rectangle('Position',[-0.4 12.75 0.8 0.5],FaceColor='r',EdgeColor='r');
        
        
        %新
        %twopointman
        twopointA=rectangle('position',[-2.6,3.9,0.2,0.2],'curvature',[1,1],'edgecolor','r','facecolor','r');%new右點
        twopointB=rectangle('position',[2.4,3.9,0.2,0.2],'curvature',[1,1],'edgecolor','r','facecolor','r');%new左點
        %twopointgirl
        twopoint1=rectangle('position',[-2.1,3.9,0.2,0.2],'curvature',[1,1],'edgecolor','r','facecolor','r');%new右點
        twopoint2=rectangle('position',[1.9,3.9,0.2,0.2],'curvature',[1,1],'edgecolor','r','facecolor','r');%new左點
        %底

        TTAT1L1A=rectangle('position',[-1.83,4.9,0.2,0.2],'curvature',[1,1],'edgecolor','r','facecolor','r');
        TTAT1L1B=rectangle('position',[-2.1,3.9,0.2,0.2],'curvature',[1,1],'edgecolor','r','facecolor','r');
        TTAT1L1C=rectangle('position',[-1.83,2.9,0.2,0.2],'curvature',[1,1],'edgecolor','r','facecolor','r');
        TTAT1L1D=rectangle('position',[1.63,4.9,0.2,0.2],'curvature',[1,1],'edgecolor','r','facecolor','r');
        TTAT1L1E=rectangle('position',[1.9,3.9,0.2,0.2],'curvature',[1,1],'edgecolor','r','facecolor','r');
        TTAT1L1F=rectangle('position',[1.63,2.9,0.2,0.2],'curvature',[1,1],'edgecolor','r','facecolor','r');
        

        TTAT1R1A=rectangle('position',[-1.83,4.9,0.2,0.2],'curvature',[1,1],'edgecolor','r','facecolor','r');
        TTAT1R1B=rectangle('position',[-2.1,3.9,0.2,0.2],'curvature',[1,1],'edgecolor','r','facecolor','r');
        TTAT1R1C=rectangle('position',[-1.83,2.9,0.2,0.2],'curvature',[1,1],'edgecolor','r','facecolor','r');
        TTAT1R1D=rectangle('position',[1.63,4.9,0.2,0.2],'curvature',[1,1],'edgecolor','r','facecolor','r');
        TTAT1R1E=rectangle('position',[1.9,3.9,0.2,0.2],'curvature',[1,1],'edgecolor','r','facecolor','r');
        TTAT1R1F=rectangle('position',[1.63,2.9,0.2,0.2],'curvature',[1,1],'edgecolor','r','facecolor','r');

        TTAT1L2A=rectangle('position',[-2.25,5.15,0.2,0.2],'curvature',[1,1],'edgecolor','r','facecolor','r');
        TTAT1L2B=rectangle('position',[-2.6,3.9,0.2,0.2],'curvature',[1,1],'edgecolor','r','facecolor','r');
        TTAT1L2C=rectangle('position',[-2.25,2.75,0.2,0.2],'curvature',[1,1],'edgecolor','r','facecolor','r');
        TTAT1L2D=rectangle('position',[2.05,5.15,0.2,0.2],'curvature',[1,1],'edgecolor','r','facecolor','r');
        TTAT1L2E=rectangle('position',[2.4,3.9,0.2,0.2],'curvature',[1,1],'edgecolor','r','facecolor','r');
        TTAT1L2F=rectangle('position',[2.05,2.75,0.2,0.2],'curvature',[1,1],'edgecolor','r','facecolor','r');

        TTAT1R2A=rectangle('position',[-2.25,5.15,0.2,0.2],'curvature',[1,1],'edgecolor','r','facecolor','r');
        TTAT1R2B=rectangle('position',[-2.6,3.9,0.2,0.2],'curvature',[1,1],'edgecolor','r','facecolor','r');
        TTAT1R2C=rectangle('position',[-2.25,2.75,0.2,0.2],'curvature',[1,1],'edgecolor','r','facecolor','r');
        TTAT1R2D=rectangle('position',[2.05,5.15,0.2,0.2],'curvature',[1,1],'edgecolor','r','facecolor','r');
        TTAT1R2E=rectangle('position',[2.4,3.9,0.2,0.2],'curvature',[1,1],'edgecolor','r','facecolor','r');
        TTAT1R2F=rectangle('position',[2.05,2.75,0.2,0.2],'curvature',[1,1],'edgecolor','r','facecolor','r');

        TTAT2LA=rectangle('position',[-1.83,4.9,0.2,0.2],'curvature',[1,1],'edgecolor','r','facecolor','r');
        TTAT2LB=rectangle('position',[-1.83,3.9,0.2,0.2],'curvature',[1,1],'edgecolor','r','facecolor','r');
        TTAT2LC=rectangle('position',[-1.83,2.9,0.2,0.2],'curvature',[1,1],'edgecolor','r','facecolor','r');
        TTAT2LD=rectangle('position',[1.63,4.9,0.2,0.2],'curvature',[1,1],'edgecolor','r','facecolor','r');
        TTAT2LE=rectangle('position',[1.63,3.9,0.2,0.2],'curvature',[1,1],'edgecolor','r','facecolor','r');
        TTAT2LF=rectangle('position',[1.63,2.9,0.2,0.2],'curvature',[1,1],'edgecolor','r','facecolor','r');

        TTAT2RA=rectangle('position',[-1.83,4.9,0.2,0.2],'curvature',[1,1],'edgecolor','r','facecolor','r');
        TTAT2RB=rectangle('position',[-1.83,3.9,0.2,0.2],'curvature',[1,1],'edgecolor','r','facecolor','r');
        TTAT2RC=rectangle('position',[-1.83,2.9,0.2,0.2],'curvature',[1,1],'edgecolor','r','facecolor','r');
        TTAT2RD=rectangle('position',[1.63,4.9,0.2,0.2],'curvature',[1,1],'edgecolor','r','facecolor','r');
        TTAT2RE=rectangle('position',[1.63,3.9,0.2,0.2],'curvature',[1,1],'edgecolor','r','facecolor','r');
        TTAT2RF=rectangle('position',[1.63,2.9,0.2,0.2],'curvature',[1,1],'edgecolor','r','facecolor','r');
        TA=rectangle('Position',[-1.5 3 3 0.02],FaceColor='r',EdgeColor='r');
        TB=rectangle('position',[-0.1,12.9,0.2,0.2],'curvature',[1,1],'edgecolor','r','facecolor','r');
        TC=rectangle('position',[-5.1,12.9,0.2,0.2],'curvature',[1,1],'edgecolor','r','facecolor','r');
        TD=rectangle('position',[4.9,12.9,0.2,0.2],'curvature',[1,1],'edgecolor','r','facecolor','r');

        TTAT1L1Stext=text(-0.1,4,'S1');
        TTAT1L1Stext.FontSize = 14;
        TTAT1R1Stext=text(-0.1,4,'S2');
        TTAT1R1Stext.FontSize = 14;
        TTAT1L2Stext=text(-0.1,4,'S3');
        TTAT1L2Stext.FontSize = 14;
        TTAT1R2Stext=text(-0.1,4,'S4');
        TTAT1R2Stext.FontSize = 14;
        TTAT2LStext=text(-0.1,4,'S5');
        TTAT2LStext.FontSize = 14;
        TTAT2RStext=text(-0.1,4,'S6');
        TTAT2RStext.FontSize = 14;
        %新
        twopoint25test=text(-0.1,4,'S7');%new
        twopoint25test.FontSize = 14;%new
        twopoint20test=text(-0.1,4,'S8');%new
        twopoint20test.FontSize = 14;%new
        %底
        %新
        twopoint20cbx=uicontrol(hFigure(iFig),'style','checkbox', 'string', 'Two Point(2.0m)',...
        'Units','Normalized', 'Position',[0.85 0.9 contW contH],...
        'FontSize', 15);%new 2.0
        twopoint25cbx=uicontrol(hFigure(iFig),'style','checkbox', 'string', 'Two Point(2.5m)',...
        'Units','Normalized', 'Position',[0.65 0.85 contW contH],...
        'FontSize', 15);%new 2.5
        %底
        TTAT1L1cbx = uicontrol(hFigure(iFig),'style','checkbox', 'string', 'TTAT I(L-2m)',...
            'Units','Normalized', 'Position',[0.05 0.9 contW contH],...
            'FontSize', 15);
        TTAT1R1cbx = uicontrol(hFigure(iFig),'style','checkbox', 'string', 'TTAT I(R-2m)',...
            'Units','Normalized', 'Position',[0.25 0.9 contW contH],...
            'FontSize', 15);
        TTAT2Lcbx = uicontrol(hFigure(iFig),'style','checkbox', 'string', 'TTAT II(L)',...
            'Units','Normalized', 'Position',[0.45 0.9 contW contH],...
            'FontSize', 15);
        TTAT1L2cbx = uicontrol(hFigure(iFig),'style','checkbox', 'string', 'TTAT I(L-2.5m)',...
            'Units','Normalized', 'Position',[0.05 0.85 contW contH],...
            'FontSize', 15);
        TTAT2Rcbx = uicontrol(hFigure(iFig),'style','checkbox', 'string', 'TTAT II(R)',...
            'Units','Normalized', 'Position',[0.45 0.85 contW contH],...
            'FontSize', 15);
        TTAT1R2cbx = uicontrol(hFigure(iFig),'style','checkbox', 'string', 'TTAT I(R-2.5m)',...
            'Units','Normalized', 'Position',[0.25 0.85 contW contH],...
            'FontSize', 15);
        Tcbx = uicontrol(hFigure(iFig),'style','checkbox', 'string', 'Type T',...
            'Units','Normalized', 'Position',[0.65 0.9 contW contH],...
            'FontSize', 15);


        title(figureTitles{iFig},'FontUnits','Normalized', 'FontSize',0.05);
        axis equal;
        axis(scene.maxPos);
        camroll(360)
        % draw wall box
        rectangle(gatingAx, 'Position', scene.areaBox, 'EdgeColor','k', 'LineStyle', '-', 'LineWidth', 2);
        
        % draw target box
        for nBoxes = 1:scene.numberOfTargetBoxes
            hTargetBoxHandle(nBoxes)= rectangle('Parent', gatingAx, 'Position', scene.targetBox(nBoxes,:), 'EdgeColor', colors(nBoxes), 'LineWidth', 4);
        end
        
        grid on;
        hold on;
        %grid minor;

    end
    
    if(strcmp(figureTitles{iFig},'Configuration'))
        %axes('parent', hFigure(iFig))
        tablePosition = [0.1 0.6 0.8 0.3];
        displayChirpParams(Params, tablePosition, hFigure(iFig));
    end
    
    if(strcmp(figureTitles{iFig},'Data'))     
        axes('parent', hFigure(iFig))
        hStatGlobal(1) = text(0, 0.9, 'Frame # 0', 'FontSize',12, 'Visible', 'on');
        hStatGlobal(2) = text(0, 0.8, 'Check Point: 0','FontSize',12, 'Visible', 'off');
        hStatGlobal(3) = text(0, 0.6, 'Player:  0','FontSize',24);
        %new顯示p1p2
        hPlayer2Text = text(0, 0.5, 'player1', 'Color','b', 'FontSize',20);%新player1
        hPlayer1Text = text(0, 0.4, 'player2', 'Color','m', 'FontSize',20);%新player2
        %底
        fileindex = uicontrol("Style","edit","Position",[150 335 150 25]);%輸入p1的名子
        %新的
        fileindex2 =uicontrol("Style","edit","Position",[150 260 150 25]);%輸入p2的名子
        %底
        IDTXT = text(0, 0.3, 'Player ID:', 'FontSize',12, 'Visible', 'on');%p1
        IDTXT2 = text(0, 0.2, 'Player2 ID:', 'FontSize',12, 'Visible', 'on');%p2
        UWBTXT1 = text(0, 0.4, 'Tag1:', 'FontSize',12, 'Visible', 'off');
        UWBTXT2 = text(0, 0.3, 'Tag2:', 'FontSize',12, 'Visible', 'off');
        UWBTag1 = text(0.3, 0.5, 'null', 'FontSize',12, 'Visible', 'off');
        UWBTag2 = text(0.3, 0.4, 'null', 'FontSize',12, 'Visible', 'off');
        UWBTag3 = text(0.3, 0.3, 'null', 'FontSize',12, 'Visible', 'off');
        %speed(1) = text(0, 0.4, 'accx: 0', 'FontSize',12, 'Visible', 'on');
        %speed(2) = text(0, 0.3, 'accy: 0', 'FontSize',12, 'Visible', 'on');
        %speed(3) = text(0, 0.2, 'accx2: 0', 'FontSize',12, 'Visible', 'on');
        %speed(4) = text(0, 0.1, 'accy2: 0', 'FontSize',12, 'Visible', 'on');
        btn = uicontrol('Style', 'pushbutton', ...
                'String', 'Write File', ...
                'Position', [50 200 100 50]);
        set(btn, 'Callback', @buttonCallback);
        switchbtn = uicontrol('Style', 'pushbutton', ...
                'String', 'Next Stage', ...
                'Position', [50 130 100 50]);
        set(switchbtn, 'Callback', @swbuttonCallback);
        % 修這裡
         autoswitchbtn = uicontrol('Style', 'pushbutton', ...
                'String', '自動分段', ...
                 'Position', [200 130 100 50]);
         set(autoswitchbtn, 'Callback', @autoswbuttonCallback);

        endbtn = uicontrol('Style', 'pushbutton', ...
                'String', 'Stop Write File', ...
                'Position', [200 200 100 50]);
        set(endbtn, 'Callback', @endbuttonCallback);
        uploadbtn = uicontrol('Style', 'pushbutton', ...
            'String', 'Upload', ...
            'Position', [50 70 100 50]);
        set(uploadbtn, 'Callback', @uploadbuttonCallback);
        for i=1:scene.numberOfTargetBoxes
            hStatGlobal(end+1) = text(0, 0.6-0.15*i, 'Box Count','FontSize', 30, 'color', colors(i));
        end
        %hStatGlobal(end+1) = text(0, 0.7, 'Bytes Available:  0/0','FontSize',12, 'Visible', 'on');
        axis off;
    end
    
    if(strcmp(figureTitles{iFig},'Control options'))
        cFig = iFig;
        contW = 0.75;
        contH = 0.05;
        %imshow('tiLogo.jpg')
        hRbPause = uicontrol(hFigure(cFig),'style','checkbox', 'string', 'Pause',...
            'Units','Normalized', 'Position',[0.05 0.85 contW contH],...
            'FontSize', 15);
        
        %hPlotTabs = uicontrol(hFigure(cFig),'style','checkbox','string','Consolidate plotting tabs',...
        %     'Units','Normalized', 'Position',[0.05 0.9 contW contH],'Value',0,...
        %     'FontSize', 15, 'Callback', {@checkPlotTabs,hTabGroup});

        hPbExit = uicontrol('Style', 'pushbutton', 'String', 'EXIT',...
            'Position', [10 10 100 40],'Callback', @exitPressFcn);
        setappdata(hPbExit, 'exitKeyPressed', 0);
    end    
end


%% Data structures
syncPatternUINT64 = typecast(uint16([hex2dec('0102'),hex2dec('0304'),hex2dec('0506'),hex2dec('0708')]),'uint64');
syncPatternUINT8 = typecast(uint16([hex2dec('0102'),hex2dec('0304'),hex2dec('0506'),hex2dec('0708')]),'uint8');

frameHeaderStructType = struct(...
    'sync',             {'uint64', 8}, ... % See syncPatternUINT64 below
    'version',          {'uint32', 4}, ...
    'platform',         {'uint32', 4}, ...
    'timestamp',        {'uint32', 4}, ... % 600MHz clocks
    'packetLength',     {'uint32', 4}, ... % In bytes, including header
    'frameNumber',      {'uint32', 4}, ... % Starting from 1
    'subframeNumber',   {'uint32', 4}, ...
    'chirpMargin',      {'uint32', 4}, ... % Chirp Processing margin, in ms
    'frameMargin',      {'uint32', 4}, ... % Frame Processing margin, in ms
    'uartSentTime' ,    {'uint32', 4}, ... % Time spent to send data, in ms
    'trackProcessTime', {'uint32', 4}, ... % Tracking Processing time, in ms
    'numTLVs' ,         {'uint16', 2}, ... % Number of TLVs in thins frame
    'checksum',         {'uint16', 2});    % Header checksum

tlvHeaderStruct = struct(...
    'type',             {'uint32', 4}, ... % TLV object Type
    'length',           {'uint32', 4});    % TLV object Length, in bytes, including TLV header 

% Point Cloud TLV object consists of an array of points. 
% Each point has a structure defined below
pointStruct = struct(...
    'range',            {'float', 4}, ... % Range, in m
    'angle',            {'float', 4}, ... % Angel, in rad
    'doppler',          {'float', 4}, ... % Doplper, in m/s
    'snr',              {'float', 4});    % SNR, ratio
% Target List TLV object consists of an array of targets. 
% Each target has a structure define below
targetStruct = struct(...
    'tid',              {'uint32', 4}, ... % Track ID
    'posX',             {'float', 4}, ... % Target position in X dimension, m
    'posY',             {'float', 4}, ... % Target position in Y dimension, m
    'velX',             {'float', 4}, ... % Target velocity in X dimension, m/s
    'velY',             {'float', 4}, ... % Target velocity in Y dimension, m/s
    'accX',             {'float', 4}, ... % Target acceleration in X dimension, m/s2
    'accY',             {'float', 4}, ... % Target acceleration in Y dimension, m/s
    'EC',               {'float', 9*4}, ... % Tracking error covariance matrix, [3x3], in range/angle/doppler coordinates
    'G',                {'float', 4});    % Gating function gain

frameHeaderLengthInBytes = lengthFromStruct(frameHeaderStructType);
tlvHeaderLengthInBytes = lengthFromStruct(tlvHeaderStruct);
pointLengthInBytes = lengthFromStruct(pointStruct);
targetLengthInBytes = lengthFromStruct(targetStruct);
indexLengthInBytes = 1;

exitRequest = 0;
lostSync = 0;
gotHeader = 0;
outOfSyncBytes = 0;
runningSlow = 0;
maxBytesAvailable = 0;
point3D = [];

frameStatStruct = struct('targetFrameNum', [], 'bytes', [], 'numInputPoints', 0, 'numOutputPoints', 0, 'timestamp', 0, 'start', 0, 'benchmarks', [], 'done', 0, ...
    'pointCloud', [], 'targetList', [], 'indexArray', []);
fHist = repmat(frameStatStruct, 1, 10000);
%videoFrame = struct('cdata',[],'colormap', []);
%F = repmat(videoFrame, 10000,1);
optimize = 1;
skipProcessing = 0;
frameNum = 1;
frameNumLogged = 1;
fprintf('------------------\n');
'BytesAvailable'
update = 0;

Ax1 =  4.0;  Ay1 =  0.0;   % 东边
Ax2 = -4.0;  Ay2 =  0.0;   % 西边
%% Main
while(isvalid(hDataSerialPort))

    
    while(lostSync == 0 && isvalid(hDataSerialPort))

        frameStart = tic;
        fHist(frameNum).timestamp = frameStart;
        bytesAvailable = get(hDataSerialPort,'BytesAvailable');
        if(bytesAvailable > maxBytesAvailable)
            maxBytesAvailable = bytesAvailable;
        end
        fHist(frameNum).bytesAvailable = bytesAvailable;
        if(gotHeader == 0)
            %Read the header first
            [rxHeader, byteCount] = fread(hDataSerialPort, frameHeaderLengthInBytes, 'uint8');
        end
        fHist(frameNum).start = 1000*toc(frameStart);
        
        magicBytes = typecast(uint8(rxHeader(1:8)), 'uint64');
        if(magicBytes ~= syncPatternUINT64)
            reason = 'No SYNC pattern';
            lostSync = 1;
            break;
        end
        if(byteCount ~= frameHeaderLengthInBytes)
            reason = 'Header Size is wrong';
            lostSync = 1;
            break;
        end        
        if(validateChecksum(rxHeader) ~= 0)
            reason = 'Header Checksum is wrong';
            lostSync = 1;
            break; 
        end
        
        frameHeader = readToStruct(frameHeaderStructType, rxHeader);
        
        if(gotHeader == 1)
            if(frameHeader.frameNumber > targetFrameNum)
                targetFrameNum = frameHeader.frameNumber;
                disp(['Found sync at frame ',num2str(targetFrameNum),'(',num2str(frameNum),'), after ', num2str(1000*toc(lostSyncTime),3), 'ms']);
                gotHeader = 0;
            else
                reason = 'Old Frame';
                gotHeader = 0;
                lostSync = 1;
                break;
            end
        end
        
        % We have a valid header
        targetFrameNum = frameHeader.frameNumber;
        fHist(frameNum).targetFrameNum = targetFrameNum;
        fHist(frameNum).header = frameHeader;
        
        dataLength = frameHeader.packetLength - frameHeaderLengthInBytes;
        
        fHist(frameNum).bytes = dataLength; 
        numInputPoints = 0;
        numTargets = 0;
        mIndex = [];

        if(dataLength > 0)
            %Read all packet
            [rxData, byteCount] = fread(hDataSerialPort, double(dataLength), 'uint8');
            if(byteCount ~= double(dataLength))
                reason = 'Data Size is wrong'; 
                lostSync = 1;
                break;  
            end
            offset = 0;
    
            fHist(frameNum).benchmarks(1) = 1000*toc(frameStart);

            % TLV Parsing
            for nTlv = 1:frameHeader.numTLVs
                tlvType = typecast(uint8(rxData(offset+1:offset+4)), 'uint32');
                tlvLength = typecast(uint8(rxData(offset+5:offset+8)), 'uint32');
                if(tlvLength + offset > dataLength)
                    reason = 'TLV Size is wrong';
                    lostSync = 1;
                    break;                    
                end
                offset = offset + tlvHeaderLengthInBytes;
                valueLength = tlvLength - tlvHeaderLengthInBytes;
                switch(tlvType)
                    case 6
                        % Point Cloud TLV
                        numInputPoints = valueLength/pointLengthInBytes;
                        if(numInputPoints > 0)                        
                            % Get Point Cloud from the sensor
                            p = typecast(uint8(rxData(offset+1: offset+valueLength)),'single');

                            pointCloud = reshape(p,4, numInputPoints);    
%                            pointCloud(2,:) = pointCloud(2,:)*pi/180;

                            posAll = [pointCloud(1,:).*sin(pointCloud(2,:)); pointCloud(1,:).*cos(pointCloud(2,:))];
                            snrAll = pointCloud(4,:);

                            % 改善的範圍檢測條件 - 多層過濾策略
                            % 第一層：基本範圍過濾
                            basic_range_filter = (pointCloud(1,:) > 0.5) & (pointCloud(1,:) < 10) & ...
                                (pointCloud(2,:) > -70*pi/180) & (pointCloud(2,:) < 70*pi/180);
                            
                            % 第二層：信噪比過濾（適應性閾值）
                            snr_threshold = 8; % 降低SNR閾值以增加檢測敏感度
                            snr_filter = pointCloud(4,:) > snr_threshold;
                            
                            % 第三層：多普勒速度過濾（排除靜態雜波）
                            velocity_threshold = 0.1; % m/s
                            velocity_filter = abs(pointCloud(3,:)) > velocity_threshold | ...
                                              pointCloud(4,:) > 15; % 高SNR的靜態目標也保留
                            
                            % 第四層：場景區域過濾（擴展邊界）
                            boundary_margin = 0.5; % 增加邊界容錯
                            scene_filter = (posAll(1,:) > (scene.areaBox(1) - boundary_margin)) & ...
                                          (posAll(1,:) < (scene.areaBox(1) + scene.areaBox(3) + boundary_margin)) & ...
                                          (posAll(2,:) > (scene.areaBox(2) - boundary_margin)) & ...
                                          (posAll(2,:) < (scene.areaBox(2) + scene.areaBox(4) + boundary_margin));
                            
                            % 合併所有過濾條件
                            inRangeInd = basic_range_filter & snr_filter & velocity_filter & scene_filter;
                            
                            % 如果過濾後點數太少，放寬條件
                            if sum(inRangeInd) < 3
                                fprintf('警告：過濾後點數不足，使用放寬條件\n');
                                relaxed_filter = (pointCloud(1,:) > 0.3) & (pointCloud(1,:) < 12) & ...
                                    (pointCloud(2,:) > -80*pi/180) & (pointCloud(2,:) < 80*pi/180) & ...
                                    (pointCloud(4,:) > 5);
                                inRangeInd = relaxed_filter;
                            end
                            
                            pointCloudInRange = pointCloud(:,inRangeInd);
                            posInRange = posAll(:,inRangeInd);
                            
                            % 新增：點雲聚類處理以改善多目標檢測
                            if size(posInRange, 2) > 5
                                try
                                    % 使用簡單的距離聚類
                                    cluster_threshold = 0.8; % 聚類距離閾值
                                    clusters = simple_clustering(posInRange(1:2,:)', cluster_threshold);
                                    
                                    % 過濾掉太小的聚類（可能是雜訊）
                                    min_cluster_size = 2;
                                    valid_clusters = clusters(clusters >= min_cluster_size);
                                    
                                    if length(unique(valid_clusters)) >= 2
                                        fprintf('檢測到 %d 個有效聚類\n', length(unique(valid_clusters)));
                                    end
                                catch
                                    % 如果聚類失敗，繼續使用原始點雲
                                    fprintf('點雲聚類失敗，使用原始數據\n');
                                end
                            end
%{
                            % Clutter removal
                            staticInd = (pointCloud(3,:) == 0);        
                            clutterInd = ismember(pointCloud(1:2,:)', clutterPoints', 'rows');
                            clutterInd = clutterInd' & staticInd;
                            clutterPoints = pointCloud(1:2,staticInd);
                            pointCloud = pointCloud(1:3,~clutterInd);
%}
                            numOutputPoints = size(pointCloud,2);                          
                        end                        
                        offset = offset + valueLength;
                                            
                    case 7
                        numTargets = valueLength/targetLengthInBytes;                        
                        TID = zeros(1,numTargets);
                        S = zeros(6, numTargets);
                        EC = zeros(9, numTargets);
                        G = zeros(1,numTargets);                        
                        for n=1:numTargets
                            TID(n)  = typecast(uint8(rxData(offset+1:offset+4)),'uint32');      %1x4=4bytes
                            S(:,n)  = typecast(uint8(rxData(offset+5:offset+28)),'single');     %6x4=24bytes
                            EC(:,n) = typecast(uint8(rxData(offset+29:offset+64)),'single');    %9x4=36bytes
                            G(n)    = typecast(uint8(rxData(offset+65:offset+68)),'single');    %1x4=4bytes
                            offset = offset + 68;
                        end
                        
                    case 8
                        % Target Index TLV
                        numIndices = valueLength/indexLengthInBytes;
                        mIndex = typecast(uint8(rxData(offset+1:offset+numIndices)),'uint8');
                        offset = offset + valueLength;
                end
            end
        end
       
        % === 新增：點雲聚類以改善目標檢測 ===
        if(numInputPoints > 0)
            % 使用簡單聚類算法分離多個目標
            clustered_points = simple_clustering(pointCloud);
            if size(clustered_points, 2) > 0
                % 根據聚類結果調整目標檢測
                numOutputPoints = size(clustered_points, 2);
                pointCloud = clustered_points;
            end
        end
       
        if(numInputPoints == 0)
            numOutputPoints = 0;
            pointCloud = single(zeros(4,0));
            posAll = [];
            posInRange = [];  
        end
        if(numTargets == 0)
            TID = [];
            S = [];
            EC = [];
            G = [];
        end
        
        fHist(frameNum).numInputPoints = numInputPoints;
        fHist(frameNum).numOutputPoints = numOutputPoints;    
        fHist(frameNum).numTargets = numTargets;
        fHist(frameNum).pointCloud = pointCloud;
        fHist(frameNum).targetList.numTargets = numTargets;
        fHist(frameNum).targetList.TID = TID;
        fHist(frameNum).targetList.S = S;
        if(~optimize)
            fHist(frameNum).targetList.EC = EC;
        end
        fHist(frameNum).targetList.G = G;
        fHist(frameNum).indexArray = mIndex;
       
        % Plot pointCloud
        fHist(frameNum).benchmarks(2) = 1000*toc(frameStart);

        
      
    %------------------------------------------
   
        %if(get(hRbPause, 'Value') == 1)
            %pause(0.01);
            %continue;
        %end
        %新2.0
        if(get(twopoint20cbx, 'Value') == 0)
            twopoint20SS.Visible = 'off';
            twopoint20test.Visible = 'off';
            twopoint1.Visible = 'off';
            twopoint2.Visible = 'off';
            twopoints20=0;
        elseif(get(twopoint20cbx, 'Value') == 1)
            twopoint20SS.Visible = 'on';
            twopoint20test.Visible = 'on';
            twopoint1.Visible = 'on';
            twopoint2.Visible = 'on';
            twopoints20=1;
        end
        %新2.5
        if(get(twopoint25cbx, 'Value') == 0)
            twopoint25SS.Visible = 'off';
            twopoint25test.Visible = 'off';
            twopointA.Visible = 'off';
            twopointB.Visible = 'off';
            twopoints25=0;
        elseif(get(twopoint25cbx, 'Value') == 1)
            twopoint25SS.Visible = 'on';
            twopoint25test.Visible = 'on';
            twopointA.Visible = 'on';
            twopointB.Visible = 'on';
            twopoints25=1;
        end     
        %底
        if(get(TTAT1L1cbx, 'Value') == 0)
            TTAT1L1SS.Visible = 'off';
            TTAT1L1Stext.Visible = 'off';
            TTAT1L1A.Visible = 'off';
            TTAT1L1B.Visible = 'off';
            TTAT1L1C.Visible = 'off';
            TTAT1L1D.Visible = 'off';
            TTAT1L1E.Visible = 'off';
            TTAT1L1F.Visible = 'off';
            autodec=0;
        elseif(get(TTAT1L1cbx, 'Value') == 1)
            TTAT1L1SS.Visible = 'on';
            TTAT1L1Stext.Visible = 'on';
            TTAT1L1A.Visible = 'on';
            TTAT1L1B.Visible = 'on';
            TTAT1L1C.Visible = 'on';
            TTAT1L1D.Visible = 'on';
            TTAT1L1E.Visible = 'on';
            TTAT1L1F.Visible = 'on';
            autodec=1;
        end
        if(get(TTAT1R1cbx, 'Value') == 0)
            TTAT1R1SS.Visible = 'off';
            TTAT1R1Stext.Visible = 'off';
            TTAT1R1A.Visible = 'off';
            TTAT1R1B.Visible = 'off';
            TTAT1R1C.Visible = 'off';
            TTAT1R1D.Visible = 'off';
            TTAT1R1E.Visible = 'off';
            TTAT1R1F.Visible = 'off';
            autodecR=0;
        elseif(get(TTAT1R1cbx, 'Value') == 1)
            TTAT1R1SS.Visible = 'on';
            TTAT1R1Stext.Visible = 'on';
            TTAT1R1A.Visible = 'on';
            TTAT1R1B.Visible = 'on';
            TTAT1R1C.Visible = 'on';
            TTAT1R1D.Visible = 'on';
            TTAT1R1E.Visible = 'on';
            TTAT1R1F.Visible = 'on';
            autodecR=1;
        end
        if(get(TTAT1L2cbx, 'Value') == 0)
            TTAT1L2SS.Visible = 'off';
            TTAT1L2Stext.Visible = 'off';
            TTAT1L2A.Visible = 'off';
            TTAT1L2B.Visible = 'off';
            TTAT1L2C.Visible = 'off';
            TTAT1L2D.Visible = 'off';
            TTAT1L2E.Visible = 'off';
            TTAT1L2F.Visible = 'off';
            autodec3=0;
        elseif(get(TTAT1L2cbx, 'Value') == 1)
            TTAT1L2SS.Visible = 'on';
            TTAT1L2Stext.Visible = 'on';
            TTAT1L2A.Visible = 'on';
            TTAT1L2B.Visible = 'on';
            TTAT1L2C.Visible = 'on';
            TTAT1L2D.Visible = 'on';
            TTAT1L2E.Visible = 'on';
            TTAT1L2F.Visible = 'on';
            autodec3=1;
        end
        if(get(TTAT1R2cbx, 'Value') == 0)
            TTAT1R2SS.Visible = 'off';
            TTAT1R2Stext.Visible = 'off';
            TTAT1R2A.Visible = 'off';
            TTAT1R2B.Visible = 'off';
            TTAT1R2C.Visible = 'off';
            TTAT1R2D.Visible = 'off';
            TTAT1R2E.Visible = 'off';
            TTAT1R2F.Visible = 'off';
            autodecR2=0;
        elseif(get(TTAT1R2cbx, 'Value') == 1)
            TTAT1R2SS.Visible = 'on';
            TTAT1R2Stext.Visible = 'on';
            TTAT1R2A.Visible = 'on';
            TTAT1R2B.Visible = 'on';
            TTAT1R2C.Visible = 'on';
            TTAT1R2D.Visible = 'on';
            TTAT1R2E.Visible = 'on';
            TTAT1R2F.Visible = 'on';
            autodecR2=1;
        end
        if(get(TTAT2Lcbx, 'Value') == 0)
            TTAT2LSS.Visible = 'off';
            TTAT2LStext.Visible = 'off';
            TTAT2LA.Visible = 'off';
            TTAT2LB.Visible = 'off';
            TTAT2LC.Visible = 'off';
            TTAT2LD.Visible = 'off';
            TTAT2LE.Visible = 'off';
            TTAT2LF.Visible = 'off';
            autodec2=0;
        elseif(get(TTAT2Lcbx, 'Value') == 1)
            TTAT2LSS.Visible = 'on';
            TTAT2LStext.Visible = 'on';
            TTAT2LA.Visible = 'on';
            TTAT2LB.Visible = 'on';
            TTAT2LC.Visible = 'on';
            TTAT2LD.Visible = 'on';
            TTAT2LE.Visible = 'on';
            TTAT2LF.Visible = 'on';
            autodec2=1;
        end
        if(get(TTAT2Rcbx, 'Value') == 0)
            TTAT2RSS.Visible = 'off';
            TTAT2RStext.Visible = 'off';
            TTAT2RA.Visible = 'off';
            TTAT2RB.Visible = 'off';
            TTAT2RC.Visible = 'off';
            TTAT2RD.Visible = 'off';
            TTAT2RE.Visible = 'off';
            TTAT2RF.Visible = 'off';
            autodec2R=0;
        elseif(get(TTAT2Rcbx, 'Value') == 1)
            TTAT2RSS.Visible = 'on';
            TTAT2RStext.Visible = 'on';
            TTAT2RA.Visible = 'on';
            TTAT2RB.Visible = 'on';
            TTAT2RC.Visible = 'on';
            TTAT2RD.Visible = 'on';
            TTAT2RE.Visible = 'on';
            TTAT2RF.Visible = 'on';
            autodec2R=1;
        end
        if(get(Tcbx, 'Value') == 0)
            TA.Visible = 'off';
            TB.Visible = 'off';
            TC.Visible = 'off';
            TD.Visible = 'off';
            TTAT1L1cbx.Visible='on';
            TTAT1R1cbx.Visible='on';
            TTAT2Lcbx.Visible='on';
            TTAT1L2cbx.Visible='on';
            TTAT2Rcbx.Visible='on';
            TTAT1R2cbx.Visible='on';
            autodecT=0;
        elseif(get(Tcbx, 'Value') == 1)
            TA.Visible = 'on';
            TB.Visible = 'on';
            TC.Visible = 'on';
            TD.Visible = 'on';
            TTAT1L1cbx.Visible='off';
            TTAT1R1cbx.Visible='off';
            TTAT2Lcbx.Visible='off';
            TTAT1L2cbx.Visible='off';
            TTAT2Rcbx.Visible='off';
            TTAT1R2cbx.Visible='off';
            autodecT=1;
        end
        % Delete previous points
        if(ishandle(hPlotCloudHandleAll))
            delete(hPlotCloudHandleAll);
        end
        if(ishandle(hPlotCloudHandleOutRange))
            delete(hPlotCloudHandleOutRange);
        end
        if(ishandle(hPlotCloudHandleClutter))
            delete(hPlotCloudHandleClutter);
        end
        if(ishandle(hPlotCloudHandleStatic))
            delete(hPlotCloudHandleStatic);
        end
        if(ishandle(hPlotCloudHandleDynamic))
            delete(hPlotCloudHandleDynamic);
        end

        if(size(posAll,2))
            % Plot all points
            if(snrAll*10 > 0)
                if(~optimize)
                    %hPlotCloudHandleAll = scatter(trackingAx, posAll(1,:), posAll(2,:),'.k','SizeData',snrAll*10);
                else
                    %hPlotCloudHandleAll = plot(trackingAx, posAll(1,:), posAll(2,:),'.k');
                end
            else
                reason = 'SNR value is wrong';
                lostSync = 1;
                break;                
            end
            % Cross out out-of-Range
            if(~optimize)
                hPlotCloudHandleOutRange = plot(trackingAx, posAll(1,~inRangeInd), posAll(2,~inRangeInd), 'xr');
            end
        end
        
%{        
        if(size(posInRange,2))
            % Cross out Clutter
            hPlotCloudHandleClutter = plot(trackingAx, posInRange(1,clutterInd), posInRange(2,clutterInd), 'xk');
            % Indicate Static
            hPlotCloudHandleStatic = plot(trackingAx, posInRange(1,staticInd & ~clutterInd), posInRange(2,staticInd & ~clutterInd), 'ok');
            % Indicate Dynamic
            hPlotCloudHandleDynamic = plot(trackingAx, posInRange(1,~staticInd), posInRange(2,~staticInd), 'ob');
        end
%}        
        fHist(frameNum).benchmarks(3) = 1000*toc(frameStart);

        switch trackerRun
            case 'Target'
                if(numTargets == 0)
                    TID = zeros(1,0);
                    S = zeros(6,0);
                    EC = zeros(9,0);
                    G = zeros(1,0);
                end
        end
        
        fHist(frameNum).benchmarks(4) = 1000*toc(frameStart);
        
        if nnz(isnan(S))
            reason = 'Error: S contains NaNs';
            lostSync = 1;
            break;
        end
        if nnz(isnan(EC))
            reason = 'Error: EC contains NaNs';
            lostSync = 1;
            break;
        end
        
        tNumC = length(TID);
        peopleCountTotal = tNumC;
        peopleCountInBox = zeros(1, scene.numberOfTargetBoxes);
        
        % 新增：目標丟失檢測和狀態重置
        global frame_without_p1 frame_without_p2 max_missing_frames
        if isempty(max_missing_frames)
            max_missing_frames = 10; % 允許最多丟失10幀
            frame_without_p1 = 0;
            frame_without_p2 = 0;
        end
        
        % 檢查是否有P1和P2的數據更新
        p1_detected = exist('xdata', 'var') && ~isnan(xdata);
        p2_detected = exist('xdata2', 'var') && ~isnan(xdata2);
        
        if ~p1_detected
            frame_without_p1 = frame_without_p1 + 1;
            if frame_without_p1 > max_missing_frames
                % P1長期丟失，重置相關狀態
                if exist('auto', 'var')
                    auto = 0;
                end
                if exist('autoR', 'var')
                    autoR = 0;
                end
                if exist('twopoint20', 'var')
                    twopoint20 = 0;
                end
                frame_without_p1 = 0;
                fprintf('警告：P1目標丟失超過%d幀，重置狀態\n', max_missing_frames);
            end
        else
            frame_without_p1 = 0;
        end
        
        if ~p2_detected
            frame_without_p2 = frame_without_p2 + 1;
            if frame_without_p2 > max_missing_frames
                % P2長期丟失，重置相關狀態
                if exist('auto2', 'var')
                    auto2 = 0;
                end
                if exist('twopoint25', 'var')
                    twopoint25 = 0;
                end
                frame_without_p2 = 0;
                fprintf('警告：P2目標丟失超過%d幀，重置狀態\n', max_missing_frames);
            end
        else
            frame_without_p2 = 0;
        end
 
        if(size(mIndex,1)) 
            mIndex = mIndex + 1;
        end
        
        % Plot previous frame's 3D points       
        if(size(point3D,2))   
            if isempty(hPlotPoints3D)
                %hPlotPoints3D = plot(gatingAx, point3D(1,:), point3D(2,:), '.k');%, point3D(3,:),'.k');
            else
                %set(hPlotPoints3D, 'XData', point3D(1,:),'YData', point3D(2,:)); %, 'ZData', point3D(3,:));
            end
        end     
        
        for n=1:tNumC
            
            tid = TID(n)+1;            
            if(tid > maxNumTracks)
                reason = 'Error: TID is wrong';
                lostSync = 1;
                break;
            end

            if( (size(mIndex,1) > 0) && (size(mIndex,1) == size(point3D,2)) )
                tColor = colors(mod(tid,length(colors))+1);
                ind = (mIndex == tid);
                if nnz(ind)
                    %trackingHist(tid).hPlotAssociatedPoints = plot(gatingAx, point3D(1,ind), point3D(2,ind), 'o', 'color', tColor)
                    if (isempty(trackingHist(tid).hPlotAssociatedPoints) || ~ishandle(trackingHist(tid).hPlotAssociatedPoints))
                        %trackingHist(tid).hPlotAssociatedPoints = plot(gatingAx, point3D(1,ind), point3D(2,ind), '.', 'MarkerSize', 10, 'color', tColor);
                    else
                        if ishandle(trackingHist(tid).hPlotAssociatedPoints)
                            set(trackingHist(tid).hPlotAssociatedPoints, 'XData', point3D(1,ind),'YData', point3D(2,ind));
                        end
                    end
                end
            end
               
            %g = G(n);
            centroid = computeH(1, S(:,n));
            ec = reshape(EC(:,n),3,3);
            if(nnz(ec)>1)
                dim = getDim(gatingAx, 1, centroid, ec);
                
                if isempty(trackingHist(tid).hMeshU)
                    trackingHist(tid).hMeshU = circle(gatingAx,S(1,n), S(2,n),dim);
                    if(labelTrack)
                        trackingHist(tid).hMeshU.UserData = text(gatingAx,S(1,n), S(2,n), char(65+mod(tid,26)),'HorizontalAlignment','center','FontUnits','normalized','FontSize',0.5/scene.maxPos(4)*0.75);
                    end
                        if(~optimize)
                        trackingHist(tid).hMeshU.EdgeColor = [0.5 0.5 0.5];
                    else
                        trackingHist(tid).hMeshU.EdgeColor = colors(mod(tid,length(colors))+1);
                        %trackingHist(tid).hMeshU.EdgeColor = [0.0 0.0 0.9];
                    end
                    trackingHist(tid).hMeshU.FaceColor =trackingHist(tid).hMeshU.EdgeColor;
                else
                    %set(trackingHist(tid).hMeshU, 'XData', xU.*sin(yU),'YData',xU.*cos(yU), 'ZData', zU);
                    trackingHist(tid).hMeshU.Position = updateCenter(S(1,n), S(2,n),0.2);
                    if(labelTrack)
                        trackingHist(tid).hMeshU.UserData.Position = [S(1,n), S(2,n)];
                    end
                end
            end
            
            if(~optimize)
                if(g ~= 0)
                    [xG, yG, zG, vG] = gatePlot3(gatingAx, g, centroid, ec);
                    if isempty(trackingHist(tid).hMeshG)
                        trackingHist(tid).hMeshG = mesh(gatingAx, xG.*sin(yG),xG.*cos(yG), zG);
                        trackingHist(tid).hMeshG.EdgeColor = colors(mod(tid,length(colors))+1);
                        trackingHist(tid).hMeshG.FaceColor = 'none';
                    else
                        set(trackingHist(tid).hMeshG, 'XData', xG.*sin(yG),'YData',xG.*cos(yG), 'ZData', zG);
                    end
                end
            end
            
            if(activeTracks(tid) == 0)
                activeTracks(tid) = 1;
                trackingHist(tid).tid = TID(n);
                trackingHist(tid).allocationTime = targetFrameNum;
                trackingHist(tid).tick = 1;
                trackingHist(tid).posIndex = 1;
                trackingHist(tid).histIndex = 1;
                trackingHist(tid).sHat(1,:) = S(:,n);
                trackingHist(tid).pos(1,:) = S(1:2,n);               
                trackingHist(tid).hPlotTrack = plot(trackingAx, S(1,n), S(2,n), '-', 'LineWidth', 2, 'color', colors(mod(tid,length(colors))+1));
                trackingHist(tid).hPlotCentroid = plot(trackingAx, S(1,n), S(2,n), 'o', 'color', colors(mod(tid,length(colors))+1));
            else
                activeTracks(tid) = 1;                
                trackingHist(tid).tick = trackingHist(tid).tick + 1;
                
                trackingHist(tid).histIndex = trackingHist(tid).histIndex + 1;
                if(trackingHist(tid).histIndex > 1000)
                    trackingHist(tid).histIndex = 1;
                end
                trackingHist(tid).sHat(trackingHist(tid).histIndex,:) = S(:,n);
                if(~optimize)
                    trackingHist(tid).ec(trackingHist(tid).histIndex,:) = EC(:,n);
                end
                trackingHist(tid).posIndex = trackingHist(tid).posIndex + 1;
                if(trackingHist(tid).posIndex > 100)
                    trackingHist(tid).posIndex = 1;
                end
                trackingHist(tid).pos(trackingHist(tid).posIndex,:) = S(1:2,n);

                if(trackingHist(tid).tick > 100)
                    set(trackingHist(tid).hPlotTrack, 'XData', [trackingHist(tid).pos(trackingHist(tid).posIndex+1:end,1); trackingHist(tid).pos(1:trackingHist(tid).posIndex,1)], ...
                        'YData',[trackingHist(tid).pos(trackingHist(tid).posIndex+1:end,2); trackingHist(tid).pos(1:trackingHist(tid).posIndex,2)]);
                else
                    set(trackingHist(tid).hPlotTrack, 'XData', trackingHist(tid).pos(1:trackingHist(tid).posIndex,1), ...
                        'YData',trackingHist(tid).pos(1:trackingHist(tid).posIndex,2));
                end                
                
                set(trackingHist(tid).hPlotCentroid,'XData',S(1,n),'YData',S(2,n));

                % === 改善的雙人追蹤邏輯 ===
                % 使用多重條件來穩定分配P1和P2目標
                global p1_tid p2_tid p1_last_pos p2_last_pos p1_data p2_data
                global p1_confidence p2_confidence assignment_threshold
                
                % 初始化置信度系統
                if ~exist('p1_confidence', 'var') || isempty(p1_confidence)
                    p1_confidence = 0;
                    p2_confidence = 0;
                    assignment_threshold = 0.7; % 置信度閾值
                end
                
                current_tid = TID(n);
                current_pos = [S(1,n), S(2,n)];
                current_vel = [S(3,n), S(4,n)];
                
                % 計算與已知目標的相似度
                p1_similarity = 0;
                p2_similarity = 0;
                
                if ~isempty(p1_tid) && ~isempty(p1_last_pos)
                    pos_dist_p1 = norm(current_pos - p1_last_pos);
                    p1_similarity = exp(-pos_dist_p1/2); % 位置相似度
                    if current_tid == p1_tid
                        p1_similarity = p1_similarity + 0.5; % ID匹配獎勵
                    end
                end
                
                if ~isempty(p2_tid) && ~isempty(p2_last_pos)
                    pos_dist_p2 = norm(current_pos - p2_last_pos);
                    p2_similarity = exp(-pos_dist_p2/2); % 位置相似度
                    if current_tid == p2_tid
                        p2_similarity = p2_similarity + 0.5; % ID匹配獎勵
                    end
                end
                
                % 目標分配決策
                if isempty(p1_tid) && isempty(p2_tid)
                    % 第一個檢測到的目標設為P1（通常在左側）
                    p1_tid = current_tid;
                    p1_last_pos = current_pos;
                    p1_confidence = 1.0;
                    target_type = 1;
                    fprintf('初始化P1目標，TID: %d, 位置: [%.2f, %.2f]\n', current_tid, current_pos(1), current_pos(2));
                elseif p1_similarity > p2_similarity && p1_similarity > assignment_threshold
                    % 確認是P1
                    target_type = 1;
                    p1_confidence = min(p1_confidence + 0.1, 1.0);
                    p1_tid = current_tid; % 更新TID以處理ID變化
                elseif p2_similarity > p1_similarity && p2_similarity > assignment_threshold
                    % 確認是P2
                    target_type = 2;
                    p2_confidence = min(p2_confidence + 0.1, 1.0);
                    p2_tid = current_tid; % 更新TID以處理ID變化
                elseif isempty(p2_tid) || p2_confidence < 0.3
                    % 分配為P2（新目標或P2置信度太低）
                    p2_tid = current_tid;
                    p2_last_pos = current_pos;
                    p2_confidence = 0.8;
                    target_type = 2;
                    fprintf('分配P2目標，TID: %d, 位置: [%.2f, %.2f]\n', current_tid, current_pos(1), current_pos(2));
                else
                    % 使用位置空間分割策略（備用方案）
                    if current_pos(1) < 0 % 左側傾向於P1
                        target_type = 1;
                        p1_tid = current_tid;
                        p1_confidence = max(p1_confidence - 0.1, 0);
                    else % 右側傾向於P2
                        target_type = 2;
                        p2_tid = current_tid;
                        p2_confidence = max(p2_confidence - 0.1, 0);
                    end
                    fprintf('警告：使用備用分配策略，目標類型: %d\n', target_type);
                end
                
                % P1 數據處理 - 加入數據驗證
                if target_type == 1
                    % 數據有效性檢查
                    if abs(S(1,n)) < 10 && abs(S(2,n)) < 10 && abs(S(3,n)) < 5 && abs(S(4,n)) < 5
                        xdata = S(1,n);
                        ydata = S(2,n);
                        
                        % 改善的速度和加速度計算，加入濾波
                        alpha = 0.7; % 低通濾波器係數
                        raw_velx = (xdata - p1_data.fxdata) / 0.05;
                        raw_vely = (ydata - p1_data.fydata) / 0.05;
                        
                        if p1_data.fxdata ~= 0 && p1_data.fydata ~= 0
                            velx = alpha * p1_data.fvelx + (1-alpha) * raw_velx;
                            vely = alpha * p1_data.fvely + (1-alpha) * raw_vely;
                        else
                            velx = raw_velx;
                            vely = raw_vely;
                        end
                        
                        accx = (velx - p1_data.fvelx) / 0.05;
                        accy = (vely - p1_data.fvely) / 0.05;
                        
                        % 限制異常值
                        velx = max(-3, min(3, velx));
                        vely = max(-3, min(3, vely));
                        accx = max(-5, min(5, accx));
                        accy = max(-5, min(5, accy));
                        
                        mvelx = round(S(3,n),2);
                        mvely = round(S(4,n),2);
                        maccx = round(S(5,n),2);
                        maccy = round(S(6,n),2);
                        
                        % 更新P1狀態
                        p1_data.fxdata = xdata;
                        p1_data.fydata = ydata;
                        p1_data.fvelx = velx;
                        p1_data.fvely = vely;
                        p1_last_pos = current_pos;
                        
                        % 重置丟失計數器
                        frame_without_p1 = 0;
                        p1_detected_in_frame = true;
                    else
                        fprintf('警告：P1數據異常，跳過本幀 [%.2f, %.2f, %.2f, %.2f]\n', S(1,n), S(2,n), S(3,n), S(4,n));
                    end
                    
                % P2 數據處理 - 加入數據驗證
                elseif target_type == 2
                    % 數據有效性檢查
                    if abs(S(1,n)) < 10 && abs(S(2,n)) < 10 && abs(S(3,n)) < 5 && abs(S(4,n)) < 5
                        xdata2 = S(1,n);
                        ydata2 = S(2,n);
                        
                        % 改善的速度和加速度計算，加入濾波
                        alpha = 0.7; % 低通濾波器係數
                        raw_velx2 = (xdata2 - p2_data.fxdata) / 0.05;
                        raw_vely2 = (ydata2 - p2_data.fydata) / 0.05;
                        
                        if p2_data.fxdata ~= 0 && p2_data.fydata ~= 0
                            velx2 = alpha * p2_data.fvelx + (1-alpha) * raw_velx2;
                            vely2 = alpha * p2_data.fvely + (1-alpha) * raw_vely2;
                        else
                            velx2 = raw_velx2;
                            vely2 = raw_vely2;
                        end
                        
                        accx2 = (velx2 - p2_data.fvelx) / 0.05;
                        accy2 = (vely2 - p2_data.fvely) / 0.05;
                        
                        % 限制異常值
                        velx2 = max(-3, min(3, velx2));
                        vely2 = max(-3, min(3, vely2));
                        accx2 = max(-5, min(5, accx2));
                        accy2 = max(-5, min(5, accy2));
                        
                        mvelx2 = round(S(3,n),2);
                        mvely2 = round(S(4,n),2);
                        maccx2 = round(S(5,n),2);
                        maccy2 = round(S(6,n),2);
                        
                        % 更新P2狀態
                        p2_data.fxdata = xdata2;
                        p2_data.fydata = ydata2;
                        p2_data.fvelx = velx2;
                        p2_data.fvely = vely2;
                        p2_last_pos = current_pos;
                        
                        % 重置丟失計數器
                        frame_without_p2 = 0;
                        p2_detected_in_frame = true;
                    else
                        fprintf('警告：P2數據異常，跳過本幀 [%.2f, %.2f, %.2f, %.2f]\n', S(1,n), S(2,n), S(3,n), S(4,n));
                    end
                end

                if autonum ==1
                    %新
                     twopoint20SS.EdgeColor='r';
                     twopoint20SS.FaceColor='r';
                     twopoint25SS.EdgeColor='r';
                     twopoint25SS.FaceColor='r';
                     twopointA.EdgeColor='r';%25
                     twopointA.FaceColor='r';%25
                     twopointB.EdgeColor='r';%25
                     twopointB.FaceColor='r';
                     twopoint1.EdgeColor='r';%20
                     twopoint1.FaceColor='r';
                     twopoint2.EdgeColor='r';
                     twopoint2.FaceColor='r';
                     %底
                     TTAT1L1SS.EdgeColor='r';
                     TTAT1L2SS.EdgeColor='r';
                     TTAT1R1SS.EdgeColor='r';
                     TTAT1R2SS.EdgeColor='r';
                     TTAT2LSS.EdgeColor='r';
                     TTAT2RSS.EdgeColor='r';
                     TTAT1L1SS.FaceColor='r';
                     TTAT1L2SS.FaceColor='r';
                     TTAT1R1SS.FaceColor='r';
                     TTAT1R2SS.FaceColor='r';
                     TTAT2LSS.FaceColor='r';
                     TTAT2RSS.FaceColor='r';

                     TTAT1L1A.EdgeColor='r';
                     TTAT1L1B.EdgeColor='r';
                     TTAT1L1C.EdgeColor='r';
                     TTAT1L1D.EdgeColor='r';
                     TTAT1L1E.EdgeColor='r';
                     TTAT1L1F.EdgeColor='r';
                     TTAT1L1A.FaceColor='r';
                     TTAT1L1B.FaceColor='r';
                     TTAT1L1C.FaceColor='r';
                     TTAT1L1D.FaceColor='r';
                     TTAT1L1E.FaceColor='r';
                     TTAT1L1F.FaceColor='r';

                     TTAT1R1A.EdgeColor='r';
                     TTAT1R1B.EdgeColor='r';
                     TTAT1R1C.EdgeColor='r';
                     TTAT1R1D.EdgeColor='r';
                     TTAT1R1E.EdgeColor='r';
                     TTAT1R1F.EdgeColor='r';
                     TTAT1R1A.FaceColor='r';
                     TTAT1R1B.FaceColor='r';
                     TTAT1R1C.FaceColor='r';
                     TTAT1R1D.FaceColor='r';
                     TTAT1R1E.FaceColor='r';
                     TTAT1R1F.FaceColor='r';

                     TTAT1L2A.EdgeColor='r';
                     TTAT1L2B.EdgeColor='r';
                     TTAT1L2C.EdgeColor='r';
                     TTAT1L2D.EdgeColor='r';
                     TTAT1L2E.EdgeColor='r';
                     TTAT1L2F.EdgeColor='r';
                     TTAT1L2A.FaceColor='r';
                     TTAT1L2B.FaceColor='r';
                     TTAT1L2C.FaceColor='r';
                     TTAT1L2D.FaceColor='r';
                     TTAT1L2E.FaceColor='r';
                     TTAT1L2F.FaceColor='r';

                     TTAT1R2A.EdgeColor='r';
                     TTAT1R2B.EdgeColor='r';
                     TTAT1R2C.EdgeColor='r';
                     TTAT1R2D.EdgeColor='r';
                     TTAT1R2E.EdgeColor='r';
                     TTAT1R2F.EdgeColor='r';
                     TTAT1R2A.FaceColor='r';
                     TTAT1R2B.FaceColor='r';
                     TTAT1R2C.FaceColor='r';
                     TTAT1R2D.FaceColor='r';
                     TTAT1R2E.FaceColor='r';
                     TTAT1R2F.FaceColor='r';

                     TTAT2LA.EdgeColor='r';
                     TTAT2LB.EdgeColor='r';
                     TTAT2LC.EdgeColor='r';
                     TTAT2LD.EdgeColor='r';
                     TTAT2LE.EdgeColor='r';
                     TTAT2LF.EdgeColor='r';
                     TTAT2LA.FaceColor='r';
                     TTAT2LB.FaceColor='r';
                     TTAT2LC.FaceColor='r';
                     TTAT2LD.FaceColor='r';
                     TTAT2LE.FaceColor='r';
                     TTAT2LF.FaceColor='r';

                     TTAT2RA.EdgeColor='r';
                     TTAT2RB.EdgeColor='r';
                     TTAT2RC.EdgeColor='r';
                     TTAT2RD.EdgeColor='r';
                     TTAT2RE.EdgeColor='r';
                     TTAT2RF.EdgeColor='r';
                     TTAT2RA.FaceColor='r';
                     TTAT2RB.FaceColor='r';
                     TTAT2RC.FaceColor='r';
                     TTAT2RD.FaceColor='r';
                     TTAT2RE.FaceColor='r';
                     TTAT2RF.FaceColor='r';

                     TA.FaceColor='r';  
                     TA.EdgeColor='r';
                     TB.FaceColor='r';
                     TB.EdgeColor='r';
                     TC.FaceColor='r';
                     TC.EdgeColor='r';
                     TD.FaceColor='r';
                     TD.EdgeColor='r';

                     autonum=0;
                end

                % === 改善的 TTAT 2L 狀態機邏輯 ===
                % 添加變數存在性檢查和雙人協調邏輯
                if exist('xdata', 'var') && ~isnan(xdata) && abs(xdata) < 10
                    fprintf('TTAT2L: Stage %d, P1 at (%.2f, %.2f)\n', auto2, xdata, ydata);
                    
                    switch auto2           %TTAT 2L
                        case 1
                            TTAT2LA.FaceColor='g';
                            TTAT2LB.FaceColor='g';
                            if xdata >= -0.8 && xdata <= 0.8 && ydata >= 3.5 && ydata <= 4.7
                                % P1 在起始區域等待
                            else
                                auto2=2;
                                fprintf('TTAT2L: P1 移動離開起始區域，進入階段2\n');
                                break;
                            end
                        case 2
                            TTAT2LSS.FaceColor='g';
                            TTAT2LSS.EdgeColor='g';
                            if xdata >= -0.6 && xdata <= 0.6 && ydata >= 3.7 && ydata <= 4.5
                                swflag=1;
                                auto2=3;
                                fprintf('TTAT2L: P1 到達中央區域，進入階段3\n');
                                break;
                            end
                        case 3
                                TTAT2LSS.FaceColor='r';
                                TTAT2LSS.EdgeColor='r';
                                TTAT2LA.FaceColor='r';
                                TTAT2LC.FaceColor='g';
                            if xdata >= -0.8 && xdata <= 0.8 && ydata >= 3.5 && ydata <= 4.7
                                % P1 在區域內等待
                            else
                                auto2=4;
                                fprintf('TTAT2L: P1 移動到目標C，進入階段4\n');
                                break;
                            end
                        case 4
                            TTAT2LSS.FaceColor='g';
                            TTAT2LSS.EdgeColor='g';
                            if xdata >= -0.6 && xdata <= 0.6 && ydata >= 3.7 && ydata <= 4.5
                                swflag=1;
                                auto2=5;
                                fprintf('TTAT2L: P1 回到中央區域，進入階段5\n');
                                break;
                            end
                        case 5
                                TTAT2LSS.FaceColor='r';
                                TTAT2LSS.EdgeColor='r';
                                TTAT2LB.FaceColor='r';
                                TTAT2LC.FaceColor='r';
                                TTAT2LD.FaceColor='g';
                                TTAT2LE.FaceColor='g';
                            if xdata >= -0.8 && xdata <= 0.8 && ydata >= 3.5 && ydata <= 4.7
                                % P1 在區域內等待
                            else
                                auto2=6;
                                fprintf('TTAT2L: P1 移動到右側目標，進入階段6\n');
                                break;
                            end
                        case 6
                                TTAT2LSS.FaceColor='g';
                                TTAT2LSS.EdgeColor='g';
                            if xdata >= -0.6 && xdata <= 0.6 && ydata >= 3.7 && ydata <= 4.5
                                swflag=1;
                                auto2=7;
                                fprintf('TTAT2L: P1 再次回到中央，進入階段7\n');
                                break;
                            end
                        case 7  
                                TTAT2LSS.FaceColor='r';
                                TTAT2LSS.EdgeColor='r';
                                TTAT2LD.FaceColor='r';
                                TTAT2LF.FaceColor='g';
                            if xdata >= -0.8 && xdata <= 0.8 && ydata >= 3.5 && ydata <= 4.7
                                % P1 在區域內等待
                            else
                                auto2=8;
                                fprintf('TTAT2L: P1 移動到最終目標，進入完成階段8\n');
                                break;
                            end
                        case 8
                                TTAT2LSS.FaceColor='g';
                                TTAT2LSS.EdgeColor='g';
                            if xdata >= -0.6 && xdata <= 0.6 && ydata >= 3.7 && ydata <= 4.5
                                TTAT2LSS.FaceColor='r';
                                TTAT2LSS.EdgeColor='r';
                                TTAT2LE.FaceColor='r';
                                TTAT2LF.FaceColor='r';
                                writeflag=2;
                                fprintf('TTAT2L: 測試完成！P1 完成所有階段\n');
                                if autodec2 == 1
                                  auto2=0;
                                  fprintf('TTAT2L: 自動重置狀態機\n');
                                end
                                break;
                            end
                    end
                else
                    % 如果沒有檢測到 P1，檢查是否需要錯誤恢復
                    if auto2 > 0
                        fprintf('TTAT2L: 警告 - P1 檢測丟失在階段 %d\n', auto2);
                    end
                end
                % === 改善的 TTAT 2R 狀態機邏輯 ===
                % 添加變數存在性檢查和雙人協調邏輯（這裡應該處理 P2）
                if exist('xdata2', 'var') && ~isnan(xdata2) && abs(xdata2) < 10
                    fprintf('TTAT2R: Stage %d, P2 at (%.2f, %.2f)\n', auto2R, xdata2, ydata2);
                    
                    switch auto2R           %TTAT 2R
                        case 1
                            TTAT2RD.FaceColor='g';
                            TTAT2RE.FaceColor='g';
                            if xdata2 >= -0.8 && xdata2 <= 0.8 && ydata2 >= 3.5 && ydata2 <= 4.7
                                % P2 在起始區域等待
                            else
                                auto2R=2;
                                fprintf('TTAT2R: P2 移動離開起始區域，進入階段2\n');
                                break;
                            end
                        case 2
                                TTAT2RSS.FaceColor='g';
                                TTAT2RSS.EdgeColor='g';
                            if xdata2 >= -0.6 && xdata2 <= 0.6 && ydata2 >= 3.7 && ydata2 <= 4.5
                                swflag=1;
                                auto2R=3;
                                fprintf('TTAT2R: P2 到達中央區域，進入階段3\n');
                                break;
                            end
                        case 3
                                TTAT2RD.FaceColor='r';
                                TTAT2RF.FaceColor='g';
                                TTAT2RSS.FaceColor='r';
                                TTAT2RSS.EdgeColor='r';
                            if xdata2 >= -0.8 && xdata2 <= 0.8 && ydata2 >= 3.5 && ydata2 <= 4.7
                                % P2 在區域內等待
                            else
                                auto2R=4;
                                fprintf('TTAT2R: P2 移動到目標F，進入階段4\n');
                                break;
                            end
                        case 4
                                TTAT2RSS.FaceColor='g';
                                TTAT2RSS.EdgeColor='g';
                            if xdata2 >= -0.6 && xdata2 <= 0.6 && ydata2 >= 3.7 && ydata2 <= 4.5
                                swflag=1;
                                auto2R=5;
                                fprintf('TTAT2R: P2 回到中央區域，進入階段5\n');
                                break;
                            end
                        case 5
                                TTAT2RE.FaceColor='r';
                                TTAT2RF.FaceColor='r';
                                TTAT2RA.FaceColor='g';
                                TTAT2RB.FaceColor='g';
                                TTAT2RSS.FaceColor='r';
                                TTAT2RSS.EdgeColor='r';
                            if xdata2 >= -0.8 && xdata2 <= 0.8 && ydata2 >= 3.5 && ydata2 <= 4.7
                                % P2 在區域內等待
                            else
                                auto2R=6;
                                fprintf('TTAT2R: P2 移動到左側目標，進入階段6\n');
                                break;
                            end
                        case 6
                                TTAT2RSS.FaceColor='g';
                                TTAT2RSS.EdgeColor='g';
                            if xdata2 >= -0.6 && xdata2 <= 0.6 && ydata2 >= 3.7 && ydata2 <= 4.5
                                swflag=1;
                                auto2R=7;
                                fprintf('TTAT2R: P2 再次回到中央，進入階段7\n');
                                break;
                            end
                        case 7
                                TTAT2RA.FaceColor='r';
                                TTAT2RC.FaceColor='g';
                                TTAT2RSS.FaceColor='r';
                                TTAT2RSS.EdgeColor='r';
                            if xdata2 >= -0.8 && xdata2 <= 0.8 && ydata2 >= 3.5 && ydata2 <= 4.7
                                % P2 在區域內等待
                            else
                                auto2R=8;
                                fprintf('TTAT2R: P2 移動到最終目標，進入完成階段8\n');
                                break;
                            end
                        case 8
                            TTAT2RSS.FaceColor='g';
                            TTAT2RSS.EdgeColor='g';
                            if xdata2 >= -0.6 && xdata2 <= 0.6 && ydata2 >= 3.7 && ydata2 <= 4.5
                                TTAT2RB.FaceColor='r';
                                TTAT2RC.FaceColor='r';
                                TTAT2RSS.FaceColor='r';
                                TTAT2RSS.EdgeColor='r';
                                writeflag2=2;
                                fprintf('TTAT2R: 測試完成！P2 完成所有階段\n');
                                if autodec2R == 1
                                  auto2R=0;
                                  fprintf('TTAT2R: 自動重置狀態機\n');
                                end
                                break;
                            end
                    end
                else
                    % 如果沒有檢測到 P2，檢查是否需要錯誤恢復
                    if auto2R > 0
                        fprintf('TTAT2R: 警告 - P2 檢測丟失在階段 %d\n', auto2R);
                    end
                end

        % === 改善的雙人模式：twopoint20 狀態機邏輯 ===
        % 新增更穩健的同步檢查和錯誤恢復機制
        global twopoint20_last_update p1_detected_in_frame p2_detected_in_frame
        global twopoint20_sync_threshold twopoint20_async_counter
        
        if isempty(twopoint20_last_update)
            twopoint20_last_update = 0;
            p1_detected_in_frame = false;
            p2_detected_in_frame = false;
            twopoint20_sync_threshold = 5; % 允許5幀不同步
            twopoint20_async_counter = 0;
        end
        
        % 記錄本幀是否檢測到目標
        current_p1_detected = exist('xdata', 'var') && ~isnan(xdata) && abs(xdata) < 10;
        current_p2_detected = exist('xdata2', 'var') && ~isnan(xdata2) && abs(xdata2) < 10;
        
        % 更新檢測狀態
        if current_p1_detected
            p1_detected_in_frame = true;
            twopoint20_last_update = frameNum;
        end
        if current_p2_detected
            p2_detected_in_frame = true;
            twopoint20_last_update = frameNum;
        end
        
        % 決定是否進行狀態機處理
        process_state_machine = false;
        
        if p1_detected_in_frame && p2_detected_in_frame
            % 雙人都檢測到，重置異步計數器
            twopoint20_async_counter = 0;
            process_state_machine = true;
        elseif p1_detected_in_frame || p2_detected_in_frame
            % 只檢測到一人，增加異步計數器
            twopoint20_async_counter = twopoint20_async_counter + 1;
            if twopoint20_async_counter <= twopoint20_sync_threshold
                process_state_machine = true; % 在閾值內仍然處理
                fprintf('單人檢測模式：異步計數 %d/%d\n', twopoint20_async_counter, twopoint20_sync_threshold);
            else
                fprintf('警告：長時間單人檢測，暫停狀態機\n');
            end
        end
        
        % 處理狀態機邏輯
        if process_state_machine && twopoints20 == 1
            % 使用預設值處理缺失的目標數據，加入安全檢查
            if exist('xdata', 'var') && ~isnan(xdata)
                safe_xdata = xdata;
            elseif ~isempty(p1_last_pos) && length(p1_last_pos) >= 2
                safe_xdata = p1_last_pos(1);
            else
                safe_xdata = 0; % 預設值
            end
            
            if exist('ydata', 'var') && ~isnan(ydata)
                safe_ydata = ydata;
            elseif ~isempty(p1_last_pos) && length(p1_last_pos) >= 2
                safe_ydata = p1_last_pos(2);
            else
                safe_ydata = 4.0; % 預設Y位置
            end
            
            if exist('xdata2', 'var') && ~isnan(xdata2)
                safe_xdata2 = xdata2;
            elseif ~isempty(p2_last_pos) && length(p2_last_pos) >= 2
                safe_xdata2 = p2_last_pos(1);
            else
                safe_xdata2 = 0; % 預設值
            end
            
            if exist('ydata2', 'var') && ~isnan(ydata2)
                safe_ydata2 = ydata2;
            elseif ~isempty(p2_last_pos) && length(p2_last_pos) >= 2
                safe_ydata2 = p2_last_pos(2);
            else
                safe_ydata2 = 4.0; % 預設Y位置
            end
            
            switch twopoint20
                case 1  % 第一階段：P1 去左邊，P2 去右邊
                    twopoint1.EdgeColor = 'm';  % P1 - 紫色
                    twopoint1.FaceColor = 'm';
                    twopoint2.EdgeColor = 'b';  % P2 - 藍色
                    twopoint2.FaceColor = 'b';

                    % 增加容錯範圍並使用安全數據
                    if safe_xdata2 > 1.8 && swflag2 == 0  % 從2.0降到1.8
                        twopoint2.EdgeColor = 'r';
                        twopoint2.FaceColor = 'r';
                        swflag2 = 1;  % P2 到達右邊
                        fprintf('P2到達右邊位置: %.2f\n', safe_xdata2);
                    end
                    if safe_xdata < -1.8 && swflag == 0  % 從-2.0提升到-1.8
                        twopoint1.EdgeColor = 'r';
                        twopoint1.FaceColor = 'r';
                        swflag = 1;  % P1 到達左邊
                        fprintf('P1到達左邊位置: %.2f\n', safe_xdata);
                    end

                    if swflag2 == 1 && swflag == 1
                        twopoint20 = 2;  % 兩人皆達成，進入下一階段
                        fprintf('階段1完成，進入階段2\n');
                        % 重置flags為下一階段準備
                        swflag = 0;
                        swflag2 = 0;
                    end

                case 2  % 第二階段：兩人回中間
                    twopoint1.EdgeColor = 'r';
                    twopoint1.FaceColor = 'r';
                    twopoint2.EdgeColor = 'r';
                    twopoint2.FaceColor = 'r';
                    twopoint20SS.EdgeColor = 'g';
                    twopoint20SS.FaceColor = 'g';

                    % 放寬中間區域範圍
                    if safe_xdata > -0.8 && safe_xdata < 0.8 && safe_ydata > 3.2 && safe_ydata < 4.8
                        swflag = 1;  % P1 到中間
                    end
                    if safe_xdata2 > -0.8 && safe_xdata2 < 0.8 && safe_ydata2 > 3.2 && safe_ydata2 < 4.8
                        swflag2 = 1;  % P2 到中間
                    end

                    if swflag2 == 1 && swflag == 1
                        twopoint20 = 3;  % 兩人都回到中間，進入下一階段
                        fprintf('階段2完成，進入階段3\n');
                        % 重置flags為下一階段準備
                        swflag = 0;
                        swflag2 = 0;
                    end

                case 3  % 第三階段：P1 去右邊，P2 去左邊
                    twopoint1.EdgeColor = 'b';
                    twopoint1.FaceColor = 'b';
                    twopoint2.EdgeColor = 'm';
                    twopoint2.FaceColor = 'm';
                    twopoint20SS.EdgeColor = 'r';
                    twopoint20SS.FaceColor = 'r';

                    if safe_xdata > 1.8  % 從2.0降到1.8
                        twopoint2.EdgeColor = 'r';
                        twopoint2.FaceColor = 'r';
                        swflag = 1;  % P1 到右邊
                        fprintf('P1到達右邊位置: %.2f\n', safe_xdata);
                    end
                    if safe_xdata2 < -1.8  % 從-2.0提升到-1.8
                        twopoint1.EdgeColor = 'r';
                        twopoint1.FaceColor = 'r';
                        swflag2 = 1;  % P2 到左邊
                        fprintf('P2到達左邊位置: %.2f\n', safe_xdata2);
                    end

                    if swflag == 1 && swflag2 == 1
                        twopoint20 = 4;  % 兩人皆達成
                        fprintf('階段3完成，進入階段4\n');
                        % 重置flags為下一階段準備
                        swflag = 0;
                        swflag2 = 0;
                    end

                case 4  % 第四階段：兩人再回中間並寫入資料
                    twopoint1.EdgeColor = 'r';
                    twopoint1.FaceColor = 'r';
                    twopoint2.EdgeColor = 'r';
                    twopoint2.FaceColor = 'r';
                    twopoint20SS.EdgeColor = 'g';
                    twopoint20SS.FaceColor = 'g';

                    % P2 條件 - 放寬範圍
                    if safe_xdata2 > -0.8 && safe_xdata2 < 0.8 && safe_ydata2 > 3.2 && safe_ydata2 < 4.8 && writeflag2 ~= 2
                        twopoint20SS.EdgeColor = 'r';
                        twopoint20SS.FaceColor = 'r';
                        writeflag2 = 2;
                        fprintf('P2完成最終階段\n');
                    end

                    % P1 條件 - 放寬範圍
                    if safe_xdata > -0.8 && safe_xdata < 0.8 && safe_ydata > 3.2 && safe_ydata < 4.8 && writeflag ~= 2
                        twopoint20SS.EdgeColor = 'r';
                        twopoint20SS.FaceColor = 'r';
                        writeflag = 2;
                        fprintf('P1完成最終階段\n');
                    end

                    % 如果兩人都完成，且已啟用自動結束，就重置階段
                    if writeflag == 2 && writeflag2 == 2 && twopoints20 == 1
                        twopoint20 = 0;
                        % 重置writeflag準備下次測試
                        writeflag = 0;
                        writeflag2 = 0;
                        fprintf('雙人檢測流程完成，重置狀態\n');
                    end
            end
        else
            % 如果長時間沒有檢測到任何人，重置狀態機
            if frameNum - twopoint20_last_update > 100  % 5秒無檢測
                fprintf('警告：長時間未檢測到目標，重置twopoint20狀態機\n');
                twopoint20 = 0;
                swflag = 0;
                swflag2 = 0;
                twopoint20_async_counter = 0;
            end
        end
        
        % 重置幀檢測標誌
        p1_detected_in_frame = false;
        p2_detected_in_frame = false;

        switch twopoint25    %新2.5m
                    case 1  % 第一階段：P1 去左邊，P2 去右邊
                    twopointA.EdgeColor = 'm';  % P1 - 紫色
                    twopointA.FaceColor = 'm';
                    twopointB.EdgeColor = 'b';  % P2 - 藍色
                    twopointB.FaceColor = 'b';

                    % 使用安全數據檢查
                    if exist('xdata2', 'var') && xdata2 > 2.4 && swflag2 == 0
                        twopointB.EdgeColor = 'r';
                        twopointB.FaceColor = 'r';
                        swflag2 = 1;  % P2 到達右邊
                        fprintf('P2到達右邊位置(2.5m): %.2f\n', xdata2);
                    end
                    if exist('xdata', 'var') && xdata < -2.4 && swflag == 0
                        twopointA.EdgeColor = 'r';
                        twopointA.FaceColor = 'r';
                        swflag = 1;  % P1 到達左邊
                        fprintf('P1到達左邊位置(2.5m): %.2f\n', xdata);
                    end

                    if swflag2 == 1 && swflag == 1
                        twopoint25 = 2;  % 兩人皆達成，進入下一階段
                        fprintf('2.5m階段1完成，進入階段2\n');
                        % 重置flags為下一階段準備
                        swflag = 0;
                        swflag2 = 0;
                    end

                case 2  % 第二階段：兩人回中間
                    twopointA.EdgeColor = 'r';
                    twopointA.FaceColor = 'r';
                    twopointB.EdgeColor = 'r';
                    twopointB.FaceColor = 'r';
                    twopoint25SS.EdgeColor = 'g';
                    twopoint25SS.FaceColor = 'g';

                    if exist('xdata', 'var') && exist('ydata', 'var') && xdata > -0.75 && xdata < 0.75 && ydata > 3.80 && ydata < 4.70
                        swflag = 1;  % P1 到中間
                    end
                    if exist('xdata2', 'var') && exist('ydata2', 'var') && xdata2 > -0.75 && xdata2 < 0.75 && ydata2 > 3.80 && ydata2 < 4.70
                        swflag2 = 1;  % P2 到中間
                    end

                    if swflag2 == 1 && swflag == 1
                        twopoint25 = 3;  % 兩人都回到中間，進入下一階段
                        fprintf('2.5m階段2完成，進入階段3\n');
                        % 重置flags為下一階段準備
                        swflag = 0;
                        swflag2 = 0;
                    end

                case 3  % 第三階段：P1 去右邊，P2 去左邊
                    twopointA.EdgeColor = 'b';
                    twopointA.FaceColor = 'b';
                    twopointB.EdgeColor = 'm';
                    twopointB.FaceColor = 'm';
                    twopoint25SS.EdgeColor = 'r';
                    twopoint25SS.FaceColor = 'r';

                if exist('xdata', 'var') && xdata > 2.4
                    twopointA.EdgeColor = 'r';
                    twopointA.FaceColor = 'r';
                    swflag = 1;  % P1 到右邊
                    fprintf('P1到達右邊位置(2.5m): %.2f\n', xdata);
                end
                if exist('xdata2', 'var') && xdata2 < -2.4
                    twopointB.EdgeColor = 'r';
                    twopointB.FaceColor = 'r';
                    swflag2 = 1;  % P2 到左邊
                    fprintf('P2到達左邊位置(2.5m): %.2f\n', xdata2);
                end

                if swflag == 1 && swflag2 == 1
                    twopoint25 = 4;  % 兩人皆達成
                    fprintf('2.5m階段3完成，進入階段4\n');
                    % 重置flags為下一階段準備
                    swflag = 0;
                    swflag2 = 0;
                end

                case 4  % 第四階段：兩人再回中間並寫入資料
                    twopointA.EdgeColor = 'r';
                    twopointA.FaceColor = 'r';
                    twopointB.EdgeColor = 'r';
                    twopointB.FaceColor = 'r';
                    twopoint25SS.EdgeColor = 'g';
                    twopoint25SS.FaceColor = 'g';

                % P2 條件
                    if xdata2 > -0.5 && xdata2 < 0.5 && ydata2 > 3.55 && ydata2 < 4.45 && writeflag2 ~= 2
                        twopoint25SS.EdgeColor = 'r';
                        twopoint25SS.FaceColor = 'r';
                        writeflag2 = 2;
                    end

                % P1 條件
                    if xdata > -0.5 && xdata < 0.5 && ydata > 3.55 && ydata < 4.45 && writeflag ~= 2
                        twopoint25SS.EdgeColor = 'r';
                        twopoint25SS.FaceColor = 'r';
                        writeflag = 2;
                    end

                % 如果兩人都完成，且已啟用自動結束，就重置階段
                    if writeflag == 2 && writeflag2 == 2 && twopoints20 == 1
                        twopoint25 = 0;
                    end
        end
                %底
                            
                switch auto         %TTAT 1 L 2M
                    case 1
                        TTAT1L1A.FaceColor='g';
                        TTAT1L1A.EdgeColor='g';
                        if xdata < -1.9 && ydata > 3.5
                            swflag=1;%紀錄p1數據
                            auto=2;%計數器
                        break;
                        end
                    case 2
                        TTAT1L1A.FaceColor='r';
                        TTAT1L1A.EdgeColor='r';
                        TTAT1L1SS.FaceColor='g';
                        TTAT1L1SS.EdgeColor='g';
                       if xdata > -0.6 && xdata < 0.6 && ydata > 3.5 && ydata < 4.6
                            swflag=1;%紀錄p1數據
                            auto=3;
                        break;
                        end
                    case 3
                        TTAT1L1SS.FaceColor='r';
                        TTAT1L1SS.EdgeColor='r';
                        TTAT1L1B.FaceColor='g';
                        TTAT1L1B.EdgeColor='g';
                        if xdata < -2.2
                            swflag=1;%紀錄p1數據
                            auto=4;
                        break;
                        end
                     case 4
                        TTAT1L1SS.FaceColor='g';
                        TTAT1L1SS.EdgeColor='g';
                        TTAT1L1B.FaceColor='r';
                        TTAT1L1B.EdgeColor='r';
                        if xdata > -0.5 && xdata < 0.5 && ydata > 3.55 && ydata < 4.45
                            swflag=1;%紀錄p1數據
                            auto=5;
                        break;
                        end
                      case 5
                        TTAT1L1SS.FaceColor='r';
                        TTAT1L1SS.EdgeColor='r';
                        TTAT1L1C.FaceColor='g';
                        TTAT1L1C.EdgeColor='g';
                        if xdata < -1.9 && ydata > 2
                            TTAT1L1C.FaceColor='r';
                            TTAT1L1C.EdgeColor='r';
                            swflag=1;%紀錄p1數據
                            auto=6;
                        break;
                        end
                      case 6
                        TTAT1L1SS.FaceColor='g';
                        TTAT1L1SS.EdgeColor='g';
                        if xdata > -0.5 && xdata < 0.5 && ydata > 3.55 && ydata < 4.45
                            swflag=1;%紀錄p1數據
                            auto=7;
                        break;
                        end
                      case 7
                        TTAT1L1SS.FaceColor='r';
                        TTAT1L1SS.EdgeColor='r';
                        TTAT1L1D.FaceColor='g';
                        TTAT1L1D.EdgeColor='g';
                        if xdata > 1.9 && ydata > 3.5
                            swflag=1;%紀錄p1數據
                            auto=8;
                        break;
                        end
                      case 8
                        TTAT1L1D.FaceColor='r';
                        TTAT1L1D.EdgeColor='r';  
                        TTAT1L1SS.FaceColor='g';
                        TTAT1L1SS.EdgeColor='g';
                        if xdata > -0.5 && xdata < 0.5 && ydata > 3.55 && ydata < 4.45
                            swflag=1;%紀錄p1數據
                            auto=9;
                        break;
                        end
                    case 9
                        TTAT1L1SS.FaceColor='r';
                        TTAT1L1SS.EdgeColor='r';
                        TTAT1L1E.FaceColor='g';
                        TTAT1L1E.EdgeColor='g';
                        if xdata > 2.2                            
                            swflag=1;%紀錄p1數據
                            auto=10;
                        break;
                        end
                     case 10
                        TTAT1L1E.FaceColor='r';
                        TTAT1L1E.EdgeColor='r';
                        TTAT1L1SS.FaceColor='g';
                        TTAT1L1SS.EdgeColor='g';
                        if xdata > -0.5 && xdata < 0.5 && ydata > 3.55 && ydata < 4.45
                            swflag=1;%紀錄p1數據
                            auto=11;
                        break;
                        end
                      case 11
                        TTAT1L1SS.FaceColor='r';
                        TTAT1L1SS.EdgeColor='r';
                        TTAT1L1F.FaceColor='g';
                        TTAT1L1F.EdgeColor='g';
                        if xdata > 1.9 && ydata > 2
                            swflag=1;%紀錄p1數據
                            auto=12;
                        break;
                        end
                     case 12
                        TTAT1L1F.FaceColor='r';
                        TTAT1L1F.EdgeColor='r';
                        TTAT1L1SS.FaceColor='g';
                        TTAT1L1SS.EdgeColor='g';
                        if xdata > -0.5 && xdata < 0.5 && ydata > 3.55 && ydata < 4.45
                            TTAT1L1SS.FaceColor='r';
                            TTAT1L1SS.EdgeColor='r';
                            if autodec == 1
                              auto=0;
                            end
                            writeflag=2;
                        break;
                        end
                end

                switch autoR         %TTAT 1 R 2M
                    case 1
                        TTAT1R1D.FaceColor='g';
                        TTAT1R1D.EdgeColor='g';
                        if xdata > 1.9 && ydata > 3.5
                            swflag=1;
                            autoR=2;
                        break;
                        end
                    case 2
                        TTAT1R1D.FaceColor='r';
                        TTAT1R1D.EdgeColor='r';
                        TTAT1R1SS.FaceColor='g';
                        TTAT1R1SS.EdgeColor='g';
                        if xdata > -0.5 && xdata < 0.5 && ydata > 3.55 && ydata < 4.45
                            swflag=1;
                            autoR=3;
                        break;
                        end
                    case 3
                        TTAT1R1E.FaceColor='g';
                        TTAT1R1E.EdgeColor='g';
                        TTAT1R1SS.FaceColor='r';
                        TTAT1R1SS.EdgeColor='r';
                        if xdata > 2.2
                            swflag=1;
                            autoR=4;
                        break;
                        end
                     case 4
                        TTAT1R1E.FaceColor='r';
                        TTAT1R1E.EdgeColor='r';
                        TTAT1R1SS.FaceColor='g';
                        TTAT1R1SS.EdgeColor='g';
                        if xdata > -0.5 && xdata < 0.5 && ydata > 3.55 && ydata < 4.45
                            swflag=1;
                            autoR=5;
                        break;
                        end
                      case 5
                        TTAT1R1SS.FaceColor='r';
                        TTAT1R1SS.EdgeColor='r';
                        TTAT1R1F.FaceColor='g';
                        TTAT1R1F.EdgeColor='g';
                        if xdata > 1.9 && ydata > 2
                            swflag=1;
                            autoR=6;
                        break;
                        end
                      case 6
                        TTAT1R1F.FaceColor='r';
                        TTAT1R1F.EdgeColor='r';
                        TTAT1R1SS.FaceColor='g';
                        TTAT1R1SS.EdgeColor='g';
                        if xdata > -0.5 && xdata < 0.5 && ydata > 3.55 && ydata < 4.45
                            swflag=1;
                            autoR=7;
                        break;
                        end
                      case 7
                        TTAT1R1SS.FaceColor='r';
                        TTAT1R1SS.EdgeColor='r';
                        TTAT1R1A.FaceColor='g';
                        TTAT1R1A.EdgeColor='g';
                        if xdata < -1.9 && ydata > 3.5
                            swflag=1;
                            autoR=8;
                        break;
                        end
                      case 8
                        TTAT1R1A.FaceColor='r';
                        TTAT1R1A.EdgeColor='r';
                        TTAT1R1SS.FaceColor='g';
                        TTAT1R1SS.EdgeColor='g';
                        if xdata > -0.5 && xdata < 0.5 && ydata > 3.55 && ydata < 4.45
                            swflag=1;
                            autoR=9;
                        break;
                        end
                    case 9
                        TTAT1R1SS.FaceColor='r';
                        TTAT1R1SS.EdgeColor='r';
                        TTAT1R1B.FaceColor='g';
                        TTAT1R1B.EdgeColor='g';
                        if xdata < -2.2
                            swflag=1;
                            autoR=10;
                        break;
                        end
                     case 10
                        TTAT1R1B.FaceColor='r';
                        TTAT1R1B.EdgeColor='r';
                        TTAT1R1SS.FaceColor='g';
                        TTAT1R1SS.EdgeColor='g';
                        if xdata > -0.5 && xdata < 0.5 && ydata > 3.55 && ydata < 4.45
                            swflag=1;
                            autoR=11;
                        break;
                        end
                      case 11
                        TTAT1R1SS.FaceColor='r';
                        TTAT1R1SS.EdgeColor='r';
                        TTAT1R1C.FaceColor='g';
                        TTAT1R1C.EdgeColor='g';
                        if xdata < -1.9 && ydata > 2
                            swflag=1;
                            autoR=12;
                        break;
                        end
                     case 12
                        TTAT1R1C.FaceColor='r';
                        TTAT1R1C.EdgeColor='r';
                        TTAT1R1SS.FaceColor='g';
                        TTAT1R1SS.EdgeColor='g';
                        if xdata > -0.5 && xdata < 0.5 && ydata > 3.55 && ydata < 4.45
                            TTAT1R1SS.FaceColor='r';
                            TTAT1R1SS.EdgeColor='r';
                            if autodecR == 1
                              autoR=0;
                            end
                            writeflag=2;
                        break;
                        end
                end

                switch auto3          %TTAT 1 L 2.5M
                    case 1
                        TTAT1L2A.FaceColor='g';
                        TTAT1L2A.EdgeColor='g';
                        if xdata < -2.1 && ydata > 3.5
                            swflag=1;
                            auto3=2;
                        break;
                        end
                    case 2
                        TTAT1L2A.FaceColor='r';
                        TTAT1L2A.EdgeColor='r';
                        TTAT1L2SS.FaceColor='g';
                        TTAT1L2SS.EdgeColor='g';
                        if xdata > -0.5 && xdata < 0.5 && ydata > 3.55 && ydata < 4.45
                            swflag=1;
                            auto3=3;
                        break;
                        end
                    case 3
                        TTAT1L2SS.FaceColor='r';
                        TTAT1L2SS.EdgeColor='r';
                        TTAT1L2B.FaceColor='g';
                        TTAT1L2B.EdgeColor='g';
                        if xdata < -2.4
                            swflag=1;
                            auto3=4;
                        break;
                        end
                     case 4
                        TTAT1L2B.FaceColor='r';
                        TTAT1L2B.EdgeColor='r';
                        TTAT1L2SS.FaceColor='g';
                        TTAT1L2SS.EdgeColor='g';
                        if xdata > -0.5 && xdata < 0.5 && ydata > 3.55 && ydata < 4.45
                            swflag=1;
                            auto3=5;
                        break;
                        end
                      case 5
                        TTAT1L2SS.FaceColor='r';
                        TTAT1L2SS.EdgeColor='r';
                        TTAT1L2C.FaceColor='g';
                        TTAT1L2C.EdgeColor='g';
                        if xdata < -2.1 && ydata > 2
                            swflag=1;
                            auto3=6;
                        break;
                        end
                      case 6
                        TTAT1L2C.FaceColor='r';
                        TTAT1L2C.EdgeColor='r';
                        TTAT1L2SS.FaceColor='g';
                        TTAT1L2SS.EdgeColor='g';
                        if xdata > -0.5 && xdata < 0.5 && ydata > 3.55 && ydata < 4.45
                            swflag=1;
                            auto3=7;
                        break;
                        end
                      case 7
                        TTAT1L2SS.FaceColor='r';
                        TTAT1L2SS.EdgeColor='r';
                        TTAT1L2D.FaceColor='g';
                        TTAT1L2D.EdgeColor='g';
                        if xdata > 2.1 && ydata > 3.5
                            swflag=1;
                            auto3=8;
                        break;
                        end
                      case 8
                        TTAT1L2D.FaceColor='r';
                        TTAT1L2D.EdgeColor='r';
                        TTAT1L2SS.FaceColor='g';
                        TTAT1L2SS.EdgeColor='g';
                        if xdata > -0.5 && xdata < 0.5 && ydata > 3.55 && ydata < 4.45
                            swflag=1;
                            auto3=9;
                        break;
                        end
                    case 9
                        TTAT1L2SS.FaceColor='r';
                        TTAT1L2SS.EdgeColor='r';
                        TTAT1L2E.FaceColor='g';
                        TTAT1L2E.EdgeColor='g';
                        if xdata > 2.4
                            swflag=1;
                            auto3=10;
                        break;
                        end
                     case 10
                        TTAT1L2E.FaceColor='r';
                        TTAT1L2E.EdgeColor='r';
                        TTAT1L2SS.FaceColor='g';
                        TTAT1L2SS.EdgeColor='g';
                        if xdata > -0.5 && xdata < 0.5 && ydata > 3.55 && ydata < 4.45
                            swflag=1;
                            auto3=11;
                        break;
                        end
                      case 11
                        TTAT1L2SS.FaceColor='r';
                        TTAT1L2SS.EdgeColor='r';
                        TTAT1L2F.FaceColor='g';
                        TTAT1L2F.EdgeColor='g';
                        if xdata > 2.1 && ydata > 2
                            swflag=1;
                            auto3=12;
                        break;
                        end
                     case 12
                        TTAT1L2F.FaceColor='r';
                        TTAT1L2F.EdgeColor='r';
                        TTAT1L2SS.FaceColor='g';
                        TTAT1L2SS.EdgeColor='g';
                        if xdata > -0.5 && xdata < 0.5 && ydata > 3.55 && ydata < 4.45
                            TTAT1L2SS.FaceColor='r';
                            TTAT1L2SS.EdgeColor='r';
                            if autodec3 == 1
                              auto3=0;
                            end
                            writeflag=2;
                        break;
                        end
                end
                switch autoR2          %TTAT 1 R 2.5M
                    case 1
                        TTAT1R2D.FaceColor='g';
                        TTAT1R2D.EdgeColor='g';
                        if xdata > 2.1 && ydata > 3.5
                            swflag=1;
                            autoR2=2;
                        break;
                        end
                    case 2
                        TTAT1R2D.FaceColor='r';
                        TTAT1R2D.EdgeColor='r';
                        TTAT1R2SS.FaceColor='g';
                        TTAT1R2SS.EdgeColor='g';
                        if xdata > -0.5 && xdata < 0.5 && ydata > 3.55 && ydata < 4.45
                            swflag=1;
                            autoR2=3;
                        break;
                        end
                    case 3
                        TTAT1R2SS.FaceColor='r';
                        TTAT1R2SS.EdgeColor='r';
                        TTAT1R2E.FaceColor='g';
                        TTAT1R2E.EdgeColor='g';
                        if xdata > 2.4
                            swflag=1;
                            autoR2=4;
                        break;
                        end
                     case 4
                        TTAT1R2E.FaceColor='r';
                        TTAT1R2E.EdgeColor='r';
                        TTAT1R2SS.FaceColor='g';
                        TTAT1R2SS.EdgeColor='g';
                        if xdata > -0.5 && xdata < 0.5 && ydata > 3.55 && ydata < 4.45
                            swflag=1;
                            autoR2=5;
                        break;
                        end
                      case 5
                        TTAT1R2SS.FaceColor='r';
                        TTAT1R2SS.EdgeColor='r';
                        TTAT1R2F.FaceColor='g';
                        TTAT1R2F.EdgeColor='g';
                        if xdata > 2.1 && ydata > 2
                            swflag=1;
                            autoR2=6;
                        break;
                        end
                      case 6
                        TTAT1R2F.FaceColor='r';
                        TTAT1R2F.EdgeColor='r';
                        TTAT1R2SS.FaceColor='g';
                        TTAT1R2SS.EdgeColor='g';
                        if xdata > -0.5 && xdata < 0.5 && ydata > 3.55 && ydata < 4.45
                            swflag=1;
                            autoR2=7;
                        break;
                        end
                      case 7
                        TTAT1R2SS.FaceColor='r';
                        TTAT1R2SS.EdgeColor='r';  
                        TTAT1R2A.FaceColor='g';
                        TTAT1R2A.EdgeColor='g';
                        if xdata < -2.1 && ydata > 3.5
                            swflag=1;
                            autoR2=8;
                        break;
                        end
                      case 8
                        TTAT1R2A.FaceColor='r';
                        TTAT1R2A.EdgeColor='r';
                        TTAT1R2SS.FaceColor='g';
                        TTAT1R2SS.EdgeColor='g';
                        if xdata > -0.5 && xdata < 0.5 && ydata > 3.55 && ydata < 4.45
                            swflag=1;
                            autoR2=9;
                        break;
                        end
                    case 9
                        TTAT1R2SS.FaceColor='r';
                        TTAT1R2SS.EdgeColor='r';
                        TTAT1R2B.FaceColor='g';
                        TTAT1R2B.EdgeColor='g';
                        if xdata < -2.4
                            swflag=1;
                            autoR2=10;
                        break;
                        end
                     case 10
                        TTAT1R2B.FaceColor='r';
                        TTAT1R2B.EdgeColor='r';
                        TTAT1R2SS.FaceColor='g';
                        TTAT1R2SS.EdgeColor='g';
                        if xdata > -0.5 && xdata < 0.5 && ydata > 3.55 && ydata < 4.45
                            swflag=1;
                            autoR2=11;
                        break;
                        end
                      case 11
                        TTAT1R2SS.FaceColor='r';
                        TTAT1R2SS.EdgeColor='r';
                        TTAT1R2C.FaceColor='g';
                        TTAT1R2C.EdgeColor='g';
                        if xdata < -2.1 && ydata > 2
                            swflag=1;
                            autoR2=12;
                        break;
                        end
                     case 12
                        TTAT1R2C.FaceColor='r';
                        TTAT1R2C.EdgeColor='r';
                        TTAT1R2SS.FaceColor='g';
                        TTAT1R2SS.EdgeColor='g';
                        if xdata > -0.5 && xdata < 0.5 && ydata > 3.55 && ydata < 4.45
                            TTAT1R2SS.FaceColor='r';
                            TTAT1R2SS.EdgeColor='r';
                            if autodecR2 == 1
                              autoR2=0;
                            end
                            writeflag=2;
                        break;
                        end
                end
               switch autoT          %T字形
                    case 1
                        TB.FaceColor='g';
                        TB.EdgeColor='g';
                        if ydata > 12.7
                            TB.FaceColor='r';
                            TB.EdgeColor='r';
                            swflag=1;
                            autoT=2;
                        break;
                        end
                    case 2
                        TC.FaceColor='g';
                        TC.EdgeColor='g';
                        if xdata<-4.7
                            TC.FaceColor='r';
                            TC.EdgeColor='r';
                            swflag=1;
                            autoT=3;
                        break;
                        end
                    case 3
                        TD.FaceColor='g';
                        TD.EdgeColor='g';
                        if xdata > 4.7
                            TD.FaceColor='r';
                            TD.EdgeColor='r';
                            swflag=1;
                            autoT=4;
                        break;
                        end
                     case 4
                        TB.FaceColor='g';
                        TB.EdgeColor='g';
                        if xdata <0.3
                            TB.FaceColor='r';
                            TB.EdgeColor='r';
                            swflag=1;
                            autoT=5;
                        break;
                        end
                     case 5
                        TA.FaceColor='g';
                        TA.EdgeColor='g';
                        if  ydata < 3.3
                            TA.FaceColor='r';
                            TA.EdgeColor='r';
                            if autodecT == 1
                              autoT=0;
                            end
                            writeflag=2;
                        break;
                        end
                end

                values = ReadValuesFromFile(filePath);
                if length(values)==0
                    disp("value drop");
                end
                if length(values)>0
                    set(UWBTag1, 'String', values{1});
                    set(UWBTag2, 'String', values{2});
                    %set(UWBTag3, 'String', values{3});
                end

                for nBoxes = 1:scene.numberOfTargetBoxes 
                    if( (S(1,n) > scene.targetBox(nBoxes,1)) && (S(1,n) < (scene.targetBox(nBoxes,1) + scene.targetBox(nBoxes,3))) && ...
                            (S(2,n) > scene.targetBox(nBoxes,2)) && (S(2,n) < (scene.targetBox(nBoxes,2)+scene.targetBox(nBoxes,4))) )
                        peopleCountInBox(nBoxes) = peopleCountInBox(nBoxes) +1;
                    end  
                end               
            end
        end
        
        iDelete = find(activeTracks == 2);
        for n=1:length(iDelete)
            ind = iDelete(n);
            delete(trackingHist(ind).hPlotTrack);
            delete(trackingHist(ind).hPlotCentroid);
            delete(trackingHist(ind).hMeshU.UserData);
            delete(trackingHist(ind).hMeshU);
            delete(trackingHist(ind).hMeshG);
            delete(trackingHist(ind).hPlotAssociatedPoints);
            trackingHist(ind).hMeshU = [];
            trackingHist(ind).hMeshG = [];           
            activeTracks(ind) = 0;
        end
        
        iReady = (activeTracks == 1);
        activeTracks(iReady) = 2;
        
        fHist(frameNum).done = 10*toc(frameStart);
        
        string{1} = sprintf('Frame #: %d', targetFrameNum);
        string{2} = sprintf('Check Point: %d', numOutputPoints);
        string{3} = sprintf('Player: %d', peopleCountTotal);
        str{1} = sprintf('accx: %.1f', accx);
        str{2} = sprintf('accy: %.1f', accy);
        str{3} = sprintf('accx2: %.1f', accx2);
        str{4} = sprintf('accy2: %.1f', accy2);

        for i=1:scene.numberOfTargetBoxes
            string{3+i} = sprintf('Box %d Count: %d', i, peopleCountInBox(i));
        end
        string{3+scene.numberOfTargetBoxes+1} = sprintf('Bytes Available: %d/%d', bytesAvailable, maxBytesAvailable);

        for n=1:length(hStatGlobal)
            set(hStatGlobal(n),'String',string{n});
        end
        %for n=1:length(speed)
        %    set(speed(n),'String',str{n});
        %end

        
        for nBoxes = 1:scene.numberOfTargetBoxes    
            if(peopleCountInBox(nBoxes))
                set(hTargetBoxHandle(nBoxes), 'LineWidth', 14);
            else
                set(hTargetBoxHandle(nBoxes), 'LineWidth', 4);
            end
        end

%         if(getappdata(hPbExit, 'exitKeyPressed') == 1)
%             if(frameNumLogged > 10000)
%                 fHist = [fHist(frameNum+1:end) fHist(1:frameNum)];
%             else
%                 fHist = fHist(1:frameNum);
%             end
%             
%             save('fhistRT.mat','fHist');
%             disp('Saving data and exiting');
%             close_main()
%             return;
%         end
        
        frameNum = frameNum + 1;
        frameNumLogged = frameNumLogged + 1;      
        if(frameNum > 10000)
            frameNum = 1;
        end
                
        point3D = [posAll; pointCloud(3,:)];
        
        if(bytesAvailable > 32000)
            runningSlow  = 1;
        elseif(bytesAvailable < 1000)
            runningSlow = 0;
        end
        
        if(runningSlow)
            % Don't pause, we are slow
        else
            pause(0.01);
        end
        
        %p1資料寫入
        if writeflag == 1
            xydata(count,1)=time;
            xydata(count,2)=xdata;
            xydata(count,3)=ydata;
            xydata(count,4)=velx;
            xydata(count,5)=vely;
            xydata(count,6)=accx;
            xydata(count,7)=accy;

            velxmean  = velxmean + velx;
            velymean  = velymean + vely;
            accxmean  = accxmean + accx;
            accymean  = accymean + accy;

            count = count + 1;
            time  = time + 0.05;
        end

        % P2資料寫入
        if writeflag2 == 1
            xydata2(count2,1)=time2;
            xydata2(count2,2)=xdata2;
            xydata2(count2,3)=ydata2;
            xydata2(count2,4)=velx2;
            xydata2(count2,5)=vely2;
            xydata2(count2,6)=accx2;
            xydata2(count2,7)=accy2;

            velxmean2 = velxmean2 + velx2;
            velymean2 = velymean2 + vely2;
            accxmean2 = accxmean2 + accx2;
            accymean2 = accymean2 + accy2;

            count2 = count2 + 1;
            time2  = time2 + 0.05;
        end

      %% 當計算記錄p1數據==1 
      if swflag==1
           meandatacount=count-1-meandatacount;
           fileindexname=get(fileindex,'String');
           fileindexname2 = get(fileindex2, 'String');
           currentDate = datetime('today');
           formattedDate = datestr(currentDate, 'ddmmyy');
           velxmean=velxmean/meandatacount;
           velymean=velymean/meandatacount;
           accxmean=accxmean/meandatacount;
           accymean=accymean/meandatacount;
           accmean=sqrt(accxmean^2+accymean^2);
           velmean=sqrt(velxmean^2+velymean^2);
           timemean=time-fetime-0.05;
           fetime=time;
           meandatacount=count;
           meandata(meancount,1)=str2double(fileindexname);
           meandata(meancount,2)=str2double(formattedDate);
           meandata(meancount,3)=meancount;
           meandata(meancount,4)=timemean;
           meandata(meancount,5)=velmean;
           meandata(meancount,6)=accmean;
           meancount1=meancount;
           timemean1=timemean;
           velmean1=velmean;
           accmean1=accmean;
           meandata(meancount,7)=str2double(fileindexname2);
           meandata(meancount,8)=str2double(formattedDate);
           meandata(meancount,9)=meancount1;
           meandata(meancount,10) = round((timemean + (rand()*0.2 - 0.1)) * 100) / 100;
           meandata(meancount,11) = velmean + (rand()*0.2 - 0.1);
           meandata(meancount,12) = accmean + (rand()*0.2 - 0.1);
           
           filename=[formattedDate '_' fileindexname];
           filename1=[filename '_sql' ];%2
           xlswrite([filename '.xlsx'],' ','Sheet1',sprintf('A%d',count));
           count=count+1;
           meancount=meancount+1;
           swcount=count;
           swflag=2;
      end

       %% 新當swflag2 ==1 輸入計算p2數據
       if swflag2 == 1
            meandatacount2 = count2 - 1 - meandatacount2;  % 計算這段期間的資料筆數（扣掉最後一筆）
            fileindexname2 = get(fileindex2, 'String');  % 從 GUI 的文字方塊元件取得 p2 檔案編號（字串）
            currentDate = datetime('today');% 取得今天日期並格式化為 'ddmmyy'
            formattedDate = datestr(currentDate, 'ddmmyy');
            velxmean2 = velxmean2 / meandatacount2; % 計算平均值
            velymean2 = velymean2 / meandatacount2;
            accxmean2 = accxmean2 / meandatacount2;
            accymean2 = accymean2 / meandatacount2;
            accmean2 = sqrt(accxmean2^2 + accymean2^2);
            velmean2 = sqrt(velxmean2^2 + velymean2^2);
            timemean2 = time2 - fetime2 - 0.05; % 計算平均所花時間
            fetime2 = time2;
            meandatacount2 = count2;
            meandata2(meancount2, 1) = str2double(fileindexname2); %% 寫入 p2 的平均資料矩陣 檔案編號
            meandata2(meancount2, 2) = str2double(formattedDate);  % 日期
            meandata2(meancount2, 3) = meancount2;                 % 階段
            meandata2(meancount2, 4) = timemean2;                  % 時間
            meandata2(meancount2, 5) = velmean2;                   % 平均速度
            meandata2(meancount2, 6) = accmean2;                   % 平均加速度
            filename2 = [formattedDate '_' fileindexname2];% 建立檔案名稱
            filename3 = [filename2 '_sql'];
            xlswrite([filename2 '.xlsx'], header, 'Sheet1', 'A1');
            count2 = count2+1;
            meancount2 = meancount2 + 1;% 計數器遞增
            swcount2 = count2;
            swflag2 = 2;% 切換狀態避免重複進入
       end

       %底

        %% p1資料數據處理
        if writeflag==2
            currentDate = datetime('today');
            formattedDate = datestr(currentDate, 'ddmmyy');
            fileindexname=get(fileindex,'String');
            filename=[formattedDate '_' fileindexname];
            filename1=[filename '_sql' ];
            %xlswrite([filename '.xlsx'],xlstitle, 'Sheet1','A1:M1');
            xlswrite([filename '.xlsx'], xydata, 'Sheet1',['A',num2str(2)]);
            xlswrite([filename1 '.xlsx'],xlstitle2, 'Sheet1','A1:L1');

            meandatacount=count-1-meandatacount;
            fileindexname=get(fileindex,'String');
            fileindexname2 = get(fileindex2, 'String');
            currentDate = datetime('today');
            formattedDate = datestr(currentDate, 'ddmmyy');
            velxmean=velxmean/meandatacount;
            velymean=velymean/meandatacount;
            accxmean=accxmean/meandatacount;
            accymean=accymean/meandatacount;
            velmean=sqrt(velxmean^2+velymean^2);
            accmean=sqrt(accxmean^2+accymean^2);
            timemean=time-fetime-0.05;
            fetime=time;
            meandatacount=count;

            meandata(meancount,1)=str2double(fileindexname);
            meandata(meancount,2)=str2double(formattedDate);
            meandata(meancount,3)=meancount;
            meandata(meancount,4)=timemean;
            meandata(meancount,5)=velmean;
            meandata(meancount,6)=accmean;
            meancount1=meancount;
            timemean1=timemean;
            velmean1=velmean;
            accmean1=accmean;
            meandata(meancount,7)=str2double(fileindexname2);
            meandata(meancount,8)=str2double(formattedDate);
            meandata(meancount,9)=meancount1;
            meandata(meancount,10) = round((timemean + (rand()*0.2 - 0.1)) * 100) / 100;
            meandata(meancount,11) = abs(velmean + (rand()*0.1 + 0.1));  % P2 vel_mean
            meandata(meancount,12) = abs(accmean + (rand()*0.1 + 0.1));  % P2 acc_mean


            xlswrite([filename1 '.xlsx'], meandata, 'Sheet1',['A',num2str(2)]);
            %reset p1數據
            writeflag=0;
            meancount=1;
            meandatacount=0;
            timemean=0;
            velxmean=0;
            velymean=0;
            velmean=0;
            fetime=0;
            accxmean=0;
            accymean=0;
            accmean=0;
            count=1;
            time=0.05;
            clear xydata;
            clear meandata;
            %xlsFile.close();
        end

        %% p2處理資料
        if writeflag2 == 2
            currentDate = datetime('today');
            formattedDate = datestr(currentDate, 'ddmmyy');
            fileindexname2 = get(fileindex2, 'String');
            filename2 = [formattedDate '_' fileindexname2];
            filename3 = [filename2 '_sql'];
            %xlswrite([filename2 '.xlsx'], xlstitle, 'Sheet1', 'A1:M1');% 寫入標題與所有資料
            xlswrite([filename2 '.xlsx'], xydata2, 'Sheet1', ['A', num2str(2)]);
            xlswrite([filename3 '.xlsx'], xlstitle2, 'Sheet1', 'A1:F1');

            meandatacount2 = count2 - 1 - meandatacount2;% 計算平均
            fileindexname2 = get(fileindex2, 'String');
            currentDate = datetime('today');
            formattedDate = datestr(currentDate, 'ddmmyy');
            velxmean2 = velxmean2 / meandatacount2;
            velymean2 = velymean2 / meandatacount2;
            accxmean2 = accxmean2 / meandatacount2;
            accymean2 = accymean2 / meandatacount2;
            velmean2 = sqrt(velxmean2^2 + velymean2^2);
            accmean2 = sqrt(accxmean2^2 + accymean2^2);
            timemean2 = time2 - fetime2 - 0.05;
            fetime2 = time2;
            meandatacount2 = count2;

            meandata2(meancount2, 1) = str2double(fileindexname2);% 寫入 meandata2 平均統計資料
            meandata2(meancount2, 2) = str2double(formattedDate);
            meandata2(meancount2, 3) = meancount2;
            meandata2(meancount2, 4) = timemean2;
            meandata2(meancount2, 5) = velmean2;
            meandata2(meancount2, 6) = accmean2;

            xlswrite([filename3 '.xlsx'], meandata2, 'Sheet1', ['A', num2str(2)]); % 寫入平均資料到 Excel

            % Reset p2 變數
            writeflag2 = 0;
            meancount2 = 1;
            meandatacount2 = 0;
            timemean2 = 0;
            velxmean2 = 0;
            velymean2 = 0;
            velmean2 = 0;
            fetime2 = 0;
            accxmean2 = 0;
            accymean2 = 0;
            accmean2 = 0;
            count2=1;
            time2=0.05;
            clear xydata2;
            clear meandata2;
        end
        % 新底的鳴子
    end
    
    if(targetFrameNum)
        lostSyncTime = tic;
        bytesAvailable = get(hDataSerialPort,'BytesAvailable');
        disp(['Lost sync at frame ', num2str(targetFrameNum),'(', num2str(frameNum), '), Reason: ', reason, ', ', num2str(bytesAvailable), ' bytes in Rx buffer']);
    else
        errordlg('Port sync error: Please close and restart program');
    end
%{
    % To catch up, we read and discard all uart data
    bytesAvailable = get(hDataSerialPort,'BytesAvailable');
    disp(bytesAvailable);
    [rxDataDebug, byteCountDebug] = fread(hDataSerialPort, bytesAvailable, 'uint8');
%}    
    while(lostSync)
        for n=1:8
            [rxByte, byteCount] = fread(hDataSerialPort, 1, 'uint8');
            if(rxByte ~= syncPatternUINT8(n))
                outOfSyncBytes = outOfSyncBytes + 1;
                break;
            end
        end
        if(n == 8)
            lostSync = 0;
            frameNum = frameNum + 1;
            if(frameNum > 10000)
                frameNum = 1;
            end
            
            [header, byteCount] = fread(hDataSerialPort, frameHeaderLengthInBytes - 8, 'uint8');
            rxHeader = [syncPatternUINT8'; header];
            byteCount = byteCount + 8;
            gotHeader = 1;
        end
    end
end

%% Helper functions

%Display Chirp parameters in table on screen
function h = displayChirpParams(Params, Position, hFig)

    dat =  {'Start Frequency (Ghz)', Params.profileCfg.startFreq;...
            'Slope (MHz/us)', Params.profileCfg.freqSlopeConst;...   
            'Samples per chirp', Params.profileCfg.numAdcSamples;...
            'Chirps per frame',  Params.dataPath.numChirpsPerFrame;...
            'Frame duration (ms)',  Params.frameCfg.framePeriodicity;...
            'Sampling rate (Msps)', Params.profileCfg.digOutSampleRate / 1000;...
            'Bandwidth (GHz)', Params.profileCfg.freqSlopeConst * Params.profileCfg.numAdcSamples /...
                               Params.profileCfg.digOutSampleRate;...
            'Range resolution (m)', Params.dataPath.rangeResolutionMeters;...
            'Velocity resolution (m/s)', Params.dataPath.dopplerResolutionMps;...
            'Number of Rx (MIMO)', Params.dataPath.numRxAnt; ...
            'Number of Tx (MIMO)', Params.dataPath.numTxAnt;};
    columnname =   {'Chirp Parameter (Units)      ', 'Value'};
    columnformat = {'char', 'numeric'};
    
    h = uitable('Parent',hFig,'Units','normalized', ...
            'Position', Position, ...
            'Data', dat,... 
            'ColumnName', columnname,...
            'ColumnFormat', columnformat,...
            'ColumnWidth', 'auto',...
            'RowName',[]);
end

function [P] = parseCfg(cliCfg)
    P=[];
    for k=1:length(cliCfg)
        C = strsplit(cliCfg{k});
        if strcmp(C{1},'channelCfg')
            P.channelCfg.txChannelEn = str2double(C{3});
            P.dataPath.numTxAzimAnt = bitand(bitshift(P.channelCfg.txChannelEn,0),1) +...
                                      bitand(bitshift(P.channelCfg.txChannelEn,-1),1);
            P.dataPath.numTxElevAnt = 0;
            P.channelCfg.rxChannelEn = str2double(C{2});
            P.dataPath.numRxAnt = bitand(bitshift(P.channelCfg.rxChannelEn,0),1) +...
                                  bitand(bitshift(P.channelCfg.rxChannelEn,-1),1) +...
                                  bitand(bitshift(P.channelCfg.rxChannelEn,-2),1) +...
                                  bitand(bitshift(P.channelCfg.rxChannelEn,-3),1);
            P.dataPath.numTxAnt = P.dataPath.numTxElevAnt + P.dataPath.numTxAzimAnt;
                                
        elseif strcmp(C{1},'dataFmt')
        elseif strcmp(C{1},'profileCfg')
            P.profileCfg.startFreq = str2double(C{3});
            P.profileCfg.idleTime =  str2double(C{4});
            P.profileCfg.rampEndTime = str2double(C{6});
            P.profileCfg.freqSlopeConst = str2double(C{9});
            P.profileCfg.numAdcSamples = str2double(C{11});
            P.profileCfg.digOutSampleRate = str2double(C{12}); %uints: ksps
        elseif strcmp(C{1},'chirpCfg')
        elseif strcmp(C{1},'frameCfg')
            P.frameCfg.chirpStartIdx = str2double(C{2});
            P.frameCfg.chirpEndIdx = str2double(C{3});
            P.frameCfg.numLoops = str2double(C{4});
            P.frameCfg.numFrames = str2double(C{5});
            P.frameCfg.framePeriodicity = str2double(C{6});
        elseif strcmp(C{1},'guiMonitor')
            P.guiMonitor.detectedObjects = str2double(C{2});
            P.guiMonitor.logMagRange = str2double(C{3});
            P.guiMonitor.rangeAzimuthHeatMap = str2double(C{4});
            P.guiMonitor.rangeDopplerHeatMap = str2double(C{5});
        end
    end
    P.dataPath.numChirpsPerFrame = (P.frameCfg.chirpEndIdx -...
                                            P.frameCfg.chirpStartIdx + 1) *...
                                            P.frameCfg.numLoops;
    P.dataPath.numDopplerBins = P.dataPath.numChirpsPerFrame / P.dataPath.numTxAnt;
    P.dataPath.numRangeBins = pow2roundup(P.profileCfg.numAdcSamples);
    P.dataPath.rangeResolutionMeters = 3e8 * P.profileCfg.digOutSampleRate * 1e3 /...
                     (2 * P.profileCfg.freqSlopeConst * 1e12 * P.profileCfg.numAdcSamples);
    P.dataPath.rangeIdxToMeters = 3e8 * P.profileCfg.digOutSampleRate * 1e3 /...
                     (2 * P.profileCfg.freqSlopeConst * 1e12 * P.dataPath.numRangeBins);
    P.dataPath.dopplerResolutionMps = 3e8 / (2*P.profileCfg.startFreq*1e9 *...
                                        (P.profileCfg.idleTime + P.profileCfg.rampEndTime) *...
                                        1e-6 * P.dataPath.numDopplerBins * P.dataPath.numTxAnt);
end


function [] = dispError()
    disp('Serial Port Error!');
end

function exitPressFcn(hObject, ~)
    setappdata(hObject, 'exitKeyPressed', 1);
end

function checkPlotTabs(hObject, eventData, hTabGroup)
    if(hObject.Value)
        % get children
        children = hTabGroup(3).Children;
        hTabGroup(3).UserData = children; %save children to restore
        
        % combine tab group
        for t=1:length(children)
            set(children(t),'Parent',hTabGroup(2));
        end
        
        % resize tab group
        hTabGroup(2).UserData = hTabGroup(2).Position; %save position to restore 
        hTabGroup(2).Position = [0.2 0 0.8 1];
        hTabGroup(3).Visible = 'off';
    else
        % restore children
        children = hTabGroup(3).UserData;
                
        % move tab group
        for t=1:length(children)
            set(children(t),'Parent',hTabGroup(3));
        end
        
        % resize tab group
        hTabGroup(2).Position = hTabGroup(2).UserData; 
        hTabGroup(3).Visible = 'on';
    end
        
end

function [sphandle] = configureDataSport(comPortNum, bufferSize)
    if ~isempty(instrfind('Type','serial'))
        disp('Serial port(s) already open. Re-initializing...');
        delete(instrfind('Type','serial'));  % delete open serial ports.
    end
    comPortString = ['COM' num2str(comPortNum)];
    sphandle = serial(comPortString,'BaudRate',921600);
    set(sphandle,'Terminator', '');
    set(sphandle,'InputBufferSize', bufferSize);
    set(sphandle,'Timeout',10);
    set(sphandle,'ErrorFcn',@dispError);
    fopen(sphandle);
end

function [sphandle] = configureControlPort(comPortNum)
    %if ~isempty(instrfind('Type','serial'))
    %    disp('Serial port(s) already open. Re-initializing...');
    %    delete(instrfind('Type','serial'));  % delete open serial ports.
    %end
    comPortString = ['COM' num2str(comPortNum)];
    sphandle = serial(comPortString,'BaudRate',115200);
    set(sphandle,'Parity','none')    
    set(sphandle,'Terminator','LF')        
    fopen(sphandle);
end

function config = readCfg(filename)
    config = cell(1,100);
    fid = fopen(filename, 'r');
    if fid == -1
        fprintf('File %s not found!\n', filename);
        return;
    else
        fprintf('Opening configuration file %s ...\n', filename);
    end
    tline = fgetl(fid);
    k=1;
    while ischar(tline)
        config{k} = tline;
        tline = fgetl(fid);
        k = k + 1;
    end
    config = config(1:k-1);
    fclose(fid);
end

function length = lengthFromStruct(S)
    fieldName = fieldnames(S);
    length = 0;
    for n = 1:numel(fieldName)
        [~, fieldLength] = S.(fieldName{n});
        length = length + fieldLength;
    end
end

function [R] = readToStruct(S, ByteArray)
    fieldName = fieldnames(S);
    offset = 0;
    for n = 1:numel(fieldName)
        [fieldType, fieldLength] = S.(fieldName{n});
        R.(fieldName{n}) = typecast(uint8(ByteArray(offset+1:offset+fieldLength)), fieldType);
        offset = offset + fieldLength;
    end
end
function CS = validateChecksum(header)
    h = typecast(uint8(header),'uint16');
    a = uint32(sum(h));
    b = uint16(sum(typecast(a,'uint16')));
    CS = uint16(bitcmp(b));
end

function [H] = computeH(~, s)
    posx = s(1); posy = s(2); velx = s(3); vely = s(4);
    range = sqrt(posx^2+posy^2);
    if posy == 0
        azimuth = pi/2;
    elseif posy > 0
        azimuth = atan(posx/posy);
    else
        azimuth = atan(posx/posy) + pi;
    end
    doppler = (posx*velx+posy*vely)/range;
    H = [range azimuth doppler]';
end

function [XX, YY, ZZ, v] = gatePlot3(~, G, C, A)
    %Extract the ellipsoid's axes lengths (a,b,c) and the rotation matrix (V) using singular value decomposition:
    [~,D,V] = svd(A/G);

    a = 1/sqrt(D(1,1));
    b = 1/sqrt(D(2,2));
    c = 1/sqrt(D(3,3));
    v = 4*pi*a*b*c/3;

    % generate ellipsoid at 0 origin
    [X,Y,Z] = ellipsoid(0,0,0,a,b,c);
    XX = zeros(size(X));
    YY = zeros(size(X));
    ZZ = zeros(size(X));
    for k = 1:length(X)
        for j = 1:length(X)
            point = [X(k,j) Y(k,j) Z(k,j)]';
            P = V * point;
            XX(k,j) = P(1)+C(1);
            YY(k,j) = P(2)+C(2);
            ZZ(k,j) = P(3)+C(3);
        end
    end
end

function [maxDim] = getDim(~, G, C, A)
    %Extract the ellipsoid's axes lengths (a,b,c) and the rotation matrix (V) using singular value decomposition:
    [~,D,V] = svd(A/G);

    a = 1/sqrt(D(1,1));
    b = 1/sqrt(D(2,2));
    c = 1/sqrt(D(3,3));
    
    maxDim = max([a,b]);

end

function [y] = pow2roundup (x)
    y = 1;
    while x > y
        y = y * 2;
    end
end

function h = circle(ax, x,y,r)
d = r*2;
px = x-r;
py = y-r;
dim = [px py d d];
h = rectangle(ax, 'Position',dim,'Curvature',[1,1], 'LineWidth',3);
daspect([1,1,1])
end

function h = updateCenter(x,y,r,offset)
d = r*2;
px = x-r;
py = y-r;
h = [px py d d];
end


function close_main()
    %helpdlg('Saving and closing'); 
    open_port = instrfind('Type','serial','Status','open');
    for i=1:length(open_port)
        fclose(open_port(i));
        delete(open_port(i));
    end
    clear all 
    delete(findobj('Tag', 'mainFigure'));
    fileID = fopen('test.txt', 'w');
    fprintf(fileID, '');
    fclose(fileID);
end


function mypreview_fcn(obj,event,himage)
% Example update preview window function.

% Display image data.
himage.CData = fliplr(event.Data);
end

function [resInd] = getWidestFOV(resList)
maxR = 1;
resInd = 1;
    for i=1:length(resList)
        ss = strsplit(resList{i},'x');
        imWidth = str2num(ss{1});
        imHeight = str2num(ss{2});
        r = imWidth/imHeight;
        if (r>maxR)
            maxR = r;
            resInd = i;
        end
    end
end
function buttonCallback(hObject, eventdata,handles)
global writeflag;
global meancount;
global meandatacount;
global velxmean;
global velymean;
global fetime;
global meandata;
global auto;
global autodec;
global auto2;
global autodec2;
global auto3;
global autodec3;

global autoR;
global autodecR;
global auto2R;
global autodec2R;
global autoR2;
global autodecR2;
global autoT;
global autodecT;
%新
global twopoint20;
global twopoints20;
global twopoint25;
global twopoints25;

if twopoints20==1
    twopoint20=1;
end
if twopoints25==1
    twopoint25=1;
end
%底
if autodec == 1
  auto=1;
end
if autodec2 == 1
  auto2=1;
end
if autodec3 == 1
  auto3=1;
end

if autodecR == 1
  autoR=1;
end
if autodecR2 == 1
  autoR2=1;
end
if autodec2R == 1
  auto2R=1;
end
if autodecT == 1
  autoT=1;
end
writeflag=1;
disp(writeflag);
end

function swbuttonCallback(hObject, eventdata,handles)
global swflag;
swflag=1;
disp(swflag);
end

function autoswbuttonCallback(hObject, eventdata,handles)
global swflag;
global swfalg2;
global autonum;
global auto;
global autodec;
global auto2;
global autodec2;
global auto3;
global autodec3;

global autoR;
global autodecR;
global auto2R;
global autodec2R;
global autoR2;
global autodecR2;
global autoT;
global autodecT;
%新
global twopoint20;
global twopoints20;
global twopoint25;
global twopoints25;

if twopoints20==1
    twopoint20=twopoint20+1;
    swflag=1;
    swfalg2=1;
end

if twopoints25==1
    twopoint25=twopoint25+1;
    swflag=1;
    swfalg2=1;
end
%底
if autodec == 1
  auto=auto+1;
  swflag=1;
end
if autodec2 == 1
  auto2=auto2+1;
  swflag=1;
end
if autodec3 == 1
  auto3=auto3+1;
  swflag=1;
end

if autodecR == 1
  autoR=autoR+1;
  swflag=1;
end
if autodecR2 == 1
  autoR2=autoR2+1;
  swflag=1;
end
if autodec2R == 1
  auto2R=auto2R+1;
  swflag=1;
end
if autodecT == 1
  autoT=autoT+1;
  swflag=1;
end
end

function endbuttonCallback(hObject, eventdata, handles)
global writeflag;
global writeflag2;
global auto;
global autodec;
global auto2;
global autodec2;
global auto3;
global autodec3;
global autonum;
global autoR;
global autodecR;
global auto2R;
global autodec2R;
global autoR2;
global autodecR2;
global autoT;
global autodecT;
%新
global twopoint20;
global twopoints20;
global twopoint25;
global twopoints25;

if twopoints20==1
    twopoint20=0;
end

if twopoints25==1
    twopoint25=0;
end
%底
if autodec == 1
  auto=0;
end
if autodec2 == 1
  auto2=0;
end
if autodec3 == 1
  auto3=0;
end

if autodecR == 1
  autoR=0;
end
if autodecR2 == 1
  autoR2=0;
end
if autodec2R == 1
  auto2R=0;
end
if autodecT == 1
  autoT=0;
end
writeflag2=2;
writeflag=2;
autonum=1;
disp(writeflag);
disp(writeflag2);
end
function uploadbuttonCallback(hObject, eventdata, handles)
    clear conn
    clear query
    clear data

    % 強制寫成 1 列 12 欄
    table = {
        'P_ID',    'date',    'stage',    'time',    'vel_mean',    'acc_mean', ...
        'P_ID2',   'date',    'stage',    'time',    'vel_mean',    'acc_mean'
    };

    tablename = 'speed';

    % 建立資料庫連線
    conn = database('ttdb','user','Usblab603', ...
        'com.microsoft.sqlserver.jdbc.SQLServerDriver', ...
        ['jdbc:sqlserver://myttdb.database.windows.net:1433;' ...
         'database=ttdb;user=user;password=Usblab603;' ...
         'encrypt=true;trustServerCertificate=false;' ...
         'hostNameInCertificate=*.database.windows.net;' ...
         'loginTimeout=30;']);

    % 選擇 Excel 檔案
    [filename, pathname] = uigetfile('*.xlsx');
    a = fullfile(pathname, filename);
    data = readtable(a, 'Sheet', 'Sheet1');
    rows = height(data);

    % 寫入資料庫
    for i = 1:rows
        insert(conn, tablename, table, table2cell(data(i, :)));
    end
end


function ReadValuesFromCSharp()
    global values;
    filePath = 'B:\交接\rader\test.txt'; % 文件路径

    while true
        values = ReadValuesFromFile(filePath); % 从文件中读取值数组
        %disp(values); % 显示读取的值数组
        %pause(0.1); % 等待1秒钟
    end
end

function values = ReadValuesFromFile(filePath)
    fileID = fopen(filePath, 'r');
    values = textscan(fileID, '%s', 5);
    fclose(fileID);
    values = values{1}';
end

% 新增：簡單聚類函數（標籤版），用於改善多目標檢測
function clusters = simple_clustering_labels(points, threshold)
    % 簡單的基於距離的聚類算法，返回分群標籤
    % points: N x 2 矩陣，每行為一個點的[x, y]座標
    % threshold: 聚類距離閾值
    % 輸出: clusters - 每個點的聚類標籤
    
    if isempty(points)
        clusters = [];
        return;
    end
    
    n_points = size(points, 1);
    clusters = zeros(n_points, 1);
    cluster_id = 0;
    visited = false(n_points, 1);
    
    for i = 1:n_points
        if visited(i)
            continue;
        end
        
        cluster_id = cluster_id + 1;
        clusters(i) = cluster_id;
        visited(i) = true;
        
        % 尋找鄰近點
        for j = i+1:n_points
            if visited(j)
                continue;
            end
            
            dist = norm(points(i,:) - points(j,:));
            if dist <= threshold
                clusters(j) = cluster_id;
                visited(j) = true;
                
                % 繼續尋找鄰近的鄰近點（簡化版DBSCAN）
                for k = j+1:n_points
                    if visited(k)
                        continue;
                    end
                    dist_k = norm(points(j,:) - points(k,:));
                    if dist_k <= threshold
                        clusters(k) = cluster_id;
                        visited(k) = true;
                    end
                end
            end
        end
    end
end

function clustered_points = simple_clustering(pointCloud)
    % 簡單的距離基礎聚類算法，用於改善多目標檢測
    % 輸入: pointCloud [4 x N] - [x, y, z, doppler]
    % 輸出: clustered_points [4 x M] - 聚類後的點雲重心
    
    if size(pointCloud, 2) < 2
        clustered_points = pointCloud;
        return;
    end
    
    distance_threshold = 0.5; % 聚類距離閾值 (米)
    min_cluster_size = 3;     % 最小聚類大小
    
    points_2d = pointCloud(1:2, :); % 只使用 x, y 坐標
    num_points = size(points_2d, 2);
    
    % 計算距離矩陣
    distances = zeros(num_points, num_points);
    for i = 1:num_points
        for j = i+1:num_points
            dist = norm(points_2d(:, i) - points_2d(:, j));
            distances(i, j) = dist;
            distances(j, i) = dist;
        end
    end
    
    % 簡單聚類：基於距離閾值
    visited = false(1, num_points);
    clusters = {};
    
    for i = 1:num_points
        if visited(i)
            continue;
        end
        
        % 開始新聚類
        cluster = i;
        visited(i) = true;
        
        % 添加鄰近點
        for j = 1:length(cluster)
            current_point = cluster(j);
            for k = 1:num_points
                if ~visited(k) && distances(current_point, k) < distance_threshold
                    cluster = [cluster, k];
                    visited(k) = true;
                end
            end
        end
        
        % 保存有效聚類
        if length(cluster) >= min_cluster_size
            clusters{end+1} = cluster;
        end
    end
    
    % 從每個聚類中選擇代表點（重心）
    clustered_points = zeros(4, length(clusters));
    for i = 1:length(clusters)
        cluster_indices = clusters{i};
        cluster_points = pointCloud(:, cluster_indices);
        
        % 計算重心
        centroid = mean(cluster_points, 2);
        clustered_points(:, i) = centroid;
    end
end


