% this script is a wrapper around gcampImaging.m function that shows how
% the function should be used. As shown, you state which tiff file to run,
% then get system and session information either via the functions
% sysInfo.m and session2procInfo.m or manual addition. Run the
% gcampImaging.m function afterwards and you are good to go!

%% state the tiff file
tiffFileName = ["J:\180813\180813-ProbeW3M3-Post.tif", ...
    "J:\180813\180813-ProbeW3M3-Post_X2.tif"];

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
systemInfo = mouse.expSpecific.sysInfo('fcOIS2_Fluor');

% sessionType = 'fc' or 'stim'
sessionInfo = mouse.expSpecific.session2procInfo('fc');

%% get gcamp and hb data

% use this code if mask or markers data aren't available prior
[time, xform_hb, xform_probe, xform_probeCorr, isbrain, xform_isbrain, markers] ...
    = glucoseImaging(tiffFileName, systemInfo, sessionInfo, ledDir, extCoeffDir);

% use this code if mask and markers data are available
% [time, xform_hb, xform_probe, xform_probeCorr, isbrain, xform_isbrain, markers] ...
%     = glucoseImaging(tiffFileName, systemInfo, sessionInfo, ledDir, extCoeffDir, ...
%     isbrain, markers);

% isbrain = logical nxn array of brain mask.
% markers = the brain markers (bregma, tent, OF, Seeds) that are created during the whole GUI where
% you click on the midline suture and lambda. If you do not have these,
% just run the code without giving these inputs, go through the GUI, then
% the code will output isbrain, xform_isbrain, and markers.