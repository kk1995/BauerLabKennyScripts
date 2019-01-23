import mouse.*

darkFrame = 100*ones(128,128,4);
darkFrameInd = [];

blockLen = 20;
stimTime = [5 10];
roiFile = 'D:\data\zachRosenthal\_stim\ROI R 75.mat';
roiData = load(roiFile);
roi = roiData.roiR75;

wlSaveDir = 'D:\data\zachRosenthal\_wl';
% saveFile = 'D:\data\zachRosenthal\_stim\rStimResponseBothDetrend.mat';
saveFile = 'D:\data\zachRosenthal\_stim\rStimResponseFluorPkgNewDPFMouse1-3.mat';

systemInfo = mouse.expSpecific.sysInfo('fcOIS2_Fluor');
sessionInfo = mouse.expSpecific.sesInfo('gcamp6f');
sessionInfo.detrendSpatially = false;
sessionInfo.lowpass = sessionInfo.framerate./2-0.1;
sessionInfo.freqout = sessionInfo.framerate;

sR = sessionInfo.framerate;

% get list of mice
excelFile = 'D:\data\Stroke Study 1 sorted.xlsx';
rows = 1:3;
recDates = [];
mouseNames = [];
for row = rows
    [~, ~, raw]=xlsread(excelFile,1, ['A',num2str(row),':B',num2str(row)]);
    recDates = [recDates string(raw{1})];
    mouseNames = [mouseNames string(raw{2})];
end

roiResponse = [];
stimResponse = [];

for mouseInd = 1:numel(mouseNames)
    disp(['mouse # ' num2str(mouseInd)]);
    maskFile = strcat("D:\data\zachRosenthal\",recDates(mouseInd),"\",recDates(mouseInd),"-",...
        mouseNames(mouseInd),"-LandmarksandMask.mat");
    load(maskFile);
    isbrain = mask > 0;
    affineMarkers = I;
    for run = 1:3
        fileName = strcat("D:\data\zachRosenthal\",recDates(mouseInd),"\",recDates(mouseInd),"-",...
            mouseNames(mouseInd),"-stim",num2str(run),".tif");
        
        speciesNum = systemInfo.numLEDs;
        raw = read.readRaw(fileName,speciesNum,systemInfo.readFcn);
        time = 1:size(raw,4); time = time./sessionInfo.framerate;
        if ~exist('isbrain')
            rgbOrder = systemInfo.rgb;
            wl = preprocess.getWL(raw,darkFrameInd,rgbOrder);
            [isbrain, affineMarkers] = preprocess.getLandmarksAndMask(wl);
        end
        
        [time,data] = fluor.preprocess(time,raw,systemInfo,sessionInfo,affineMarkers,'darkFrame',darkFrame);
        xform_isbrain = preprocess.affineTransform(isbrain,affineMarkers);
        
        [datahb,dataFluor,dataFluorCorr] = fluor.process(data,systemInfo,sessionInfo,xform_isbrain);
        
%         datahb = preprocess.gsr(datahb,xform_isbrain);
%         dataFluor = preprocess.gsr(dataFluor,xform_isbrain);
%         dataFluorCorr = preprocess.gsr(dataFluorCorr,xform_isbrain);
        
        hbData = cat(4,datahb(:,:,:,1),datahb);
        gcamp6 = cat(4,dataFluor(:,:,:,1),dataFluor);
        gcamp6corr = cat(4,dataFluorCorr(:,:,:,1),dataFluorCorr);
        
        runData = cat(3,hbData,gcamp6,gcamp6corr); % 128x128x5040x4
        runData = double(runData);
        % oxy, deoxy, gcamp6, gcamp6corr
        
        runData = lowpass(runData,sessionInfo.lowpass,sR);
        
        blockData = reshape(runData,128,128,4,sR*blockLen,[]);
        blockData = nanmean(blockData,5);
        blockTime = 1:sR*blockLen; blockTime = blockTime./16.8;
        
        stimTimeInd = blockTime > 5 & blockTime < 10;
        stimResponseRun = nanmean(blockData(:,:,:,stimTimeInd),4);
        roiResponseRun = reshape(blockData,128*128,4,[]);
        roiResponseRun = roiResponseRun(roi,:,:);
        roiResponseRun = squeeze(nanmean(roiResponseRun,1));
        
        baseTimeInd = blockTime < 5;
        roiResponseRun = roiResponseRun - repmat(nanmean(roiResponseRun(:,baseTimeInd),2),1,size(roiResponseRun,2));
        
        % save to larger matrix
        roiResponse = cat(3,roiResponse, roiResponseRun);
        stimResponse = cat(4,stimResponse,stimResponseRun);
    end
    
%     rowNum = size(roiResponse,3);
%     roiResponse(:,:,rowNum-2) = nanmean(roiResponse(:,:,rowNum-2:rowNum),3);
%     roiResponse = roiResponse(:,:,1:rowNum-2);
end

meta.freq = sessionInfo.lowpass;
meta.darkFrame = darkFrame;
meta.mice = rows;

%% save

% save('D:\data\zachRosenthal\_stim\roiRResponse.mat','roiResponse');
% save(saveFile,...
%     'roiResponse','stimResponse','meta','sessionInfo');
%% plot

baseTimeInd = blockTime < 5;
plotData = nanmean(roiResponse,3);
plotData = bsxfun(@minus,plotData,nanmean(plotData(:,baseTimeInd),2));

figure;
plotData(1:2,:) = 1000*plotData(1:2,:);
plot(blockTime,plotData(1,:),'r');
hold on;
plot(blockTime,plotData(2,:),'b');
plot(blockTime,plotData(1,:)+plotData(2,:),'k');
plot(blockTime,plotData(3,:),'g');
plot(blockTime,plotData(4,:),'m');

legend('hbO','hbR','hbT','g6','g6corrected')
ylim([-6E-3 6E-3])
% ylim([-1.5E-2 1.5E-2])

%%
plotData = nanmean(stimResponse,4);
plotData(:,:,1:2) = 1000*plotData(:,:,1:2);
plotData(:,:,3) = sum(plotData(:,:,1:2),3);
figure;
subTitles = ["HbO","HbR","HbT","gcamp corr"];
cLim = [-5E-4 5E-4; -5E-4 5E-4; -5E-4 5E-4; -2E-3 2E-3];
% cLim = [-5E-4 5E-4; -5E-4 5E-4; -5E-4 5E-4; -1E-2 1E-2];
for i = 1:4
subplot(2,2,i);
imagesc(plotData(:,:,i),cLim(i,:));
colormap('jet');
colorbar;
axis(gca,'square'); yticklabels([]); xticklabels([]);
title(subTitles(i));
end