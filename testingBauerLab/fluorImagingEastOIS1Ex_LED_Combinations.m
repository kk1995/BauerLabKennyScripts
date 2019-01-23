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

for hbComb = 1:numel(hbCombs)
    disp(['ch combination # ' num2str(hbComb)]);
    sessionInfo.hbSpecies = hbCombs{hbComb};
    hbCombStr = num2str(hbCombs{hbComb}(1));
    for ch = 2:numel(hbCombs{hbComb})
        hbCombStr = strcat(hbCombStr,",",num2str(hbCombs{hbComb}(ch)));
    end
    saveFileName = strcat(saveFilePrefix,num2str(run),"-processed-",hbCombStr,".mat");
    
    [xform_hb,xform_gcamp,xform_gcampCorr] = fluor.process(data,systemInfo,sessionInfo,xform_isbrain);
       
    save(saveFileName,'time','xform_hb','xform_gcamp','xform_gcampCorr',...
        'isbrain','xform_isbrain','affineMarkers','sessionInfo','-v7.3');
    
    %% gsr
    
    xform_hb = mouse.preprocess.gsr(xform_hb,xform_isbrain);
    
    
    %% filter
    
    xform_hb = lowpass(xform_hb,0.49,sessionInfo.framerate);
    xform_hb = highpass(xform_hb,0.009,sessionInfo.framerate);
    % to get rid of higher frequency nonneuronal factors
    
    %% get block avg
    freqOut = 8;
    xform_hbAvg = mouse.preprocess.blockAvg(xform_hb,time,60,60*freqOut);
    blockTime = linspace(0,60,60*8+1); blockTime(end) = [];
    
    stimTime = (blockTime > 5 & blockTime <= 15);
    xform_hbStim = nanmean(xform_hbAvg(:,:,:,stimTime),4);
    stimResponseRun = xform_hbStim;
    
    %% get fluor roi response
    
    % find the center coordinate of activation
    roiMap = abs(xform_hbStim(:,:,1));
%     roiMapSub = zeros(size(roiMap)); roiMapSub(30:110,1:50) = roiMap(30:110,1:50);
%     centerCoor = find(roiMapSub == max(roiMapSub(:)));
%     centerCoor = [mod(centerCoor-1,size(roiMap,1))+1, floor(centerCoor/size(roiMap,1))];
    centerCoor = [60 31];
    
    % find coordinates above the threshold
    coor = mouse.plot.circleCoor(centerCoor,20);
    coor = coor(1,:)+size(xform_hb,2)*coor(2,:);
    inCoor = false(size(xform_hb,2));
    inCoor(coor) = true;
    threshold = 0.75*prctile(roiMap(coor),95);
    
    roiCandidates = roiMap >= threshold;
    roiCandidates(~inCoor) = false;
    
    % choose largest cluster
    clusters = bwconncomp(roiCandidates,4);
    clusterSizes = nan(clusters.NumObjects,1);
    for clusterInd = 1:clusters.NumObjects
        clusterSizes(clusterInd) = numel(clusters.PixelIdxList{clusterInd});
    end
    maxClusterSize = max(clusterSizes);
    roi = false(size(roiCandidates));
    roi(clusters.PixelIdxList{clusterSizes==maxClusterSize}) = true;
    
    xform_hbRoiAvgRun = reshape(xform_hbAvg,size(xform_hbAvg,1)*size(xform_hbAvg,2),size(xform_hbAvg,3),[]);
    xform_hbRoiAvgRun = squeeze(nanmean(xform_hbRoiAvgRun(roi,:,:),1)); % 2 x 60
    
    xform_hbRoiAvgBaseline = nanmean(xform_hbRoiAvgRun(:,1:floor(5*freqOut)),2);
    
    xform_hbRoiAvgRun = xform_hbRoiAvgRun - repmat(xform_hbRoiAvgBaseline,1,size(xform_hbRoiAvgRun,2));
    
    %% plot
    plotData = nanmean(xform_hbRoiAvgRun,3);
    f1 = figure;
    p1 = plot(blockTime,plotData(1,:),'r'); hold on;
    p2 = plot(blockTime,plotData(2,:),'b');
    p3 = plot(blockTime,sum(plotData(1:2,:),1),'k');
    ylim([-3E-6 3E-6]);
    yLim = ylim(gca);
    stimT = [5 15];
    for t = stimT
        plot([t t],yLim,'m');
    end
    legend([p1 p2 p3],["HbO","HbR","HbT"]);
    
    figFileName1 = strcat(figFilePrefix,num2str(run),"-blockAvg-",hbCombStr,".fig");
    
    savefig(f1,figFileName1);
    
    %% plot stim response
    
    plotData = nanmean(stimResponseRun,4);
    speciesInd = {[1],[2],[1,2],[4]};
    titleArray = ["HbO","HbR","HbT","fluor corrected"];
    cLim = [-0.5 0.5; -0.5 0.5; -0.5 0.5; -5E3 5E3]./1E6;
    f2 = figure;
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
    
    figFileName2 = strcat(figFilePrefix,num2str(run),"-stimResponse-",hbCombStr,".fig");
    
    savefig(f2,figFileName2);
end