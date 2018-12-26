% this script is a wrapper around gcampImaging.m function that shows how
% the function should be used. As shown, you state which tiff file to run,
% then get system and session information either via the functions
% sysInfo.m and session2procInfo.m or manual addition. Run the
% gcampImaging.m function afterwards and you are good to go!

dataAvg = [];
stimResponse = [];

for run = 1:3
    disp(num2str(run));
    
    %% state the tif file
    
    tiffFileName = strcat("L:\181126-166M3-stim",num2str(run),".tif");
    saveFileName = strcat("L:\181126-166M3-stim",num2str(run),"-processed.mat");
    
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
    sessionInfo = mouse.expSpecific.sesInfo('gcamp6f');
    sessionInfo.framerate = 23.5294;
    sessionInfo.lowpass = sessionInfo.framerate./2-0.1;
    sessionInfo.freqout = sessionInfo.framerate;
    
    %% get gcamp and hb data
    darkFrameNum = 118;
    
    if exist(saveFileName)
        load(saveFileName);
    else
        
        if exist('isbrain')
            % if brain mask and markers are available:
            [raw, time, xform_hb, xform_gcamp, xform_gcampCorr, isbrain, xform_isbrain, markers] ...
                = probe.probeImaging(tiffFileName, systemInfo, sessionInfo, isbrain, markers,'darkFrameNum',darkFrameNum);
        else
            [raw, time, xform_hb, xform_gcamp, xform_gcampCorr, isbrain, xform_isbrain, markers] ...
                = probe.probeImaging(tiffFileName, systemInfo, sessionInfo,'darkFrameNum',darkFrameNum);
        end
        % isbrain = logical nxn array of brain mask.
        % markers = the brain markers that are created during the whole GUI where
        % you click on the midline suture and lambda. If you do not have these,
        % just run the code without giving these inputs, go through the GUI, then
        % the code will output isbrain, xform_isbrain, and markers.
        
        save(saveFileName,'xform_hb','xform_gcamp','xform_gcampCorr','isbrain','xform_isbrain','markers','-v7.3');
    end
    %% gsr
    
    xform_hb = mouse.preprocess.gsr(xform_hb,xform_isbrain);
    xform_gcamp = mouse.preprocess.gsr(xform_gcamp,xform_isbrain);
    xform_gcampCorr = mouse.preprocess.gsr(xform_gcampCorr,xform_isbrain);
    
    %% filter
    
%     xform_hb = lowpass(xform_hb,0.5,sessionInfo.framerate);
    % to get rid of higher frequency nonneuronal factors
    
    %% get block avg
    
%     xform_hb = cat(4,zeros(size(xform_hb,1),size(xform_hb,2),size(xform_hb,3)),xform_hb);
%     xform_gcamp = cat(4,zeros(size(xform_gcamp,1),size(xform_gcamp,2),size(xform_gcamp,3)),xform_gcamp);
%     xform_gcampCorr = cat(4,zeros(size(xform_gcampCorr,1),size(xform_gcampCorr,2),size(xform_gcampCorr,3)),xform_gcampCorr);
    
    xform_hbAvg = reshape(xform_hb,size(xform_hb,1),size(xform_hb,2),size(xform_hb,3),707,[]);
    xform_gcampAvg = reshape(xform_gcamp,size(xform_gcamp,1),size(xform_gcamp,2),size(xform_gcamp,3),707,[]);
    xform_gcampCorrAvg = reshape(xform_gcampCorr,size(xform_gcampCorr,1),size(xform_gcampCorr,2),size(xform_gcampCorr,3),707,[]);
    
    xform_hbAvg = nanmean(xform_hbAvg,5);
    xform_gcampAvg = nanmean(xform_gcampAvg,5);
    xform_gcampCorrAvg = nanmean(xform_gcampCorrAvg,5);
    
%     xform_hbAvg = mouse.preprocess.blockAvg(xform_hb,time,30,30*sessionInfo.framerate);
%     xform_gcampAvg = mouse.preprocess.blockAvg(xform_gcamp,time,30,30*sessionInfo.framerate);
%     xform_gcampCorrAvg = mouse.preprocess.blockAvg(xform_gcampCorr,time,30,30*sessionInfo.framerate);
    blockTime = linspace(0,30,707+1); blockTime(end) = [];
    
    stimTime = (blockTime > 5 & blockTime <= 10);
    xform_hbStim = nanmean(xform_hbAvg(:,:,:,stimTime),4);
    xform_gcampStim = nanmean(xform_gcampAvg(:,:,:,stimTime),4);
    xform_gcampCorrStim = nanmean(xform_gcampCorrAvg(:,:,:,stimTime),4);
    stimResponseRun = cat(3,xform_hbStim,xform_gcampStim,xform_gcampCorrStim);
    
    %% get fluor roi response
    temp = xform_hbStim(:,:,1);
    temp([1:40 100:128],:) = [];
    temp(:,53:128) = [];
    threshold = 0.75*prctile(temp(:),95);
%     roiCandidates = xform_hbStim(:,:,1) >= threshold;
%     % roiCandidates(abs(xform_probeCorrStim) > 0.02) = false;
%     roiCandidates([1:40 100:128],:) = false;
%     roiCandidates(:,53:128) = false;
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
    
    load('roi.mat');
    
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
end 


%% plot fluor roi response
plotData = nanmean(dataAvg,3);

figure;
p1 = plot(blockTime,plotData(1,:),'r'); hold on;
p2 = plot(blockTime,plotData(2,:),'b');
p3 = plot(blockTime,sum(plotData(1:2,:),1),'k');
yLim = ylim(gca);
stimT = 5:1/3:10; stimT(end) = [];
for t = stimT
    plot([t t],yLim,'m');
end
legend([p1 p2 p3],["HbO","HbR","HbT"]);

figure;
p1 = plot(blockTime,plotData(3,:),'g'); hold on;
p2 = plot(blockTime,plotData(4,:),'k');
yLim = ylim(gca);
stimT = 5:1/3:10; stimT(end) = [];
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
figure;
for i = 1:4
    subplot(2,2,i);
    imagesc(sum(plotData(:,:,speciesInd{i}),3),'AlphaData',xform_isbrain>0,cLim(i,:));
    colormap('jet'); axis(gca,'square'); xticklabels([]); yticklabels([]);
    colorbar;
    title(titleArray(i));
end