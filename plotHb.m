tiffFileName = "L:\181126-166M3-stim1.tif";
sR = 0.2/0.0085;

%% get procOIS data

info.highpass = 0.009;
info.framerate = sR;
info.framerate = sR;
info.freqout = sR;
info.lowpass = sR./2 - 0.1;

dataHb = procOISData_Kenny_118Dark(char(tiffFileName),info,'EastOIS1');
dataHb = real(dataHb);

yLim = [-0.04 0.04];

%% get hb data through kenny's processing

yLim = [-0.04 0.04]./1000;

systemInfo = mouse.expSpecific.sysInfo('EastOIS1_Fluor');
sessionInfo = mouse.expSpecific.sesInfo('6-nbdg');
sessionInfo.framerate = sR;
sessionInfo.lowpass = sR./2-0.1;
sessionInfo.freqout = sR;

darkFrameNum = 118;

[raw, time, xform_hb, xform_gcamp, xform_gcampCorr, isbrain, xform_isbrain, markers] ...
    = probe.probeImaging(tiffFileName, systemInfo, sessionInfo,'darkFrameNum',darkFrameNum);

%% block avg

blockNum = 10;

blockData = reshape(dataHb,128,128,2,[],blockNum);
blockData = nanmean(blockData,5);
blockTime = linspace(0,30,size(blockData,4)+1); blockTime(1) = [];
stimTimeInd = blockTime > 5 & blockTime < 10;
stimResponse = nanmean(blockData(:,:,:,stimTimeInd),4);
hbT = sum(stimResponse,3);
mask = false(128); mask(60:110,15:60) = true;
hbT(~mask) = 0;
thr = max(hbT(:))*0.75;
roiCandidates = bwconncomp(hbT>thr,4);
roiSizes = zeros(numel(roiCandidates.PixelIdxList),1);
for roiInd = 1:numel(roiSizes)
    roiSizes(roiInd) = numel(roiCandidates.PixelIdxList{roiInd});
end
roi = false(128);
roi(roiCandidates.PixelIdxList{max(roiSizes) == roiSizes}) = true;

% plot

figure;
imagesc(roi); axis(gca,'square'); xticklabels([]); yticklabels([]);

plotData = reshape(blockData,128*128,2,[]);
plotData = squeeze(nanmean(plotData(roi,:,:),1));
plotDataStart = nanmean(plotData(:,blockTime < 5),2);
plotData = bsxfun(@minus,plotData,plotDataStart);

figure;
plot(blockTime,plotData(1,:),'r'); hold on;
plot(blockTime,plotData(2,:),'b');
plot(blockTime,sum(plotData,1),'k');
legend('HbO','HbR','HbT');
ylim(yLim);
