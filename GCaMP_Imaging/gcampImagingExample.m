% this script is a wrapper around gcampImaging.m function that shows how
% the function should be used. As shown, you state which tiff file to run,
% then get system and session information either via the functions
% sysInfo.m and session2procInfo.m or manual addition. Run the
% gcampImaging.m function afterwards and you are good to go!

%% state the tiff file

% tiffFileName = "L:\GCaMP\181031-GCampM2-stim1.tif";
% tiffFileName = "L:\181121\181121-ProbeW7M1-Post.tif";
% tiffFileName = "M:\181029-MvF195-1-fc1.mat";
tiffFileName = "D:\data\temp\170621\170621-astro313-stim2.tif";

%% get system or session information.

% use the pre-existing system and session information by selecting the type
% of system and the type of session. If the system or session you are using
% do not fit the existing choices, you can either add new system and
% session types or add them manually.
% for systemInfo, you need rgb and LEDFiles
% for sessionInfo, you need framerate, freqout, lowpass, and highpass

% systemType = 'fcOIS1', 'fcOIS2', 'fcOIS2_Fluor' or 'EastOIS1_Fluor'
systemInfo = mouse.expSpecific.sysInfo('fcOIS3');

% sessionType = 'fc' or 'stim'
sessionInfo = mouse.expSpecific.session2procInfo('stim');
sessionInfo.framerate = 16.8;
sessionInfo.lowpass = sessionInfo.framerate./2-0.1;
sessionInfo.freqout = sessionInfo.framerate;

%% get gcamp and hb data

darkFrameNum = 0*sessionInfo.framerate;

[raw, time, xform_hb, xform_gcamp, xform_gcampCorr, isbrain, xform_isbrain, markers] ...
    = gcamp.gcampImaging(tiffFileName, systemInfo, sessionInfo,'darkFrames',darkFrameNum);

% % if brain mask and markers are available:
% [raw, time, xform_hb, xform_gcamp, xform_gcampCorr, isbrain, xform_isbrain, markers] ...
%     = gcamp.gcampImaging(tiffFileName, systemInfo, sessionInfo, isbrain, markers);

% isbrain = logical nxn array of brain mask.
% markers = the brain markers that are created during the whole GUI where
% you click on the midline suture and lambda. If you do not have these,
% just run the code without giving these inputs, go through the GUI, then
% the code will output isbrain, xform_isbrain, and markers.

%% gsr

xform_hb = mouse.preprocess.gsr(xform_hb,xform_isbrain);
xform_gcamp = mouse.preprocess.gsr(xform_gcamp,xform_isbrain);
xform_gcampCorr = mouse.preprocess.gsr(xform_gcampCorr,xform_isbrain);

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

%% plot

figure;
plot(time,squeeze(xform_hb(79,34,1,:))*1000);
hold on; plot(time,squeeze(xform_hb(79,34,2,:))*1000);
hold on; plot(time,squeeze(xform_gcamp(79,34,1,:)));
hold on; plot(time,squeeze(xform_gcampCorr(79,34,1,:)));
hold off;

legend('HbO (mM)','HbR (mM)','gcamp','gcamp corrected');

%% get block avg

xform_hbAvg = cat(4,xform_hb(:,:,:,1),xform_hb);
xform_gcampAvg = cat(4,xform_gcamp(:,:,:,1),xform_gcamp);
xform_gcampCorrAvg = cat(4,xform_gcampCorr(:,:,:,1),xform_gcampCorr);

xform_hbAvg = nanmean(reshape(xform_hbAvg,128,128,2,30*sessionInfo.framerate,[]),5);
xform_gcampAvg = nanmean(reshape(xform_gcampAvg,128,128,1,30*sessionInfo.framerate,[]),5);
xform_gcampCorrAvg = nanmean(reshape(xform_gcampCorrAvg,128,128,1,30*sessionInfo.framerate,[]),5);

% xform_hbAvg = mouse.preprocess.blockAvg(xform_hb,time,30,30*floor(sessionInfo.framerate));
% xform_gcampAvg = mouse.preprocess.blockAvg(xform_gcamp,time,30,30*floor(sessionInfo.framerate));
% xform_gcampCorrAvg = mouse.preprocess.blockAvg(xform_gcampCorr,time,30,30*floor(sessionInfo.framerate));
blockTime = linspace(1,30,30*sessionInfo.framerate);

%% plot block avg

stimTime = (blockTime > 5 & blockTime <= 10);
xform_hbStim = nanmean(xform_hbAvg(:,:,:,stimTime),4);
xform_gcampStim = nanmean(xform_gcampAvg(:,:,:,stimTime),4);
xform_gcampCorrStim = nanmean(xform_gcampCorrAvg(:,:,:,stimTime),4);

plotData = cat(3,1000*xform_hbStim,xform_gcampStim,xform_gcampCorrStim);
cLim = [-0.003 0.003; -0.003 0.003; -0.01 0.01; -0.03 0.03];

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

%% get fluor roi response
temp = xform_gcampCorrStim(:,:,1);
temp(abs(temp) > 0.15) = nan;
temp(~xform_isbrain) = nan;
% temp([1:40 100:128],:) = [];
% temp(:,53:128) = [];
temp(isnan(temp)) = [];
threshold = 0.8*prctile(temp(:),95);
roiCandidates = xform_gcampCorrStim(:,:,1) >= threshold;
roiCandidates(~xform_isbrain) = false;
% roiCandidates(abs(xform_probeCorrStim) > 0.02) = false;
roiCandidates([1:40 100:128],:) = false;
roiCandidates(:,50:128) = false;

% choose largest cluster
clusters = bwconncomp(roiCandidates,4);
clusterSizes = nan(clusters.NumObjects,1);
for clusterInd = 1:clusters.NumObjects
    clusterSizes(clusterInd) = numel(clusters.PixelIdxList{clusterInd});
end
maxClusterSize = max(clusterSizes);
roi = false(size(roiCandidates));
roi(clusters.PixelIdxList{clusterSizes==maxClusterSize}) = true;

xform_hbRoiAvg = reshape(xform_hbAvg,size(xform_hbAvg,1)*size(xform_hbAvg,2),size(xform_hbAvg,3),[]);
xform_gcampRoiAvg = reshape(xform_gcampAvg,size(xform_gcampAvg,1)*size(xform_gcampAvg,2),size(xform_gcampAvg,3),[]);
xform_gcampCorrRoiAvg = reshape(xform_gcampCorrAvg,size(xform_gcampCorrAvg,1)*size(xform_gcampCorrAvg,2),size(xform_gcampCorrAvg,3),[]);

xform_hbRoiAvg = squeeze(nanmean(xform_hbRoiAvg(roi,:,:),1)); % 2 x 60
xform_gcampRoiAvg = squeeze(nanmean(xform_gcampRoiAvg(roi,:,:),1))'; % 1 x 60
xform_gcampCorrRoiAvg = squeeze(nanmean(xform_gcampCorrRoiAvg(roi,:,:),1))'; % 1 x 60

xform_hbRoiAvgBaseline = nanmean(xform_hbRoiAvg(:,1:5*sessionInfo.framerate),2);
xform_gcampRoiAvgBaseline = nanmean(xform_gcampRoiAvg(:,1:5*sessionInfo.framerate),2);
xform_gcampCorrRoiAvgBaseline = nanmean(xform_gcampCorrRoiAvg(:,1:5*sessionInfo.framerate),2);

xform_hbRoiAvg = xform_hbRoiAvg - repmat(xform_hbRoiAvgBaseline,1,size(xform_hbRoiAvg,2));
xform_gcampRoiAvg = xform_gcampRoiAvg - repmat(xform_gcampRoiAvgBaseline,1,size(xform_gcampRoiAvg,2));
xform_gcampCorrRoiAvg = xform_gcampCorrRoiAvg - repmat(xform_gcampCorrRoiAvgBaseline,1,size(xform_gcampCorrRoiAvg,2));

%% plot fluor roi response

figure;
p1 = plot(blockTime,1000*xform_hbRoiAvg(1,:),'r'); hold on;
p2 = plot(blockTime,1000*xform_hbRoiAvg(2,:),'b');
p3 = plot(blockTime,xform_gcampRoiAvg,'g');
p4 = plot(blockTime,xform_gcampCorrRoiAvg,'k');
yLim = ylim(gca);
stimT = 5:1/3:10; stimT(end) = [];
for t = stimT
    plot([t t],yLim,'m');
end
legend(titleStr);
xlim([blockTime(1) blockTime(end)]);