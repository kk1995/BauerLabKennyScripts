sR = 16.8;
lowpassFreq = 4;
blockLen = 20;
stimTime = [5 10];
roiFile = 'D:\data\zachRosenthal\_stim\ROI R 75.mat';
roiData = load(roiFile);
roi = roiData.roiR75;

systemInfo = mouse.expSpecific.sysInfo('fcOIS2');
sessionInfo = mouse.expSpecific.session2procInfo('stim');
sessionInfo.framerate = 16.8;
sessionInfo.lowpass = sessionInfo.framerate./2-0.1;
sessionInfo.freqout = sessionInfo.framerate;

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
    maskFile = strcat("K:\Proc2\",recDates(mouseInd),"\",recDates(mouseInd),"-",...
        mouseNames(mouseInd),"-LandmarksandMask.mat");
    load(maskFile);
    isbrain = mask > 0;
    markers = I;
    for run = 1:3
        tiffFileName = strcat("K:\",recDates(mouseInd),"\",recDates(mouseInd),"-",...
            mouseNames(mouseInd),"-stim",num2str(run),".tif");
        darkFrameNum = 0*sessionInfo.framerate;
        if exist('isbrain')
            % if brain mask and markers are available:
            [raw, time, xform_hb, xform_gcamp, xform_gcampCorr, isbrain, xform_isbrain, markers] ...
                = gcamp.gcampImaging(tiffFileName, systemInfo, sessionInfo, isbrain, markers,'darkFrame',darkFrame);
        else
            [raw, time, xform_hb, xform_gcamp, xform_gcampCorr, isbrain, xform_isbrain, markers] ...
                = gcamp.gcampImaging(tiffFileName, systemInfo, sessionInfo,'darkFrame',darkFrame);
        end
        hbData = cat(4,xform_hb(:,:,:,1),xform_hb);
        gcamp6 = cat(4,xform_gcamp(:,:,:,1),xform_gcamp);
        gcamp6corr = cat(4,xform_gcampCorr(:,:,:,1),xform_gcampCorr);
        
        runData = cat(3,hbData,gcamp6,gcamp6corr); % 128x128x5040x4
        % oxy, deoxy, gcamp6, gcamp6corr
        
        runData = lowpass(runData,lowpassFreq,sR);
        
        blockData = reshape(runData,128,128,4,sR*blockLen,[]);
        blockData = nanmean(blockData,5);
        roiResponseRun = reshape(blockData,128*128,4,[]);
        roiResponseRun = roiResponseRun(roi,:,:);
        roiResponseRun = squeeze(nanmean(roiResponseRun,1));
        
        % save to larger matrix
        roiResponse = cat(3,roiResponse, roiResponseRun);
    end
    
%     rowNum = size(roiResponse,3);
%     roiResponse(:,:,rowNum-2) = nanmean(roiResponse(:,:,rowNum-2:rowNum),3);
%     roiResponse = roiResponse(:,:,1:rowNum-2);
end

meta.freq = lowpassFreq;
meta.darkFrame = darkFrame;

%% save

% save('D:\data\zachRosenthal\_stim\roiRResponse.mat','roiResponse');
save('D:\data\zachRosenthal\_stim\roiRResponseMouse1v4.mat','roiResponse','meta');
%% plot

plotData = nanmean(roiResponse,3);
plotData(1:2,:) = 1000*plotData(1:2,:);
blockTime = 1:sR*blockLen; blockTime = blockTime./16.8;
plot(blockTime,plotData(1,:),'r');
hold on;
plot(blockTime,plotData(2,:),'b');
plot(blockTime,plotData(3,:),'g');
plot(blockTime,plotData(4,:),'k');

legend('hbo','hbr','g6','g6corrected')
ylim([-6E-3 6E-3])