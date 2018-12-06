% this script is a wrapper around gcampImaging.m function that shows how
% the function should be used. As shown, you state which tiff file to run,
% then get system and session information either via the functions
% sysInfo.m and session2procInfo.m or manual addition. Run the
% gcampImaging.m function afterwards and you are good to go!

dataAvg = [];

for run = 1:3
    
    %% state the tif file
    
    tiffFileName = strcat("L:\GCaMP\181031-GCampM2-stim",num2str(run),".tif");
    
    %% get system or session information.
    
    % use the pre-existing system and session information by selecting the type
    % of system and the type of session. If the system or session you are using
    % do not fit the existing choices, you can either add new system and
    % session types or add them manually.
    % for systemInfo, you need rgb and LEDFiles
    % for sessionInfo, you need framerate, freqout, lowpass, and highpass
    
    % systemType = 'fcOIS1', 'fcOIS2', 'fcOIS2_Fluor' or 'EastOIS1_Fluor'
    systemInfo = mouse.expSpecific.sysInfo('EastOIS1_Fluor');
    
    % sessionType = 'fc' or 'stim'
    sessionInfo = mouse.expSpecific.session2procInfo('stim');
    sessionInfo.framerate = 16.8;
    sessionInfo.lowpass = sessionInfo.framerate./2-0.1;
    sessionInfo.freqout = sessionInfo.framerate;
    
    %% get gcamp and hb data
    
    if exist('isbrain')
        % if brain mask and markers are available:
        [raw, time, xform_hb, xform_gcamp, xform_gcampCorr, isbrain, xform_isbrain, markers] ...
            = gcamp.gcampImaging(tiffFileName, systemInfo, sessionInfo, isbrain, markers,'darkFrames',0);
    else
        [raw, time, xform_hb, xform_gcamp, xform_gcampCorr, isbrain, xform_isbrain, markers] ...
            = gcamp.gcampImaging(tiffFileName, systemInfo, sessionInfo,'darkFrames',0);
    end
    % isbrain = logical nxn array of brain mask.
    % markers = the brain markers that are created during the whole GUI where
    % you click on the midline suture and lambda. If you do not have these,
    % just run the code without giving these inputs, go through the GUI, then
    % the code will output isbrain, xform_isbrain, and markers.
    
    %% gsr
    
    xform_hb = mouse.preprocess.gsr(xform_hb,xform_isbrain);
    xform_gcamp = mouse.preprocess.gsr(xform_gcamp,xform_isbrain);
    xform_gcampCorr = mouse.preprocess.gsr(xform_gcampCorr,xform_isbrain);
    
    %% filter
    
    xform_hb = lowpass(xform_hb,0.5,sessionInfo.framerate);
    % to get rid of higher frequency nonneuronal factors
    
    %% get block avg
    
    xform_hb = cat(4,zeros(size(xform_hb,1),size(xform_hb,2),size(xform_hb,3)),xform_hb);
    xform_gcamp = cat(4,zeros(size(xform_gcamp,1),size(xform_gcamp,2),size(xform_gcamp,3)),xform_gcamp);
    xform_gcampCorr = cat(4,zeros(size(xform_gcampCorr,1),size(xform_gcampCorr,2),size(xform_gcampCorr,3)),xform_gcampCorr);
    
    xform_hbAvg = reshape(xform_hb,size(xform_hb,1),size(xform_hb,2),size(xform_hb,3),30*sessionInfo.framerate,[]);
    xform_gcampAvg = reshape(xform_gcamp,size(xform_gcamp,1),size(xform_gcamp,2),size(xform_gcamp,3),30*sessionInfo.framerate,[]);
    xform_gcampCorrAvg = reshape(xform_gcampCorr,size(xform_gcampCorr,1),size(xform_gcampCorr,2),size(xform_gcampCorr,3),30*sessionInfo.framerate,[]);
    
    xform_hbAvg = nanmean(xform_hbAvg,5);
    xform_gcampAvg = nanmean(xform_gcampAvg,5);
    xform_gcampCorrAvg = nanmean(xform_gcampCorrAvg,5);
    
%     xform_hbAvg = mouse.preprocess.blockAvg(xform_hb,time,30,30*sessionInfo.framerate);
%     xform_gcampAvg = mouse.preprocess.blockAvg(xform_gcamp,time,30,30*sessionInfo.framerate);
%     xform_gcampCorrAvg = mouse.preprocess.blockAvg(xform_gcampCorr,time,30,30*sessionInfo.framerate);
    blockTime = linspace(0,30,30*sessionInfo.framerate+1); blockTime(end) = [];
    
    stimTime = (blockTime > 5 & blockTime <= 10);
    xform_hbStim = nanmean(xform_hbAvg(:,:,:,stimTime),4);
    xform_gcampStim = nanmean(xform_gcampAvg(:,:,:,stimTime),4);
    xform_gcampCorrStim = nanmean(xform_gcampCorrAvg(:,:,:,stimTime),4);
    
    %% get fluor roi response
    temp = xform_hbStim(:,:,1);
    temp([1:40 100:128],:) = [];
    temp(:,53:128) = [];
    threshold = 0.75*prctile(temp(:),95);
    roiCandidates = xform_hbStim(:,:,1) >= threshold;
    % roiCandidates(abs(xform_probeCorrStim) > 0.02) = false;
    roiCandidates([1:40 100:128],:) = false;
    roiCandidates(:,53:128) = false;
    
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
end

plotData = nanmean(dataAvg,3);

%% plot fluor roi response

figure;
p1 = plot(blockTime,1000*plotData(1,:),'r'); hold on;
p2 = plot(blockTime,1000*plotData(2,:),'b');
p3 = plot(blockTime,plotData(3,:),'g');
p4 = plot(blockTime,plotData(4,:),'k');
yLim = ylim(gca);
stimT = 5:1/3:10; stimT(end) = [];
for t = stimT
    plot([t t],yLim,'m');
end
legend([p1 p2 p3 p4],["HbO","HbR","fluor","corrected"]);