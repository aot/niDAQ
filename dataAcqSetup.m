function [sA, chA, idxA, chD, idxD, anChanCal, anChanUnits, anChanOff] = dataAcqSetup
daqModel = 'USB-6343';
daqInfo =daq.getDevices;  %determine if the daq card is plugged in/turned on
sampleRate = 2; %sample rate in Hz

if ~strcmp(daqInfo.Model, daqModel)
    error('USB 6343 not connected/powered');
end


sA = daq.createSession('ni');
sA.IsContinuous = true; %set session to log data continuously
sA.Rate = sampleRate;

sD = daq.createSession('ni'); 

%% Add Channels


[anChanNum, anChanName, anChanCal, anChanOff, anChanUnits, digChanID, digChanName] = getNIChanSetup;
NChanA = length(anChanNum);
NChanD = length(digChanID);

%% Add Channels
%Analogue
[chA, idxA] = sA.addAnalogInputChannel(daqInfo.ID, anChanNum, 'Voltage');

for n = 1:NChanA
    sA.Channels(idxA(n)).Name = anChanName{n};
    sA.Channels(idxA(n)).TerminalConfig = 'Differential';
    
end


%Digital
[chD, idxD] = sA.addDigitalChannel(daqInfo.ID, digChanID, 'InputOnly');
for n = 1:NChanD
    sA.Channels(idxD(n)).Name = digChanName{n};
    
end
    
          

