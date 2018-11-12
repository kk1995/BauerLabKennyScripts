% this script is a wrapper around gcampImaging.m function that shows how
% the function should be used. As shown, you state which tiff file to run,
% then get system and session information either via the functions
% sysInfo.m and session2procInfo.m or manual addition. Run the
% gcampImaging.m function afterwards and you are good to go!

%% state the tiff file

tiffFileName = "L:\181031-GCampM2-fc1.tif";
% tiffFileName = "J:\180813\180813-ProbeW3M2-Post.tif";

%% state where the led spectrum files and extinction coefficient files are

ledDir = "C:\Repositories\GitHub\OIS\Spectroscopy\LED Spectra\";
extCoeffDir = "C:\Repositories\GitHub\OIS\Spectroscopy\";

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
sessionInfo.freqout = 2;

%% get gcamp and hb data

[raw, time, xform_hb, xform_gcamp, xform_gcampCorr, isbrain, xform_isbrain, markers] ...
    = gcampImaging(tiffFileName, systemInfo, sessionInfo, ledDir, extCoeffDir);

% % if brain mask and markers are available:
% [raw, time, xform_hb, xform_gcamp, xform_gcampCorr, isbrain, xform_isbrain, markers] ...
%     = gcampImaging(tiffFileName, systemInfo, sessionInfo, ledDir, extCoeffDir, ...
%     isbrain, markers);

% isbrain = logical nxn array of brain mask.
% markers = the brain markers that are created during the whole GUI where
% you click on the midline suture and lambda. If you do not have these,
% just run the code without giving these inputs, go through the GUI, then
% the code will output isbrain, xform_isbrain, and markers.

%% plot

plot(time,squeeze(xform_hb(79,95,1,:))*1000);
hold on; plot(time,squeeze(xform_hb(79,95,2,:))*1000);
hold on; plot(time,squeeze(xform_gcamp(79,95,1,:)));
hold on; plot(time,squeeze(xform_gcampCorr(79,95,1,:)));
hold off;

legend('HbO (mM)','HbR (mM)','gcamp','gcamp corrected');