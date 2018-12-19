dataFile = "\\10.39.168.176\RawData_East3410\181215\5min_8.mat";
sR = 23.5294;
ledTimeBlock = [0.4 0.2 0.2 0.2];

load(dataFile); % timeStamps, data

blockLen = round(10000/sR);

blueLedStart = find(data > 1,1,'first');
ind = 1:numel(data); ind = ind-blueLedStart;
blueIndices = find(mod(ind,blockLen) < blockLen*ledTimeBlock(1));
bounds = [1 find(diff(blueIndices)~=1)];

array = [];
for boundInd = 1:numel(bounds)-1
    boundary = bounds(boundInd):bounds(boundInd+1);
    boundary(boundary < 1) = [];
    frameData = data(blueIndices(boundary));
    plot(frameData); title(num2str(boundInd));
    pause(0.02);
    array = [array mean(frameData)];
end

figure; plot(timeStamps,data);

figure;
plot(array);
ylim([0 4]);