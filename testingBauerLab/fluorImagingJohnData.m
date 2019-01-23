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

for run = 1:3
    disp(num2str(run));
    fileName = strcat("\\10.39.168.176\RawData_East3410\181004\181004-D16M2-stim",num2str(run),".tif");
    saveFileName = strcat("D:\data\none\181004-D16M2-stim",num2str(run),".mat");
    maskFileName = 'D:\data\181004-D16M2-LandmarksandMask.mat';
    
    maskData = load(maskFileName);
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
    sessionInfo.detrendSpatially = false;
    sessionInfo.detrendTemporally = false;
    sessionInfo.hbSpecies = 1:4;
    sessionInfo.probeSpecies = [];
    sessionInfo.framerate = 20;
    sessionInfo.lowpass = sessionInfo.framerate./2-0.1;
    sessionInfo.freqout = 1;
    
    darkFrameInd = [];
    
    %% get raw
    
    speciesNum = systemInfo.numLEDs+1;
    raw = read.readRaw(fileName,speciesNum,systemInfo.readFcn);
    raw = raw(:,:,1:4,:);
    
    raw = double(raw);
    raw=resampledata(raw,sessionInfo.framerate,sessionInfo.freqout,1E-5);
    time = 1:size(raw,4);
    time = time./sessionInfo.freqout;
    
%     if run == 1
%         %% get WL image, landmarks, and mask
%         rgbOrder = systemInfo.rgb;
%         wl = preprocess.getWL(raw,darkFrameInd,rgbOrder);
%         [isbrain, affineMarkers] = preprocess.getLandmarksAndMask(wl);
%     end

    isbrain = logical(maskData.isbrain);
    affineMarkers = maskData.I;
    
    %% preprocess
    
    [time,data] = fluor.preprocess(time,raw,systemInfo,sessionInfo,affineMarkers,'darkFrameInd',darkFrameInd);
    xform_isbrain = preprocess.affineTransform(isbrain,affineMarkers);
    
    %% process
    
    [xform_hb,xform_gcamp,xform_gcampCorr] = fluor.process(data,systemInfo,sessionInfo,xform_isbrain);
    
%         load(saveFileName);
    
%     save(saveFileName,'time','xform_hb','xform_gcamp','xform_gcampCorr','isbrain','xform_isbrain','affineMarkers','-v7.3');
    %% gsr
    
    xform_hb = mouse.preprocess.gsr(xform_hb,xform_isbrain);
    
    %% filter
    
    xform_hb = highpass(xform_hb,0.009,sessionInfo.freqout);
    xform_hb = lowpass(xform_hb,0.49,sessionInfo.freqout);
    
    %% get block avg
    
    xform_hb = cat(4,xform_hb(:,:,:,1),xform_hb);
    
    xform_hbAvg = mean(reshape(xform_hb,128,128,2,blockDur*sessionInfo.freqout,[]),5);
    blockTime = linspace(0,blockDur,blockDur*sessionInfo.freqout+1); blockTime(1) = [];
    
    stimTime = (blockTime >= 6 & blockTime <= 11);
    xform_hbStim = nanmean(xform_hbAvg(:,:,:,stimTime),4);
    stimResponseRun = xform_hbStim;
    
    %% get fluor roi response
%     % find the center coordinate of activation
%     roiMap = abs(xform_hbStim(:,:,1));
%     candidateCoor = mouse.plot.circleCoor([76 27],20);
%     candidateCoor = candidateCoor(1,:) + size(roiMap,1)*candidateCoor(2,:);
%     roiMapSub = zeros(size(roiMap)); roiMapSub(candidateCoor) = roiMap(candidateCoor);
%     centerCoor = find(roiMapSub == max(roiMapSub(:)));
%     centerCoor = [mod(centerCoor-1,size(roiMap,1))+1, floor(centerCoor/size(roiMap,1))];
%     
%     coor = mouse.plot.circleCoor(centerCoor,20);
%     coor = coor(1,:)+size(xform_hb,2)*coor(2,:);
%     inCoor = false(size(xform_hb,2));
%     inCoor(coor) = true;
%     
%     roiMap = abs(xform_hbStim(:,:,1));
%     threshold = 0.75*prctile(roiMap(coor),95);
%     
%     roiCandidates = roiMap >= threshold;
%     roiCandidates(~inCoor) = false;
%     
%     % choose largest cluster
%     clusters = bwconncomp(roiCandidates,4);
%     clusterSizes = nan(clusters.NumObjects,1);
%     for clusterInd = 1:clusters.NumObjects
%         clusterSizes(clusterInd) = numel(clusters.PixelIdxList{clusterInd});
%     end
%     maxClusterSize = max(clusterSizes);
%     roi = false(size(roiCandidates));
%     roi(clusters.PixelIdxList{clusterSizes==maxClusterSize}) = true;
    
    roiCoor = mouse.plot.circleCoor([85 28],3);
    roiCoor = roiCoor(1,:) + size(xform_hbStim,1)*roiCoor(2,:);
    roi = false(size(xform_hbStim,1));
    roi(roiCoor) = true;
    
    xform_hbRoiAvgRun = reshape(xform_hbAvg,size(xform_hbAvg,1)*size(xform_hbAvg,2),size(xform_hbAvg,3),[]);
    
    xform_hbRoiAvgRun = squeeze(nanmean(xform_hbRoiAvgRun(roi,:,:),1)); % 2 x 60
    
    xform_hbRoiAvgBaseline = nanmean(xform_hbRoiAvgRun(:,1:floor(5*sessionInfo.freqout)),2);
    
    xform_hbRoiAvgRun = xform_hbRoiAvgRun - repmat(xform_hbRoiAvgBaseline,1,size(xform_hbRoiAvgRun,2));
    
    dataAvgRun = xform_hbRoiAvgRun;
    dataAvg = cat(3,dataAvg,dataAvgRun);
    stimResponse = cat(4,stimResponse,stimResponseRun);
    
end
%% plot fluor roi response
plotData = nanmean(dataAvg,3);

figure;
p1 = plot(blockTime,plotData(1,:),'r'); hold on;
p2 = plot(blockTime,plotData(2,:),'b');
p3 = plot(blockTime,sum(plotData(1:2,:),1),'k');
ylim([-1.5E-6 3E-6]);
yLim = ylim(gca);
stimT = 5:10;
for t = stimT
    plot([t t],yLim,'m');
end
legend([p1 p2 p3],["HbO","HbR","HbT"]);


%% plot stim response

plotData = nanmean(stimResponse,4);

speciesInd = {[1],[2],[1,2]};
titleArray = ["HbO","HbR","HbT"];
% cLim = [-0.5 0.5; -0.5 0.5; -0.5 0.5; -3E3 3E3]./1E6;
% cLim = [-5 5; -5 5; -5 5; -2E4 2E4]./1E6;
% cLim = [-1 1; -1 1; -1 1]./1E6;
cLim = [-2 2; -2 2; -2 2]./1E6;
figure;
for i = 1:3
    subplot(2,2,i);
    imagesc(sum(plotData(:,:,speciesInd{i}),3),'AlphaData',xform_isbrain>0,cLim(i,:));
    colormap('jet'); axis(gca,'square'); xticklabels([]); yticklabels([]);
    colorbar;
    title(titleArray(i));
end

i = 4;
s4 = subplot(2,2,i);
imagesc(roi); colormap(s4, 'parula'); axis(gca,'square'); xticklabels([]); yticklabels([]); colorbar;