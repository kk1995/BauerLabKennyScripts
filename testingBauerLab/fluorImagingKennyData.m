% this script is a wrapper around gcampImaging.m function that shows how
% the function should be used. As shown, you state which tiff file to run,
% then get system and session information either via the functions
% sysInfo.m and session2procInfo.m or manual addition. Run the
% gcampImaging.m function afterwards and you are good to go!

blockDur = 60; % seconds

%% import packages

import mouse.*


%% initialize
dataAvg = [];
stimResponse = [];

fileName = "M:\181121\181121-ProbeW7M1-Post.tif";
% saveFilePrefix = "D:\data\gcamp6f\171128-Mouse1-stim";

%% get system or session information.

% use the pre-existing system and session information by selecting the type
% of system and the type of session. If the system or session you are using
% do not fit the existing choices, you can either add new system and
% session types or add them manually.
% for systemInfo, you need rgb and LEDFiles
% for sessionInfo, you need framerate, freqout, lowpass, and highpass

% systemType = 'fcOIS1', 'fcOIS2', 'fcOIS2_Fluor' or 'EastOIS1_Fluor'
systemInfo = mouse.expSpecific.sysInfo('fcOIS2_Fluor');

% sessionType = 'fc' or 'stim'
sessionInfo = mouse.expSpecific.sesInfo('6-nbdg');
%     sessionInfo.hbSpecies = [2 4];
%     sessionInfo.framerate = 23.5294;
%     sessionInfo.framerate = 29.76;
sessionInfo.framerate = 16.8;
sessionInfo.lowpass = sessionInfo.framerate./2-0.1;
sessionInfo.freqout = sessionInfo.framerate;

darkFrameInd = 2:50;

%% get raw

speciesNum = systemInfo.numLEDs;
raw = read.readRaw(fileName,speciesNum,systemInfo.readFcn);
raw = raw(:,:,:,1:5040);
time = 1:size(raw,4); time = time./sessionInfo.framerate;

%% get WL image, landmarks, and mask
rgbOrder = systemInfo.rgb;
wl = preprocess.getWL(raw,darkFrameInd,rgbOrder);
[isbrain, affineMarkers] = preprocess.getLandmarksAndMask(wl);

%% preprocess

[time,data] = fluor.preprocess(time,raw,systemInfo,sessionInfo,affineMarkers,'darkFrameInd',darkFrameInd);
xform_isbrain = preprocess.affineTransform(isbrain,affineMarkers);

%% process

[xform_hb,xform_gcamp,xform_gcampCorr] = fluor.process(data,systemInfo,sessionInfo,xform_isbrain);

%     load(saveFileName);

%     save(saveFileName,'xform_hb','xform_gcamp','xform_gcampCorr','isbrain','xform_isbrain','affineMarkers','-v7.3');
%% gsr

xform_hb = mouse.preprocess.gsr(xform_hb,xform_isbrain);
xform_gcamp = mouse.preprocess.gsr(xform_gcamp,xform_isbrain);
xform_gcampCorr = mouse.preprocess.gsr(xform_gcampCorr,xform_isbrain);

%% filter

%     xform_hb = lowpass(xform_hb,0.5,sessionInfo.framerate);
% to get rid of higher frequency nonneuronal factors

%% get block avg

xform_hb = cat(4,xform_hb(:,:,:,1),xform_hb);
xform_gcamp = cat(4,xform_gcamp(:,:,:,1),xform_gcamp);
xform_gcampCorr = cat(4,xform_gcampCorr(:,:,:,1),xform_gcampCorr);

xform_hbAvg = mean(reshape(xform_hb,128,128,2,blockDur*sessionInfo.framerate,[]),5);
xform_gcampAvg = mean(reshape(xform_gcamp,128,128,1,blockDur*sessionInfo.framerate,[]),5);
xform_gcampCorrAvg = mean(reshape(xform_gcampCorr,128,128,1,blockDur*sessionInfo.framerate,[]),5);

%     xform_hbAvg = mouse.preprocess.blockAvg(xform_hb,time,blockDur,blockDur*sessionInfo.framerate);
%     xform_gcampAvg = mouse.preprocess.blockAvg(xform_gcamp,time,blockDur,blockDur*sessionInfo.framerate);
%     xform_gcampCorrAvg = mouse.preprocess.blockAvg(xform_gcampCorr,time,blockDur,blockDur*sessionInfo.framerate);
blockTime = linspace(0,blockDur,blockDur*sessionInfo.framerate+1); blockTime(end) = [];

stimTime = (blockTime > 5 & blockTime <= 10);
xform_hbStim = nanmean(xform_hbAvg(:,:,:,stimTime),4);
xform_gcampStim = nanmean(xform_gcampAvg(:,:,:,stimTime),4);
xform_gcampCorrStim = nanmean(xform_gcampCorrAvg(:,:,:,stimTime),4);
stimResponseRun = cat(3,xform_hbStim,xform_gcampStim,xform_gcampCorrStim);

%% get fluor roi response
temp = xform_hbStim(:,:,1);
temp([1:30 100:128],:) = [];
temp(:,56:128) = [];
threshold = 0.75*prctile(temp(:),95);
roiCandidates = xform_hbStim(:,:,1) >= threshold;
% roiCandidates(abs(xform_probeCorrStim) > 0.02) = false;
roiCandidates([1:30 100:128],:) = false;
roiCandidates(:,56:128) = false;

% choose largest cluster
clusters = bwconncomp(roiCandidates,4);
clusterSizes = nan(clusters.NumObjects,1);
for clusterInd = 1:clusters.NumObjects
    clusterSizes(clusterInd) = numel(clusters.PixelIdxList{clusterInd});
end
maxClusterSize = max(clusterSizes);
roi = false(size(roiCandidates));
roi(clusters.PixelIdxList{clusterSizes==maxClusterSize}) = true;

%     load('roi.mat');

xform_hbRoiAvgRun = reshape(xform_hbAvg,size(xform_hbAvg,1)*size(xform_hbAvg,2),size(xform_hbAvg,3),[]);
xform_gcampRoiAvgRun = reshape(xform_gcampAvg,size(xform_gcampAvg,1)*size(xform_gcampAvg,2),size(xform_gcampAvg,3),[]);
xform_gcampCorrRoiAvgRun = reshape(xform_gcampCorrAvg,size(xform_gcampCorrAvg,1)*size(xform_gcampCorrAvg,2),size(xform_gcampCorrAvg,3),[]);

xform_hbRoiAvgRun = squeeze(nanmean(xform_hbRoiAvgRun(roi,:,:),1)); % 2 x 60
xform_gcampRoiAvgRun = squeeze(nanmean(xform_gcampRoiAvgRun(roi,:,:),1))'; % 1 x 60
xform_gcampCorrRoiAvgRun = squeeze(nanmean(xform_gcampCorrRoiAvgRun(roi,:,:),1))'; % 1 x 60

xform_hbRoiAvgBaseline = nanmean(xform_hbRoiAvgRun(:,1:floor(5*sessionInfo.framerate)),2);
xform_gcampRoiAvgBaseline = nanmean(xform_gcampRoiAvgRun(:,1:floor(5*sessionInfo.framerate)),2);
xform_gcampCorrRoiAvgBaseline = nanmean(xform_gcampCorrRoiAvgRun(:,1:floor(5*sessionInfo.framerate)),2);

xform_hbRoiAvgRun = xform_hbRoiAvgRun - repmat(xform_hbRoiAvgBaseline,1,size(xform_hbRoiAvgRun,2));
xform_gcampRoiAvgRun = xform_gcampRoiAvgRun - repmat(xform_gcampRoiAvgBaseline,1,size(xform_gcampRoiAvgRun,2));
xform_gcampCorrRoiAvgRun = xform_gcampCorrRoiAvgRun - repmat(xform_gcampCorrRoiAvgBaseline,1,size(xform_gcampCorrRoiAvgRun,2));

dataAvgRun = cat(1,xform_hbRoiAvgRun,xform_gcampRoiAvgRun,xform_gcampCorrRoiAvgRun);
dataAvg = cat(3,dataAvg,dataAvgRun);
stimResponse = cat(4,stimResponse,stimResponseRun);

%% plot fluor roi response
plotData = nanmean(dataAvg,3);

figure;
p1 = plot(blockTime,plotData(1,:),'r'); hold on;
p2 = plot(blockTime,plotData(2,:),'b');
p3 = plot(blockTime,sum(plotData(1:2,:),1),'k');
yLim = ylim(gca);
stimT = 5:1/3:10;
for t = stimT
    plot([t t],yLim,'m');
end
legend([p1 p2 p3],["HbO","HbR","HbT"]);

figure;
p1 = plot(blockTime,plotData(3,:),'g'); hold on;
p2 = plot(blockTime,plotData(4,:),'k');
yLim = ylim(gca);
stimT = 5:1/3:10;
for t = stimT
    plot([t t],yLim,'m');
end
legend([p1 p2],["fluor uncorrected","fluor corrected"]);

%% plot stim response

plotData = nanmean(stimResponse,4);

speciesInd = {[1],[2],[1,2],[4]};
titleArray = ["HbO","HbR","HbT","fluor corrected"];
% cLim = [-0.5 0.5; -0.5 0.5; -0.5 0.5; -3E3 3E3]./1E6;
% cLim = [-5 5; -5 5; -5 5; -2E4 2E4]./1E6;
cLim = [-0.5 0.5; -0.5 0.5; -0.5 0.5; -5E3 5E3]./1E6;
% cLim = [-3 3; -3 3; -0.5 0.5; -5E3 5E3]./1E6;
figure;
for i = 1:4
    subplot(2,2,i);
    imagesc(sum(plotData(:,:,speciesInd{i}),3),'AlphaData',xform_isbrain>0,cLim(i,:));
    colormap('jet'); axis(gca,'square'); xticklabels([]); yticklabels([]);
    colorbar;
    title(titleArray(i));
end