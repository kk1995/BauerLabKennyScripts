% this script is a wrapper around gcampImaging.m function that shows how
% the function should be used. As shown, you state which tiff file to run,
% then get system and session information either via the functions
% sysInfo.m and session2procInfo.m or manual addition. Run the
% gcampImaging.m function afterwards and you are good to go!

saveFileName = "181204-ProbeW9M1-Post_preprocessed.mat";
% saveDir = "D:\data\6-nbdg";
saveDir = "D:\data\wildType";
%% state the tiff file

tiffFileName = ["\\10.39.168.176\RawData_East3410\181204\181204-ProbeW9M1-Post.tif"];

% tiffFileName = ["J:\180713\180713-NewProbeM4W5Post.tif" ...
%     "J:\180713\180713-NewProbeM4W5Post_X2.tif" ...
%     "J:\180713\180713-NewProbeM4W5Post_X3.tif" ...
%     "J:\180713\180713-NewProbeM4W5Post_X4.tif"];

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
sessionInfo = mouse.expSpecific.sesInfo('none');
% sessionInfo.framerate = 23.5294;
sessionInfo.framerate = 5;
sessionInfo.freqout = 5;
sessionInfo.lowpass = sessionInfo.framerate/2 - 0.1;

%% get gcamp and hb data
darkFrameNum = 5*10;

if exist('isbrain')
    [raw, time, xform_hb, xform_probe, xform_probeCorr, isbrain, xform_isbrain, markers] ...
        = probe.probeImaging(tiffFileName, systemInfo, sessionInfo, isbrain, markers,'darkFrameNum',darkFrameNum);
else
    [raw, time, xform_hb, xform_probe, xform_probeCorr, isbrain, xform_isbrain, markers] ...
        = probe.probeImaging(tiffFileName, systemInfo, sessionInfo,'darkFrameNum',darkFrameNum);
end

% % if brain mask and markers are available:
% [raw, time, xform_hb, xform_probe, xform_probeCorr, isbrain, xform_isbrain, markers] ...
%     = probe.probeImaging(tiffFileName, systemInfo, sessionInfo, isbrain, markers,'darkTime',5);

% isbrain = logical nxn array of brain mask.
% markers = the brain markers that are created during the whole GUI where
% you click on the midline suture and lambda. If you do not have these,
% just run the code without giving these inputs, go through the GUI, then
% the code will output isbrain, xform_isbrain, and markers.

%% save

save(fullfile(saveDir,saveFileName),'sessionInfo','xform_hb','xform_probe','time','xform_probeCorr','isbrain','xform_isbrain','markers','-v7.3');

%% gsr

xform_hb = mouse.preprocess.gsr(xform_hb,xform_isbrain);
xform_probe = mouse.preprocess.gsr(xform_probe,xform_isbrain);
xform_probeCorr = mouse.preprocess.gsr(xform_probeCorr,xform_isbrain);

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
    plot(time,plotData);
    text(0.8,0.85,varianceText,'Units','normalized');
end

%% get block avg

xform_hbBlock = mouse.preprocess.blockAvg(xform_hb,time,60,60*5);
xform_probeBlock = mouse.preprocess.blockAvg(xform_probe,time,60,60*5);
xform_probeCorrBlock = mouse.preprocess.blockAvg(xform_probeCorr,time,60,60*5);
blockTime = linspace(0,60,60*5+1); blockTime(end) = [];

%% plot block avg

stimTime = (blockTime > 5 & blockTime <= 10);
xform_hbStim = nanmean(xform_hbBlock(:,:,:,stimTime),4);
xform_probeStim = nanmean(xform_probeBlock(:,:,:,stimTime),4);
xform_probeCorrStim = nanmean(xform_probeCorrBlock(:,:,:,stimTime),4);

plotData = cat(3,1000*xform_hbStim,xform_probeStim,xform_probeCorrStim);
% cLim = [-0.002 0.002; -0.002 0.002; -0.002 0.002; -0.005 0.005];
% cLim = [-0.02 0.02; -0.02 0.02; -0.01 0.01; -0.07 0.07];
cLim = [-0.005 0.005; -0.005 0.005; -0.01 0.01; -0.03 0.03];

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
temp = xform_probeCorrStim(:,:,1);
temp(~xform_isbrain) = nan;
vascularMask = false(128);
vascularMask(1:25,:) = true;
vascularMask(:,64-5:64+5) = true;
vascularMask(~xform_isbrain) = false;
temp(vascularMask) = nan;
threshold = 0.75*prctile(temp(:),95);
roiCandidates = xform_probeCorrStim(:,:,1) >= threshold;
% roiCandidates(abs(xform_probeCorrStim) > 0.02) = false;
roiCandidates(~xform_isbrain) = false;
roiCandidates(vascularMask) = false;

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

xform_hbRoi = reshape(xform_hb,size(xform_hb,1)*size(xform_hb,2),size(xform_hb,3),[]);
xform_probeRoi = reshape(xform_probe,size(xform_probe,1)*size(xform_probe,2),size(xform_probe,3),[]);
xform_probeCorrRoi = reshape(xform_probeCorr,size(xform_probeCorr,1)*size(xform_probeCorr,2),size(xform_probeCorr,3),[]);

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
legend('probe','probe corrected');

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
legend('probe','probe corrected');

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

xform_hbRoiBlock = squeeze(nanmean(xform_hbRoiBlock(roi,:,:),1)); % 2 x 60
xform_probeRoiBlock = squeeze(nanmean(xform_probeRoiBlock(roi,:,:),1))'; % 1 x 60
xform_probeCorrRoiBlock = squeeze(nanmean(xform_probeCorrRoiBlock(roi,:,:),1))'; % 1 x 60

xform_hbRoiAvgBaseline = nanmean(xform_hbRoiBlock(:,1:5),2);
xform_probeRoiAvgBaseline = nanmean(xform_probeRoiBlock(:,1:5),2);
xform_probeCorrRoiAvgBaseline = nanmean(xform_probeCorrRoiBlock(:,1:5),2);

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