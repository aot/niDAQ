function [anChanNum, anChanName, anChanCal, anChanOff, anChanUnits, digChanID, digChanName] = getNIChanSetup
%returns the NI channel setup for systemic data logging
%Analogue
anChanNum = [0,1,2,3,4,5,6,7];
anChanName = {'BP3 Mean';
              'BP3 Rate';
              'Temperature';
              'BP3 Systolic';
              'IPC Pressure';
              'Laser Doppler 1';
              'Laser Doppler 2';
              'Ambient Light'};
tN = 14; %bit depth for temperature
bpmN = 10; %bit depth for rates
bpN = 10; %bit depth for blood pressures
calBP = (2^10 - 1)/(5*3);
calt = (2^tN - 1)/(180*5);
calbpm = (2^bpmN - 1)/5;
bpOffset = -30;
anChanCal = [calBP,calbpm,calt,calBP,1,1,1,1];  %factor to multiply the voltage by to give parameter
anChanOff = [bpOffset,0,0,bpOffset,0,0,0,0]; %parameter offset
anChanUnits = {'mmHg';
              'bpm';
              'Degrees C';
              'mmHg';
              'Voltage';
              'Voltage';
              'Voltage';
              'Voltage'};



%Digital
digChanID = {'port0/line0';
             'port0/line1';
             'port0/line2';
             'port0/line3';
             'port0/line4';
             'port0/line12'};
digChanName = {'MRI Gate';
               'Dig 1';
               'Dig 2';
               'Dig 3';
               'Dig 4';
               'NIRS Gate'};