% this script is a wrapper around fluor package that shows how
% the package should be used. As shown, you state which tiff file to run,
% then get system and session information either via the functions
% sysInfo.m and session2procInfo.m or manual addition. Run the
% gcampImaging.m function afterwards and you are good to go!

%% import packages

import mouse.*

%% state the tiff file

fileName1 = "J:\180813\180813-ProbeW3M2-Pre.tif";
fileName2 = "J:\180813\180813-ProbeW3M2-Pre.tif";

orientation1 = [false true]; % only flips on 2nd dim
orientation2 = [true true]; % only flips on 1st dim

validCh1 = 3:4; % only takes ch 3 and 4 from first file
validCh2 = 1:2; % only takes ch 1 and 2 from second file

%% get system or session information.

systemInfo = expSpecific.sysInfo('EastOIS1_Fluor');

sessionInfo = expSpecific.sesInfo('gcamp6f');
sessionInfo.freqout = 2; % downsample to 2 Hz

% define which frames are dark
darkFrameInd = [];

%% get raw

speciesNum = systemInfo.numLEDs;
raw1 = read.readRaw(fileName,speciesNum,systemInfo.readFcn,orientation1);
raw2 = read.readRaw(fileName2,speciesNum,systemInfo.readFcn,orientation2);
raw = cat(3,raw1(:,:,validCh1,:),raw2(:,:,validCh2,:));
time = 1:size(raw,4); time = time./sessionInfo.framerate;

%% get WL image, landmarks, and mask

rgbOrder = systemInfo.rgb;
wl = preprocess.getWL(raw,darkFrameInd,rgbOrder);
[isbrain, affineMarkers] = preprocess.getLandmarksAndMask(wl);

%% preprocess

[time,data] = fluor.preprocess(time,raw,systemInfo,sessionInfo,affineMarkers,'darkFrameInd',darkFrameInd);
xform_isbrain = preprocess.affineTransform(isbrain,affineMarkers);

%% process

[datahb,dataFluor,dataFluorCorr] = fluor.process(data,systemInfo,sessionInfo,xform_isbrain);