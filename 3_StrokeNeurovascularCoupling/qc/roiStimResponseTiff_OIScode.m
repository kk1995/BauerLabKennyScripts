sR = 16.8;
blockLen = 20;
stimTime = [5 10];
roiFile = 'D:\data\zachRosenthal\_stim\ROI R 75.mat';
roiData = load(roiFile);
roi = roiData.roiR75;

info.framerate = sR;
info.freqout = sR;
info.highpass = 0.009;
info.lowpass = sR./2 - 0.1;

% get list of mice
excelFile = 'D:\data\Stroke Study 1 sorted.xlsx';
rows = 1;
recDates = [];
mouseNames = [];
for row = rows
    [~, ~, raw]=xlsread(excelFile,1, ['A',num2str(row),':B',num2str(row)]);
    recDates = [recDates string(raw{1})];
    mouseNames = [mouseNames string(raw{2})];
end

roiResponse = [];
darkFrame = 100*ones(128,128,4); % here I am assuming that dark values are 100.

for mouseInd = 1:numel(mouseNames)
    disp(['mouse # ' num2str(mouseInd)]);
    maskFile = strcat("D:\data\zachRosenthal\",recDates(mouseInd),"\",recDates(mouseInd),"-",...
        mouseNames(mouseInd),"-LandmarksandMask.mat");
    load(maskFile);
    isbrain = mask > 0;
    markers = I;
    for run = 1:3
        tiffFileName = strcat("D:\data\zachRosenthal\",recDates(mouseInd),"\",recDates(mouseInd),"-",...
            mouseNames(mouseInd),"-stim",num2str(run),".tif");
        
        
        [xform_hb, WL, op, E, info] = procOISData_Kenny(char(tiffFileName), info, 'fcOIS2');
        
        hbData = cat(4,xform_hb(:,:,:,1),xform_hb);
        
        runData = hbData; % 128x128x5040x4
        % oxy, deoxy
                
        blockData = reshape(runData,128,128,2,sR*blockLen,[]);
        blockData = nanmean(blockData,5);
        roiResponseRun = reshape(blockData,128*128,2,[]);
        roiResponseRun = roiResponseRun(roi,:,:);
        roiResponseRun = squeeze(nanmean(roiResponseRun,1));
        
        % save to larger matrix
        roiResponse = cat(3,roiResponse, roiResponseRun);
    end
end

meta.info = info;

%% save

% save('D:\data\zachRosenthal\_stim\roiRResponse.mat','roiResponse');
save('D:\data\zachRosenthal\_stim\roiRResponseMouse1_OISCode.mat','roiResponse','meta');
%% plot

plotData = nanmean(roiResponse,3);
plotData(1:2,:) = plotData(1:2,:);
blockTime = 1:sR*blockLen; blockTime = blockTime./16.8;
plot(blockTime,plotData(1,:),'r');
hold on;
plot(blockTime,plotData(2,:),'b');
plot(blockTime,plotData(1,:)+plotData(2,:),'k');
% plot(blockTime,plotData(3,:),'g');
% plot(blockTime,plotData(4,:),'m');

% legend('hbO','hbR','hbT','g6','g6corrected')
legend('hbO','hbR','hbT');
ylim([-6E-3 6E-3])