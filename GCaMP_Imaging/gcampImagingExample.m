% this script is a wrapper around gcampImaging.m function that shows how
% the function should be used. As shown, you state which tiff file to run,
% then get system and session information either via the functions
% sysInfo.m and session2procInfo.m or manual addition. Run the
% gcampImaging.m function afterwards and you are good to go!

%% state the tiff file

tiffFileName = "D:\data\temp\170621-pre196-stim2.tif";
% tiffFileName = "D:\data\temp\170621-astro313-stim2.tif";

%% get system or session information.

% use the pre-existing system and session information by selecting the type
% of system and the type of session. If the system or session you are using
% do not fit the existing choices, you can either add new system and
% session types or add them manually.
% for systemInfo, you need rgb and LEDFiles
% for sessionInfo, you need framerate, freqout, lowpass, and highpass

% systemType = 'fcOIS1', 'fcOIS2', 'fcOIS2_Fluor' or 'EastOIS1_Fluor'
systemInfo = mouse.expSpecific.sysInfo('fcOIS2_Fluor');

% sessionType = 'fc' or 'stim'
sessionInfo = mouse.expSpecific.session2procInfo('stim');
sessionInfo.framerate = 16.8;
sessionInfo.lowpass = 8;
sessionInfo.freqout = 16.8;

%% get gcamp and hb data

load('D:\data\temp\pre196_seeds.mat'); % I
isbrain = imread('D:\data\temp\pre196_mask.mat');
isbrain = isbrain > 0;

% [raw, time, xform_hb, xform_gcamp, xform_gcampCorr, isbrain, xform_isbrain, markers] ...
%     = gcamp.gcampImaging(tiffFileName, systemInfo, sessionInfo);

% if brain mask and markers are available:
[raw, time, xform_hb, xform_gcamp, xform_gcampCorr, isbrain, xform_isbrain, markers] ...
    = gcamp.gcampImaging(tiffFileName, systemInfo, sessionInfo, isbrain, I);

% isbrain = logical nxn array of brain mask.
% markers = the brain markers that are created during the whole GUI where
% you click on the midline suture and lambda. If you do not have these,
% just run the code without giving these inputs, go through the GUI, then
% the code will output isbrain, xform_isbrain, and markers.

%% plot

plot(time,squeeze(xform_hb(79,95,1,:))*1000,'r');
hold on; plot(time,squeeze(xform_hb(79,95,2,:))*1000,'b');
hold on; plot(time,squeeze(xform_gcamp(79,95,1,:)),'m');
hold on; plot(time,squeeze(xform_gcampCorr(79,95,1,:)),'k');
hold off;

%% plot block avg

blockLen = 20*sessionInfo.framerate;

plotTime = 1:blockLen; plotTime = plotTime./sessionInfo.framerate;


hbAvg = nanmean(reshape(cat(4,xform_hb(:,:,:,1),xform_hb),[128 128 2 blockLen 5040/blockLen]),5);
gcampAvg = nanmean(reshape(cat(4,xform_gcamp(:,:,:,1),xform_gcamp),[128 128 1 blockLen 5040/blockLen]),5);
gcampCorrAvg = nanmean(reshape(cat(4,xform_gcampCorr(:,:,:,1),xform_gcampCorr),[128 128 1 blockLen 5040/blockLen]),5);

stimInd = find(plotTime > 5 & plotTime < 10);
stimResp = squeeze(nanmean(gcampCorrAvg(:,:,1,stimInd),4));
stimROI = stimResp >= 0.75*max(stimResp(:));
stimROI(:,59:128) = false;

hbStimAvg = reshape(hbAvg,128*128,2,[]);
gcampStimAvg = reshape(gcampAvg,128*128,2,[]);
gcampCorrStimAvg = reshape(gcampCorrAvg,128*128,2,[]);

hbStimAvg = squeeze(nanmean(hbStimAvg(stimROI,:,:)));
gcampStimAvg = squeeze(nanmean(gcampStimAvg(stimROI,:)));
gcampCorrStimAvg = squeeze(nanmean(gcampCorrStimAvg(stimROI,:)));

figure;
plot(plotTime,squeeze(hbStimAvg(2,:))*1000)
hold on;
plot(plotTime,squeeze(hbStimAvg(1,:))*1000)
legend('HbR','HbO')

figure;
plot(plotTime,squeeze(hbStimAvg(2,:))*1000)
hold on;
plot(plotTime,squeeze(hbStimAvg(1,:))*1000)
plot(plotTime,squeeze(gcampStimAvg))
plot(plotTime,squeeze(gcampCorrStimAvg),'k')

legend('HbR','HbO','gcamp','corrected')