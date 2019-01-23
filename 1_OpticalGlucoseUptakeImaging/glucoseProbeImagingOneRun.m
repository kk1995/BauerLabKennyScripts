
import mouse.*

tiffFileName = ["J:\180713\180713-NewProbeM3W5Post.tif" ...
    "J:\180713\180713-NewProbeM3W5Post_X2.tif" ...
    "J:\180713\180713-NewProbeM3W5Post_X3.tif" ...
    "J:\180713\180713-NewProbeM3W5Post_X4.tif"];
saveFileName = "180713-NewProbeM3W5-Post-processed.mat";
saveMaskFile = "180713-NewProbeM3W5-Post-mask.mat";
saveDir = "D:\data\6-nbdg";

speciesNum = 4;
systemInfo = mouse.expSpecific.sysInfo('fcOIS2_Fluor');
sessionInfo = mouse.expSpecific.sesInfo('6-nbdg');
sessionInfo.framerate = 16.8;
sessionInfo.freqout = 2;

darkFrameInd = [];

blockDuration = 60; % time per block in seconds.
stimTimeLim = [5 10]; % stimulation period within the block.
% 1st value is start of stim, 2nd value is end of stim.

centerCoor = [80 103];

%% load and process data if not done already

if ~exist(fullfile(saveDir,saveFileName))
    
    %% get raw data
    
    disp('get raw data');
    
    [raw, rawTime] = read.readRaw(tiffFileName,speciesNum,systemInfo.readFcn,...
        sessionInfo.framerate,sessionInfo.freqout);
    
    if ~exist(saveMaskFile)
        rgbOrder = systemInfo.rgb;
        wl = preprocess.getWL(raw,darkFrameInd,rgbOrder);
        [isbrain, affineMarkers] = preprocess.getLandmarksAndMask(wl);
        save(saveMaskFile,'isbrain','affineMarkers');
    else
        load(saveMaskFile);
    end
    
    %% preprocess and process
    
    disp('process and preprocess')
    
    [time,data] = fluor.preprocess(rawTime,raw,systemInfo,sessionInfo,...
        affineMarkers,'darkFrameInd',darkFrameInd);
    xform_isbrain = preprocess.affineTransform(isbrain,affineMarkers);
    
    [xform_hb,xform_gcamp,xform_gcampCorr] = fluor.process(data,systemInfo,sessionInfo,xform_isbrain);
    %% save
    
    disp('save');
    
    save(fullfile(saveDir,saveFileName),'time','xform_hb','xform_gcamp',...
        'xform_gcampCorr','isbrain','xform_isbrain','affineMarkers','-v7.3');
else
    load(fullfile(saveDir,saveFileName));
end

%% gsr

disp('gsr');

xform_hb = mouse.preprocess.gsr(xform_hb,xform_isbrain);
xform_gcamp = mouse.preprocess.gsr(xform_gcamp,xform_isbrain);
xform_gcampCorr = mouse.preprocess.gsr(xform_gcampCorr,xform_isbrain);

%% get block avg

disp('get block average');

xform_hbBlock = mouse.preprocess.blockAvg(xform_hb,time,...
    blockDuration,blockDuration*sessionInfo.freqout);
xform_probeBlock = mouse.preprocess.blockAvg(xform_gcamp,time,...
    blockDuration,blockDuration*sessionInfo.freqout);
xform_probeCorrBlock = mouse.preprocess.blockAvg(xform_gcampCorr,time,...
    blockDuration,blockDuration*sessionInfo.freqout);
blockTime = linspace(0,blockDuration,blockDuration*sessionInfo.freqout+1); blockTime(1) = [];

%% plot raw
figure;
p = panel(); p.pack(4,1); p.margin = [10 5 10 5];
for i = 1:4
    p(i,1).select();
    plotData = reshape(raw(:,:,i,:),128*128,size(raw,4));
    plotData = plotData(logical(isbrain),:);
    plotData = mean(plotData,1);
    variance = std(plotData,0,2);
    varianceRatio = variance/mean(plotData);
    varianceText = strcat("s.d./mu = ", num2str(varianceRatio,'%.3f'));
    plot(rawTime,plotData);
    text(0.8,0.85,varianceText,'Units','normalized');
end

%% plot block avg

stimTime = (blockTime > stimTimeLim(1) & blockTime <= stimTimeLim(2));
xform_hbStim = nanmean(xform_hbBlock(:,:,:,stimTime),4);
xform_probeStim = nanmean(xform_probeBlock(:,:,:,stimTime),4);
xform_probeCorrStim = nanmean(xform_probeCorrBlock(:,:,:,stimTime),4);

plotData = cat(3,xform_hbStim,xform_probeStim,xform_probeCorrStim);
cLim = [-1E-6 1E-6; -1E-6 1E-6; -0.01 0.01; -0.02 0.02];

titleStr = ["HbO","HbR","fluor","corrected"];
figure;
p2 = panel(); p2.pack(2,2); p2.margin = [5 5 5 5];
for i = 1:4
    row = ceil(i/2); col = mod(i-1,2)+1;
    p2(row,col).select();
    imagesc(plotData(:,:,i),'AlphaData',xform_isbrain,cLim(i,:));
    set(gca,'Ydir','reverse')
    hold on; title(titleStr(i));
    colormap('jet'); colorbar;
    axis(gca,'square');
    xlim([0 129]); ylim([0 129]);
    set(gca,'Xtick',[]); set(gca,'Ytick',[]);
end

%% get roi

roiMap = xform_hbStim(:,:,1);

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

%% plot roi avg

figure;
imagesc(roi); axis(gca,'square'); xticklabels([]); yticklabels([]);

xform_hbRoi = reshape(xform_hb,size(xform_hb,1)*size(xform_hb,2),size(xform_hb,3),[]);
xform_probeRoi = reshape(xform_gcamp,size(xform_gcamp,1)*size(xform_gcamp,2),size(xform_gcamp,3),[]);
xform_probeCorrRoi = reshape(xform_gcampCorr,size(xform_gcampCorr,1)*size(xform_gcampCorr,2),size(xform_gcampCorr,3),[]);

xform_hbNotRoi = squeeze(nanmean(xform_hbRoi(~roi & xform_isbrain,:,:),1)); % 2 x time
xform_probeNotRoi = squeeze(nanmean(xform_probeRoi(~roi & xform_isbrain,:,:),1))'; % 1 x time
xform_probeCorrNotRoi = squeeze(nanmean(xform_probeCorrRoi(~roi & xform_isbrain,:,:),1))'; % 1 x time

xform_hbRoi = squeeze(nanmean(xform_hbRoi(roi,:,:),1)); % 2 x time
xform_probeRoi = squeeze(nanmean(xform_probeRoi(roi,:,:),1))'; % 1 x time
xform_probeCorrRoi = squeeze(nanmean(xform_probeCorrRoi(roi,:,:),1))'; % 1 x time

figure;
s1 = subplot(2,1,1);
plot(time,xform_hbRoi(1,:)*1000,'r');
hold on; plot(time,xform_hbRoi(2,:)*1000,'b');
hold on; plot(time,(xform_hbRoi(1,:)+xform_hbRoi(2,:))*1000,'k');
legend('HbO (mM)','HbR (mM)','HbT (mM)');
s2 = subplot(2,1,2);
hold on; plot(time,xform_probeRoi,'g');
hold on; plot(time,xform_probeCorrRoi,'m');
hold off;
legend('fluor','fluor corrected');

figure;
s3 = subplot(2,1,1);
plot(time,xform_hbNotRoi(1,:)*1000,'r');
hold on; plot(time,xform_hbNotRoi(2,:)*1000,'b');
hold on; plot(time,(xform_hbNotRoi(1,:)+xform_hbNotRoi(2,:))*1000,'k');
legend('HbO (mM)','HbR (mM)','HbT (mM)');
s4 = subplot(2,1,2);
hold on; plot(time,xform_probeNotRoi,'g');
hold on; plot(time,xform_probeCorrNotRoi,'m');
hold off;
legend('fluor','fluor corrected');

yLimHb1 = ylim(s1);
yLimHb2 = ylim(s3);
yLimProbe1 = ylim(s2);
yLimProbe2 = ylim(s4);

yLimHb = [min([yLimHb1(1) yLimHb2(1)]) max([yLimHb1(2) yLimHb2(2)])];
yLimProbe = [min([yLimProbe1(1) yLimProbe2(1)]) max([yLimProbe1(2) yLimProbe2(2)])];

ylim(s1,yLimHb);
ylim(s3,yLimHb);
ylim(s2,yLimProbe);
ylim(s4,yLimProbe);

%% get roi block avg

xform_hbRoiBlock = reshape(xform_hbBlock,size(xform_hbBlock,1)*size(xform_hbBlock,2),size(xform_hbBlock,3),[]);
xform_probeRoiBlock = reshape(xform_probeBlock,size(xform_probeBlock,1)*size(xform_probeBlock,2),size(xform_probeBlock,3),[]);
xform_probeCorrRoiBlock = reshape(xform_probeCorrBlock,size(xform_probeCorrBlock,1)*size(xform_probeCorrBlock,2),size(xform_probeCorrBlock,3),[]);

xform_hbRoiBlock = squeeze(nanmean(xform_hbRoiBlock(roi,:,:),1)); % 2 x 60*sessionInfo.freqout
xform_probeRoiBlock = squeeze(nanmean(xform_probeRoiBlock(roi,:,:),1))'; % 1 x 60*sessionInfo.freqout
xform_probeCorrRoiBlock = squeeze(nanmean(xform_probeCorrRoiBlock(roi,:,:),1))'; % 1 x 60*sessionInfo.freqout

xform_hbRoiAvgBaseline = nanmean(xform_hbRoiBlock(:,1:stimTimeLim(1)*sessionInfo.freqout),2);
xform_probeRoiAvgBaseline = nanmean(xform_probeRoiBlock(:,1:stimTimeLim(1)*sessionInfo.freqout),2);
xform_probeCorrRoiAvgBaseline = nanmean(xform_probeCorrRoiBlock(:,1:stimTimeLim(1)*sessionInfo.freqout),2);

xform_hbRoiBlock = xform_hbRoiBlock - repmat(xform_hbRoiAvgBaseline,1,size(xform_hbRoiBlock,2));
xform_probeRoiBlock = xform_probeRoiBlock - repmat(xform_probeRoiAvgBaseline,1,size(xform_probeRoiBlock,2));
xform_probeCorrRoiBlock = xform_probeCorrRoiBlock - repmat(xform_probeCorrRoiAvgBaseline,1,size(xform_probeCorrRoiBlock,2));

%% plot fluor roi response

figure;
plot(blockTime,1000*xform_hbRoiBlock(1,:),'r'); hold on;
plot(blockTime,1000*xform_hbRoiBlock(2,:),'b');
plot(blockTime,1000*(xform_hbRoiBlock(1,:)+xform_hbRoiBlock(2,:)),'k');
plot(blockTime,xform_probeRoiBlock,'g');
plot(blockTime,xform_probeCorrRoiBlock,'m');
legend('HbO (mM)','HbR (mM)','HbT (mM)','fluor','fluor corrected');
ylim([-0.01 0.02]);