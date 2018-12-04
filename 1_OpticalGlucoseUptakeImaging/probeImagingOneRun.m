% this script is a wrapper around gcampImaging.m function that shows how
% the function should be used. As shown, you state which tiff file to run,
% then get system and session information either via the functions
% sysInfo.m and session2procInfo.m or manual addition. Run the
% gcampImaging.m function afterwards and you are good to go!

%% state the tiff file

% tiffFileName = "L:\181121\181121-ProbeW7M1-Post.tif";
% tiffFileName = "J:\180813\180813-ProbeW3M1-Post.tif";
% tiffFileName = "\\10.39.168.176\RawData_East3410\181129\181129-ProbeW9M3-PostXiaodan.tif";
tiffFileName = "\\10.39.168.176\RawData_East3410\181204\181204-ProbeW9M1-Post.tif";

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
% sessionInfo.framerate = 23.5294;
sessionInfo.framerate = 5;
sessionInfo.freqout = sessionInfo.framerate;
sessionInfo.lowpass = sessionInfo.framerate/2 - 0.1;

%% get gcamp and hb data
darkFrameNum = 5*10;

if exist('isbrain')
    [raw, time, xform_hb, xform_probe, xform_probeCorr, isbrain, xform_isbrain, markers] ...
        = probe.probeImaging(tiffFileName, systemInfo, sessionInfo, isbrain, markers,'darkFrames',darkFrameNum);
else
    [raw, time, xform_hb, xform_probe, xform_probeCorr, isbrain, xform_isbrain, markers] ...
        = probe.probeImaging(tiffFileName, systemInfo, sessionInfo,'darkFrames',darkFrameNum);
end

% % if brain mask and markers are available:
% [raw, time, xform_hb, xform_probe, xform_probeCorr, isbrain, xform_isbrain, markers] ...
%     = probe.probeImaging(tiffFileName, systemInfo, sessionInfo, isbrain, markers,'darkTime',5);

% isbrain = logical nxn array of brain mask.
% markers = the brain markers that are created during the whole GUI where
% you click on the midline suture and lambda. If you do not have these,
% just run the code without giving these inputs, go through the GUI, then
% the code will output isbrain, xform_isbrain, and markers.

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

%% plot

figure;
plot(time,squeeze(xform_hb(79,95,1,:))*1000);
hold on; plot(time,squeeze(xform_hb(79,95,2,:))*1000);
hold on; plot(time,squeeze(xform_probe(79,95,1,:)));
hold on; plot(time,squeeze(xform_probeCorr(79,95,1,:)));
hold off;

legend('HbO (mM)','HbR (mM)','gcamp','gcamp corrected');

%% get block avg

xform_hbAvg = mouse.preprocess.blockAvg(xform_hb,time,60,60*4);
xform_probeAvg = mouse.preprocess.blockAvg(xform_probe,time,60,60*4);
xform_probeCorrAvg = mouse.preprocess.blockAvg(xform_probeCorr,time,60,60*4);
blockTime = linspace(0,60,60*4+1); blockTime(end) = [];

%% plot block avg

stimTime = (blockTime > 5 & blockTime <= 10);
xform_hbStim = nanmean(xform_hbAvg(:,:,:,stimTime),4);
xform_probeStim = nanmean(xform_probeAvg(:,:,:,stimTime),4);
xform_probeCorrStim = nanmean(xform_probeCorrAvg(:,:,:,stimTime),4);

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

%% get fluor roi response
temp = xform_probeCorrStim(:,:,1);
temp([1:40 100:128],:) = [];
temp(:,1:75) = [];
threshold = 0.75*prctile(temp(:),95);
roiCandidates = xform_probeCorrStim(:,:,1) >= threshold;
% roiCandidates(abs(xform_probeCorrStim) > 0.02) = false;
roiCandidates([1:40 100:128],:) = false;
roiCandidates(:,1:75) = false;

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
xform_probeRoiAvg = reshape(xform_probeAvg,size(xform_probeAvg,1)*size(xform_probeAvg,2),size(xform_probeAvg,3),[]);
xform_probeCorrRoiAvg = reshape(xform_probeCorrAvg,size(xform_probeCorrAvg,1)*size(xform_probeCorrAvg,2),size(xform_probeCorrAvg,3),[]);

xform_hbRoiAvg = squeeze(nanmean(xform_hbRoiAvg(roi,:,:),1)); % 2 x 60
xform_probeRoiAvg = squeeze(nanmean(xform_probeRoiAvg(roi,:,:),1))'; % 1 x 60
xform_probeCorrRoiAvg = squeeze(nanmean(xform_probeCorrRoiAvg(roi,:,:),1))'; % 1 x 60

xform_hbRoiAvgBaseline = nanmean(xform_hbRoiAvg(:,1:5),2);
xform_probeRoiAvgBaseline = nanmean(xform_probeRoiAvg(:,1:5),2);
xform_probeCorrRoiAvgBaseline = nanmean(xform_probeCorrRoiAvg(:,1:5),2);

xform_hbRoiAvg = xform_hbRoiAvg - repmat(xform_hbRoiAvgBaseline,1,size(xform_hbRoiAvg,2));
xform_probeRoiAvg = xform_probeRoiAvg - repmat(xform_probeRoiAvgBaseline,1,size(xform_probeRoiAvg,2));
xform_probeCorrRoiAvg = xform_probeCorrRoiAvg - repmat(xform_probeCorrRoiAvgBaseline,1,size(xform_probeCorrRoiAvg,2));

%% plot fluor roi response

figure;
plot(blockTime,1000*xform_hbRoiAvg(1,:),'r'); hold on;
plot(blockTime,1000*xform_hbRoiAvg(2,:),'b');
plot(blockTime,xform_probeRoiAvg,'g');
plot(blockTime,xform_probeCorrRoiAvg,'k');
legend(titleStr);