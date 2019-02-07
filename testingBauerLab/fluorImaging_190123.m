% John's data

blockDur = 60; % seconds
seedCoor = [84 23];
stimTimeLim = [6 11];

%% import packages

import mouse.*

%% initialize
dataAvg = [];
stimResponse = [];
roi = [];
vascular = [];

for run = 1:3
    disp(num2str(run));
    fileName = strcat("\\10.39.168.176\RawData_East3410\190123\190123-212M1-stim",num2str(run),".tif");
    saveFileName = strcat("D:\data\none\190123-212M1-stim",num2str(run),"-hillmanMusp.mat");
    maskFileName = 'D:\data\none\190123-212M1-LandmarksandMask.mat';
    
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
    sessionInfo.freqout = 2;
    
    darkFrameInd = [];
    
    if exist(saveFileName)
        disp('load processed');
        load(saveFileName);
    else
        %% get raw
        disp('get raw');
        speciesNum = systemInfo.numLEDs+1;
        [raw, time] = read.readRaw(fileName,speciesNum,systemInfo.readFcn,...
            systemInfo.invalidFrameInd,sessionInfo.framerate,sessionInfo.freqout);
        raw = raw(:,:,1:4,:);
        
        disp('get mask');
        if exist(maskFileName)
            maskData = load(maskFileName);
        else
            rgbOrder = systemInfo.rgb;
            wl = preprocess.getWL(raw,darkFrameInd,rgbOrder);
            [isbrain, I] = preprocess.getLandmarksAndMask(wl);
            maskData.isbrain = isbrain;
            maskData.I = I;
            
            save(maskFileName,'isbrain','I','-v7.3');
        end
        
        isbrain = logical(maskData.isbrain);
        affineMarkers = maskData.I;
        
        %% preprocess
        disp('preprocess');
        [time,data] = fluor.preprocess(time,raw,systemInfo,sessionInfo,affineMarkers,'darkFrameInd',darkFrameInd);
        xform_isbrain = preprocess.affineTransform(isbrain,affineMarkers);
        
        %% process
        
        disp('process');
        [xform_hb,xform_gcamp,xform_gcampCorr] = fluor.process(data,systemInfo,sessionInfo,xform_isbrain);
        
        disp('save');
        save(saveFileName,'time','xform_hb','xform_gcamp','xform_gcampCorr','isbrain','xform_isbrain','affineMarkers','-v7.3');
    end
    
    %% gsr
    disp('gsr');
    
%     % remove vascular data from mask
%     xform_hbAvg = mouse.preprocess.blockAvg(xform_hb,time,blockDur,blockDur*sessionInfo.freqout);
%     blockTime = linspace(0,blockDur,blockDur*sessionInfo.freqout+1); blockTime(1) = [];
%     stimTime = (blockTime > stimTimeLim(1) & blockTime <= stimTimeLim(2));
%     xform_hbStim = nanmean(xform_hbAvg(:,:,:,stimTime),4);
%     roiMap = xform_hbStim(:,:,1);
%     
%     thrCandidate = false(size(roiMap));
%     thrCandidate(21:108,61:68) = true;
%     thr = 0.75*prctile(roiMap(thrCandidate),95);
%     
%     vascularCandidate = false(size(roiMap));
%     vascularCandidate(11:118,51:78) = true;
%     vascularRun = roiMap > thr;
%     vascularRun = vascularRun & vascularCandidate;
%     vascular = cat(3,vascularRun);
%     
%     xform_isbrain(vascularRun) = false;
    
    xform_hb = mouse.preprocess.gsr(xform_hb,xform_isbrain);
    
    %% filter
    
    xform_hb = highpass(xform_hb,0.009,sessionInfo.freqout);
    xform_hb = lowpass(xform_hb,0.49,sessionInfo.freqout);
    
    %% get block avg
    xform_hbAvg = mouse.preprocess.blockAvg(xform_hb,time,blockDur,blockDur*sessionInfo.freqout);
    blockTime = linspace(0,blockDur,blockDur*sessionInfo.freqout+1); blockTime(1) = [];
    
    stimTime = (blockTime > stimTimeLim(1) & blockTime <= stimTimeLim(2));
    xform_hbStim = nanmean(xform_hbAvg(:,:,:,stimTime),4);
    stimResponseRun = xform_hbStim;
    
    %% get fluor roi response
    % find the center coordinate of activation
    roiMap = xform_hbStim(:,:,1);
    peakCandidateCoor = mouse.plot.circleCoor(seedCoor,5);
    peakCandidateCoor = peakCandidateCoor(1,:) + size(roiMap,1)*peakCandidateCoor(2,:);
    roiMapSub = zeros(size(roiMap)); roiMapSub(peakCandidateCoor) = roiMap(peakCandidateCoor);
    centerCoor = find(roiMapSub == max(roiMapSub(:)));
    centerCoor = [mod(centerCoor-1,size(roiMap,1))+1, floor(centerCoor/size(roiMap,1))];
    
    thrCoor = mouse.plot.circleCoor(centerCoor,20);
    thrCoor = thrCoor(1,:)+size(xform_hb,2)*thrCoor(2,:);
    thrCoor(thrCoor < 1) = [];
    
    threshold = 0.75*prctile(roiMap(thrCoor),95);
    
    candidateCoor = mouse.plot.circleCoor(centerCoor,8);
    candidateCoor = candidateCoor(1,:)+size(xform_hb,2)*candidateCoor(2,:);
    candidateCoor(candidateCoor < 1) = [];
    inCoor = false(size(xform_hb,2));
    inCoor(candidateCoor) = true;
    roiCandidates = roiMap >= threshold;
    roiCandidates(~inCoor) = false;
    
    % choose largest cluster
    clusters = bwconncomp(roiCandidates,4);
    clusterSizes = nan(clusters.NumObjects,1);
    for clusterInd = 1:clusters.NumObjects
        clusterSizes(clusterInd) = numel(clusters.PixelIdxList{clusterInd});
    end
    maxClusterSize = max(clusterSizes);
    roiRun = false(size(roiCandidates));
    roiRun(clusters.PixelIdxList{clusterSizes==maxClusterSize}) = true;
    
%     roiCoor = mouse.plot.circleCoor([85 28],3);
%     roiCoor = roiCoor(1,:) + size(xform_hbStim,1)*roiCoor(2,:);
%     roiRun = false(size(xform_hbStim,1));
%     roiRun(roiCoor) = true;
    
    xform_hbRoiAvgRun = reshape(xform_hbAvg,size(xform_hbAvg,1)*size(xform_hbAvg,2),size(xform_hbAvg,3),[]);
    
    xform_hbRoiAvgRun = squeeze(nanmean(xform_hbRoiAvgRun(roiRun,:,:),1)); % 2 x 60
    
    xform_hbRoiAvgBaseline = nanmean(xform_hbRoiAvgRun(:,1:floor(5*sessionInfo.freqout)),2);
    
    xform_hbRoiAvgRun = xform_hbRoiAvgRun - repmat(xform_hbRoiAvgBaseline,1,size(xform_hbRoiAvgRun,2));
        
    dataAvgRun = xform_hbRoiAvgRun;
    
    roi = cat(3,roi,roiRun);
    dataAvg = cat(3,dataAvg,dataAvgRun);
    stimResponse = cat(4,stimResponse,stimResponseRun);
    
end
%% plot fluor roi response
plotData = nanmean(dataAvg,3);

figure;
p1 = plot(blockTime,plotData(1,:),'r'); hold on;
p2 = plot(blockTime,plotData(2,:),'b');
p3 = plot(blockTime,sum(plotData(1:2,:),1),'k');
% ylim([-1.5E-6 3E-6]);
ylim([-3E-6 5E-6]);
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
% cLim = [-2 2; -2 2; -2 2]./1E6;
cLim = [-4 4; -4 4; -4 4]./1E6;
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
imagesc(mean(roi,3)); colormap(s4, 'parula'); axis(gca,'square'); xticklabels([]); yticklabels([]); colorbar;

% i = 5;
% s4 = subplot(3,2,i);
% imagesc(mean(vascular,3)); colormap(s4, 'parula'); axis(gca,'square'); xticklabels([]); yticklabels([]); colorbar;