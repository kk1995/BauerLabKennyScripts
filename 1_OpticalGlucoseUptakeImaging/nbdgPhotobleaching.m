tifFiles(1) = "\\10.39.168.176\RawData_East3410\190115\190115-1d4Hz-6NBDG.tif";
tifFiles(2) = "\\10.39.168.176\RawData_East3410\190115\190115-1Hz-6NBDG.tif";
tifFiles(3) = "\\10.39.168.176\RawData_East3410\190115\190115-4Hz-6NBDG.tif";

freq = [0.25 1 4];

times = {};
data = {};

for file = 1:numel(tifFiles)
    disp(num2str(file));
    dataFile = readtiff(char(tifFiles(file)));
    
    maxVal = max(dataFile,[],3);
    validIndices = maxVal < 1.5E4;
    
    dataFile = reshape(dataFile,[],size(dataFile,3));
    dataFile = dataFile(validIndices,:);
    dataFile = nanmean(dataFile,1);
    
    time = 1:numel(dataFile); time = time./freq(file);
    
    time(1) = [];
    dataFile(1) = [];
    
    times{file} = time;
    data{file} = dataFile;
end

%% plot

figure;
for file = 1:numel(tifFiles)
    plotData = data{file};
    plotData = plotData./max(plotData);
    plot(times{file},plotData);
    hold on;
end
legend('0.25Hz','1Hz','4Hz');