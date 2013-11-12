function plotData(src,event, ax)
    persistent tempData;
    persistent tempTimestamps;
    global data;
    if(isempty(tempData))
        tempData = [];
        tempTimestamps = [];
    end
     tempData = [tempData; event.Data];
     tempTimestamps = [tempTimestamps; event.TimeStamps];
     data.analogue = tempData;
     data.timestampAnalog = tempTimestamps;
     plot(ax, data.timestampAnalog, data.analogue);
     drawnow;
 end
