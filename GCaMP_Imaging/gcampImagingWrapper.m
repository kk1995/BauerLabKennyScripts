% this script is a wrapper around gcampImaging.m function that shows how
% the function should be used. As shown, you state which tiff file to run,
% then get system and session information either via the functions
% sysInfo.m and session2procInfo.m or manual addition. Run the
% gcampImaging.m function afterwards and you are good to go!

%% state the tiff file

tiffFileName = "\\10.39.168.176\RawData_East3410\181031\181031-GCampM2-stim1.tif";
saveMaskName = "\\10.39.168.176\RawData_East3410\181031\181031-GCampM2-mask.tif";

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
sessionInfo.lowpass = 8;
sessionInfo.framerate = 16.8;
sessionInfo.freqout = sessionInfo.framerate;

%% get gcamp and hb data

% % if brain mask and markers are available:
% [raw, time, xform_hb, xform_gcamp, xform_gcampCorr, isbrain, xform_isbrain, markers] ...
%     = gcamp.gcampImaging(tiffFileName, systemInfo, sessionInfo, isbrain, markers);

% isbrain = logical nxn array of brain mask.
% markers = the brain markers that are created during the whole GUI where
% you click on the midline suture and lambda. If you do not have these,
% just run the code without giving these inputs, go through the GUI, then
% the code will output isbrain, xform_isbrain, and markers.

if exist(saveMaskName)
    load(saveMaskName);
    [raw, time, xform_hb, xform_gcamp, xform_gcampCorr, isbrain, xform_isbrain, markers] ...
        = gcamp.gcampImaging(tiffFileName, systemInfo, sessionInfo, isbrain, markers);
else
    [raw, time, xform_hb, xform_gcamp, xform_gcampCorr, isbrain, xform_isbrain, markers] ...
        = gcamp.gcampImaging(tiffFileName, systemInfo, sessionInfo);
    
    save(saveMaskName,'isbrain','xform_isbrain','markers');
end

%% get block avg

blockNumel = 30*sessionInfo.freqout;
timeAvg = linspace(0,30,blockNumel+1);
timeAvg(1) = [];
xform_hbAvg = mouse.preprocess.blockAvg(xform_hb,time,30,blockNumel);
xform_gcampAvg = mouse.preprocess.blockAvg(xform_gcamp,time,30,blockNumel);
xform_green = mouse.expSpecific.transformHb(raw(:,:,2,:), markers);
xform_green = xform_green./repmat(nanmean(xform_green,4),1,1,1,size(xform_green,4));
xform_green = xform_green - 1;
xform_greenAvg = mouse.preprocess.blockAvg(xform_green,time,30,blockNumel);
xform_gcampCorrAvg = mouse.preprocess.blockAvg(xform_gcampCorr,time,30,blockNumel);

%% plot

% yInd = 79;
% xInd = 95;
yInd = 88;
xInd = 28;

% time series
figure;
plot(time,squeeze(xform_hb(yInd,xInd,1,:))*1000,'r');
hold on; plot(time,squeeze(xform_hb(yInd,xInd,2,:))*1000,'b');
hold on; plot(time,squeeze(xform_gcamp(yInd,xInd,1,:)),'m');
hold on; plot(time,squeeze(xform_gcampCorr(yInd,xInd,1,:)),'k');
hold off;

legend('HbO (mM)','HbR (mM)','gcamp','gcamp corrected');

blockInd = round(sessionInfo.freqout*2)+1:round(sessionInfo.freqout*20);
plotTime = timeAvg(blockInd) - 5;

% block avg 1
figure;
plot(plotTime,squeeze(xform_hbAvg(yInd,xInd,1,blockInd))*1000,'r');
hold on; plot(plotTime,squeeze(xform_hbAvg(yInd,xInd,2,blockInd))*1000,'b');
hold on; plot(plotTime,squeeze(xform_gcampCorrAvg(yInd,xInd,1,blockInd)),'k');
hold off;
xlim([min(plotTime) max(plotTime)]);

legend('HbO (mM)','HbR (mM)','gcamp corrected');

% block avg 2
figure;
plot(plotTime,squeeze(xform_gcampAvg(yInd,xInd,1,blockInd)),'m');
hold on; plot(plotTime,squeeze(xform_greenAvg(yInd,xInd,1,blockInd)),'g');
hold on; plot(plotTime,squeeze(xform_gcampCorrAvg(yInd,xInd,1,blockInd)),'k');
hold off;
xlim([min(plotTime) max(plotTime)]);

legend('gcamp','green','gcamp corrected');

% response spatial plot
t = find(timeAvg > 5 & timeAvg < 10);
figure;
imagesc(squeeze(nanmean(xform_gcampCorrAvg(:,:,1,t),4)),'AlphaData',xform_isbrain,[-0.06 0.06]); axis(gca,'square'); colormap('jet'); colorbar;