function acqSavePlot(obj,event,sA, recFile, recInfo)


s = obj.UserData;


[d, t] = sA.inputSingleScan();
d(s.idxA) = d(s.idxA).*s.anChanCal + s.anChanOff;  %apply calibration factors
s.data(end+1,:) = [t,d];
s.elapsed(end+1) = etime(datevec(t), datevec(s.data(1,1)));
data = s.data;
elapsed = s.elapsed;
recInfo.anChanCal = s.anChanCal;
recInfo.anChanOff = s.anChanOff;
recInfo.anChanName = {s.chA.Name};
recInfo.digChanName = {s.chD.Name}; %
recInfo.anChanUnits = s.anChanUnits; %channel units
recInfo.coderev = 0.1; %code revision

save(recFile,'recInfo', 'data', 'elapsed'); %save important variables to disk as a mat file

obj.UserData = s;


%update plots
a=0;
for n= 1:length(s.chA)
    set(s.pa(n), 'YData', s.data(:,2+a), 'XData', s.elapsed);
    set(s.aVal(n), 'String', num2str(s.data(end,2+a)));
    a=a+1;
end

for n= 1:length(s.chD)
    set(s.pd(n), 'YData', s.data(:,2+a), 'XData', s.elapsed);
    set(s.dVal(n), 'String', num2str(s.data(end,2+a)));
    a=a+1;
end
drawnow;
