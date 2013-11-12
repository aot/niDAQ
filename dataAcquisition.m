%Piglet Experiment Data Logging

%This script logs slow data for synchronisation during piglet experiments.
%Sample rates are intended to be approximately 1Hz.  The Data Acquisition
%Toolbox is required.  Due to Matlab's lack of support for clock based
%digital input/output (as of R2012b) this script explicitely logs data at
%the sampling rate using the inputSingleScan() function.  Data is plotted
%and saved directly to disk.


%To Do:
%1. Figure close request function - disable closing of the figure
%2. Better start/stop acquisition gui
%3. Include PulseOx Data

%Housekeeping
if exist('sPo', 'var')
    if strcmp(sPo.status, 'open')
        fclose(sPo);
    end
end

clear;
clc;


%%
set(0,'DefaultTextInterpreter','none');
homedir = getenv('HOME');
dataDir = getappdata(0, 'pigletdatadir');
tempDir = 'C:\temp'; %data is immediately saved to the temp directory as it is a SSD and so writes are faster
scrsz = get(0,'ScreenSize');

sampleRate = 1; %sampling rate in Hz.

% get today's date
[Y M D hr mn s] = datevec(now);
expDate = [Y,M,D];
startTime = [hr,mn,s];
%subjStr = 'test';
subjStr = 'LWP302';

recInfo.expDate = expDate;
recInfo.startTime = startTime;
recInfo.subjStr = subjStr;

%nice colours
c = colourscheme;


recDir = [tempDir, filesep, subjStr];
if ~exist(recDir, 'dir')
    mkdir(recDir);
end

recFile = [recDir, filesep, sprintf('systemic_%d%d%d_%02d%02d',Y, M, D, hr, mn)];
poRecFile = [recDir, filesep, sprintf('po_%d%d%d_%02d%02d',Y, M, D, hr, mn)];
app = [];
i = 0;
while exist([recFile, app, '.dat'], 'file')
    i=i+1;
    app = ['_', num2str(i, '%02d')];
end
recFile = [recFile, app, '.mat'];  %set recording file
% fid = fopen(recFile, 'w');
% hdrstr = sprintf([subjStr, '\t' date, '\t %02d:%02d:%02d\n'], hr, mn, floor(s));
% fprintf(fid, hdrstr);
% disp(hdrstr);
%% Setup DAQ
[sA, chA, idxA, chD, idxD, anChanCal, anChanUnits, anChanOff] = dataAcqSetup;

%% Setup Serial Port Acquisition

baud = 115200;
portInfo = instrhwinfo ('serial');

bPortSelect = false;


%automatically use COM4 in windows
portIndex = find(strcmp('COM4', portInfo.AvailableSerialPorts));
bPortSelect=true;

%would be sensible to have some verification/handshaking with the serial
%port/arduino to check it's the right one.

% manually select serial port
% optionsText = 'Please select which serial port to use and press ENTER\n';
% for i = 1:length(portInfo.AvailableSerialPorts)
%     optionsText = [optionsText, '(',num2str(i), ')', portInfo.AvailableSerialPorts{i}, '\n'];
% end
% 
% % select serial port
% while(~bPortSelect)
%     portIndex = str2num(input(optionsText, 's'));
%     if ~isempty(portIndex)
%         bPortSelect = true;
%     end
% end

% open serial comms
sPo = serial( portInfo.AvailableSerialPorts{portIndex}, 'BAUD', baud);



%% Set up Data Plotting
% Create Plots
imsize = [800, 600];
f = figure('Position', [1, scrsz(2)/2, imsize(1), imsize(2)]);
totalPlots = length(chA) + length(chD) + 2;
nCols = 3;
nRows = ceil(totalPlots/nCols);

%Analogue Channels
a=1;
for n= 1:length(chA)
    aAn(n) = subplot(nRows, nCols, a);
    pa(n) = plot(0,0, 'Color', c(a).colour);
    xlabel('s');
    ylabel(anChanUnits{n});
    title(chA(n).Name);
    aVal(n) = text(0.5, 0.2, '0', 'Units', 'normalized', 'FontSize', 15);
    
    a=a+1;
    
end

%digital channels
for n= 1:length(chD)
    aD(n) = subplot(nRows, nCols, a);
    pd(n) = plot(0,0,'Color', c(a).colour);
    xlabel('s');
    title(chD(n).Name);
    ylim([-0.1, 1.1]);
    dVal(n) = text(0.5, 0.2, '0', 'Units', 'normalized', 'FontSize', 15);
    
    a=a+1;
    
end

% PulseOx Channels
%Sat
asat = subplot(nRows, nCols, a);
psat = plot(0,0,'Color', c(a).colour);
ylabel('%');
xlabel('s');
title('Sp02 (%)')
ylim([80, 100]);
satVal = text(0.5, 0.2, '0', 'Units', 'normalized', 'FontSize', 15);
a=a+1;

%Heart Rate
ahr = subplot(nRows, nCols, a);
phr = plot(0,0,'Color', c(a).colour);
ylabel('bpm');
xlabel('s');
ylim([40, 200]);
title('Heart Rate (bpm)')
hrVal = text(0.5, 0.2, '0', 'Units', 'normalized', 'FontSize', 15);


set(gca, 'Box', 'off');
spaceplots(f);

set(f, 'CloseRequestFcn', @my_closereq);
drawnow;


%% Set Acquisition
%Acquisition is controlled by a timer object, every time the timer counts
%it calls the function acqSavePlot, which acquires a sample on all channels
%(analogue and digital), adds these to the matrix data, calculates the
%increment in seconds since the acquisition began.  This results in
%consistent sampling at rates of around 1Hz.
f2=figure('Position', [1, scrsz(2)/2, 400, 100]);
u=uicontrol('string','Stop Acquiring','callback','delete(get(gcbo,''parent''))', 'Position', [150, 25, 100, 50]);
i = 0;
data = [];

t=timer;
%Initialise timer user data structure
udStruct.pa = pa; %analogue plots handles
udStruct.pd = pd; %digital plots handles
udStruct.aVal = aVal; %analogue value handles
udStruct.dVal = dVal; %digital value handles
udStruct.chA = chA; %analogue channel info 
udStruct.chD = chD; %digital channel info
udStruct.idxA = idxA;
udStruct.anChanCal = anChanCal;
udStruct.anChanOff = anChanOff;
udStruct.anChanUnits = anChanUnits;
udStruct.data = []; %empty matrix for stored data
udStruct.elapsed = []; %empty matrix for elapsed times

t.UserData = udStruct;

t.TimerFcn = @(t, event)acqSavePlot(t,event,sA, recFile,recInfo); %set the timer function handle
t.ExecutionMode = 'fixedRate';
t.Period = 1/sampleRate;
t.TasksToExecute = Inf;

start(t)
fopen(sPo);
spcnt = 0; %pulse oximeter counter
poData = [0,0,0,0]; %initialise pulse ox data array: timestamp, elapsed, SpO2, heart rate

while(ishandle(f2))
%does this until the ui control box is clicked to close the window

%acquire serial data, parse and plot

    if sPo.BytesAvailable >=18
        line = fscanf(sPo);

        if length(deblank(line)) > 7
            if strcmp(line(1:4), 'SpO2')
                spcnt = spcnt+1;
                poData(spcnt,1) = now; %timestamp
                poData(spcnt,2) = etime(datevec(poData(spcnt,1)), datevec(poData(1,1)));
                if(strcmp(line(6:8), '---'))
                    poData(spcnt,3) = -1;
                else
                    poData(spcnt,3) = str2double(line(6:8));
                end

                if strcmp(line(13:15), '---')
                    poData(spcnt,4) = -1;
                else
                    poData(spcnt,4) = str2double(line(13:15));
                end

                if isnan(poData(spcnt,3))
                    poData(spcnt, 3) = -1;
                end
                if isnan(poData(spcnt,4))
                    poData(spcnt, 4) = -1;
                end
                save(poRecFile, 'poData', 'recInfo');

                %update plots and text
                if ishandle(f)
                    set(psat, 'YData', poData(:,3), 'XData', poData(:,2));
                    set(phr, 'YData', poData(:,4), 'XData', poData(:,2));
                    set(satVal, 'String', num2str(poData(spcnt,3)));
                    set(hrVal, 'String', num2str(poData(spcnt,4)));
                end
            end
        end
    end

    drawnow;
    if ~ishandle(f)
        close(f2);
    end
end

stop(t);
fclose(sPo); %close serial port

%% Save Data



