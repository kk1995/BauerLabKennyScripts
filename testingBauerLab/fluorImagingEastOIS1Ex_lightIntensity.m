% this script is a wrapper around gcampImaging.m function that shows how
% the function should be used. As shown, you state which tiff file to run,
% then get system and session information either via the functions
% sysInfo.m and session2procInfo.m or manual addition. Run the
% gcampImaging.m function afterwards and you are good to go!

%% import packages

import mouse.*


%% initialize
dataAvg = [];
stimResponse = [];

filePrefix = "\\10.39.168.176\RawData_East3410\171128\171128-Mouse2-stim";
saveFilePrefix = "D:\data\gcamp6f\171128-Mouse2-stim";
figFilePrefix = "D:\figures\171128-Mouse2-stim";

run = 1;
%% state the tif file

fileName = strcat(filePrefix,num2str(run),".tif");

%% get system or session information.

% use the pre-existing system and session information by selecting the type
% of system and the type of session. If the system or session you are using
% do not fit the existing choices, you can either add new system and
% session types or add them manually.
% for systemInfo, you need rgb and LEDFiles
% for sessionInfo, you need framerate, freqout, lowpass, and highpass

% systemType = 'fcOIS1', 'fcOIS2', 'fcOIS2_Fluor' or 'EastOIS1_Fluor'
systemInfo = mouse.expSpecific.sysInfo('EastOIS1');

% sessionType = 'fc' or 'stim'
sessionInfo = mouse.expSpecific.sesInfo('none');
sessionInfo.hbSpecies = 1:4;
sessionInfo.probeSpecies = [];
%     sessionInfo.framerate = 23.5294;
sessionInfo.framerate = 29.76;
sessionInfo.lowpass = sessionInfo.framerate./2-0.1;
sessionInfo.freqout = sessionInfo.framerate;

darkFrameInd = [];

%% get raw

speciesNum = systemInfo.numLEDs;
raw = read.readRaw(fileName,speciesNum,systemInfo.readFcn);
time = 1:size(raw,4); time = time + 1; time = time./sessionInfo.framerate;

% %% get WL image, landmarks, and mask
% rgbOrder = systemInfo.rgb;
% wl = preprocess.getWL(raw,darkFrameInd,rgbOrder);
% [isbrain, affineMarkers] = preprocess.getLandmarksAndMask(wl);

%% preprocess

[time,data] = fluor.preprocess(time,raw,systemInfo,sessionInfo,affineMarkers,'darkFrameInd',darkFrameInd);
xform_isbrain = preprocess.affineTransform(isbrain,affineMarkers);

%% find all hb combinations
hbCombs = {};
% choose2 = nchoosek(1:4,2);
% for i = 1:size(choose2,1)
%     hbCombs = [hbCombs{:}, {choose2(i,:)}];
% end
choose3 = nchoosek(1:4,3);
for i = 1:size(choose3,1)
    hbCombs = [hbCombs{:}, {choose3(i,:)}];
end
% hbCombs = [{[1 2 3 4]},hbCombs{:}];

data = logmean(data);

%% get block avg
freqOut = 8;
data = mouse.preprocess.blockAvg(data,time,60,60*freqOut);
blockTime = linspace(0,60,60*8+1); blockTime(end) = [];

stimTime = (blockTime > 5 & blockTime <= 15);
dataStim = nanmean(data(:,:,:,stimTime),4);
stimResponseRun = dataStim;

%% get fluor roi response
centerCoor = [60 31];

% find coordinates above the threshold
coor = mouse.plot.circleCoor(centerCoor,10);
coor = coor(1,:)+size(xform_hb,2)*coor(2,:);
roi = false(size(data,1));
roi(coor) = true;

dataRoiAvgRun = reshape(data,size(data,1)*size(data,2),size(data,3),[]);
dataRoiAvgRun = squeeze(nanmean(dataRoiAvgRun(roi,:,:),1)); % 2 x 60

xform_hbRoiAvgBaseline = nanmean(dataRoiAvgRun(:,1:floor(5*freqOut)),2);

dataRoiAvgRun = dataRoiAvgRun - repmat(xform_hbRoiAvgBaseline,1,size(dataRoiAvgRun,2));

%% plot
plotData = nanmean(dataRoiAvgRun,3);
f1 = figure;
p1 = plot(blockTime,plotData(1,:),'b'); hold on;
p2 = plot(blockTime,plotData(2,:),'g');
p3 = plot(blockTime,plotData(3,:),'Color',[255,165,0]./255);
p4 = plot(blockTime,plotData(4,:),'r');
ylim([-2E-2 2E-2]);
yLim = ylim(gca);
stimT = [5 15];
for t = stimT
    plot([t t],yLim,'m');
end
legend([p1 p2 p3 p4],["blue","yellow","orange","red"]);

%% plot stim response

plotData = nanmean(stimResponseRun,4);
speciesInd = {[1],[2],[3],[4]};
titleArray = ["blue","yellow","orange","red"];
cLim = [-1 1; -1 1; -1 1; -1 1]./1E2;
f2 = figure;
for i = 1:4
    subplot(3,2,i);
    imagesc(sum(plotData(:,:,speciesInd{i}),3),'AlphaData',xform_isbrain>0,cLim(i,:));
    colormap('jet'); axis(gca,'square'); xticklabels([]); yticklabels([]);
    colorbar;
    title(titleArray(i));
end

i = 5;
s4 = subplot(3,2,i);
imagesc(roi); colormap(s4, 'parula'); axis(gca,'square'); xticklabels([]); yticklabels([]); colorbar;
