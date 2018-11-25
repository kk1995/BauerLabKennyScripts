
runFileNames = ["D:\ProcessedData\181031-GcampM2-stim1-processed.mat" ...
    "D:\ProcessedData\181031-GcampM2-stim2-processed.mat" ...
    "D:\ProcessedData\181031-GcampM2-stim3-processed.mat"];
fs = 16.8;
blockLenSeconds = 30; % seconds

%% get roi

load(runFileNames(1));
blockLen = blockLenSeconds*fs;

plotTime = 1:blockLen; plotTime = plotTime./fs;

gcampCorrAvg = nanmean(reshape(cat(4,xform_gcampCorr(:,:,:,1),xform_gcampCorr),[128 128 1 blockLen 5040/blockLen]),5);

stimInd = plotTime > 5 & plotTime < 10;
stimResp = squeeze(nanmean(gcampCorrAvg(:,:,1,stimInd),4));
candidateROI = false(128);
candidateROI(60:108,8:40) = true;
candidateROI(~xform_isbrain) = false;

stimROI = stimResp >= 0.75*max(stimResp(candidateROI));
stimROI(~candidateROI) = false;

%% get avg stim response

blockLen = blockLenSeconds*fs;
plotTime = 1:blockLen; plotTime = plotTime./fs;

hbOStimAvg = [];
hbRStimAvg = [];
gcampStimAvg = [];
gcampCorrStimAvg = [];

for run = 1:numel(runFileNames)
    load(runFileNames(run));
    
    hbAvg = nanmean(reshape(cat(4,xform_hb(:,:,:,1),xform_hb),[128 128 2 blockLen 5040/blockLen]),5);
    gcampAvg = nanmean(reshape(cat(4,xform_gcamp(:,:,:,1),xform_gcamp),[128 128 1 blockLen 5040/blockLen]),5);
    gcampCorrAvg = nanmean(reshape(cat(4,xform_gcampCorr(:,:,:,1),xform_gcampCorr),[128 128 1 blockLen 5040/blockLen]),5);
    stimInd = plotTime > 5 & plotTime < 10;
    
    hbStimAvgRun = reshape(hbAvg,128*128,2,[]);
    gcampStimAvgRun = reshape(gcampAvg,128*128,2,[]);
    gcampCorrStimAvgRun = reshape(gcampCorrAvg,128*128,2,[]);
    
    hbStimAvgRun = squeeze(nanmean(hbStimAvgRun(stimROI,:,:)));
    hbOStimAvgRun = squeeze(hbStimAvgRun(1,:));
    hbRStimAvgRun = squeeze(hbStimAvgRun(2,:));
    gcampStimAvgRun = squeeze(nanmean(gcampStimAvgRun(stimROI,:)));
    gcampCorrStimAvgRun = squeeze(nanmean(gcampCorrStimAvgRun(stimROI,:)));

    hbOStimAvg = [hbOStimAvg; hbOStimAvgRun];
    hbRStimAvg = [hbRStimAvg; hbRStimAvgRun];
    gcampStimAvg = [gcampStimAvg; gcampStimAvgRun];
    gcampCorrStimAvg = [gcampCorrStimAvg; gcampCorrStimAvgRun];
end

%% plot block avg

figure;
p1 = plot(plotTime,mean(hbOStimAvg,1)*1000,'r');
hold on;
p2 = plot(plotTime,mean(hbRStimAvg,1)*1000,'b');

% stim
stimTime = 5:1/3:10; stimTime(end) = [];
yLim = ylim(gca);
for stim = 1:numel(stimTime)
    plot([stimTime(stim) stimTime(stim)],yLim,'g');
end

legend([p1, p2], 'HbO (mM)','HbR (mM)')

figure;
p1 = plot(plotTime,mean(hbOStimAvg,1)*1000,'r');
hold on;
p2 = plot(plotTime,mean(hbRStimAvg,1)*1000,'b');
p3 = plot(plotTime,mean(gcampStimAvg,1),'m');
p4 = plot(plotTime,mean(gcampCorrStimAvg,1),'k');


% stim
stimTime = 5:1/3:10; stimTime(end) = [];
yLim = ylim(gca);
for stim = 1:numel(stimTime)
    plot([stimTime(stim) stimTime(stim)],yLim,'g');
end

legend([p1,p2,p3,p4],'HbO (mM)','HbR (mM)','gcamp','corrected')
