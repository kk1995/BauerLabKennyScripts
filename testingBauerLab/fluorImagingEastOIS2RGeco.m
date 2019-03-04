function fluorImagingEastOIS2RGeco

% this script is a wrapper around fluor package that shows how
% the package should be used. As shown, you feed an excel file with file locations,
% then get system and session information either via the functions
% sysInfo.m and sesInfo.m or manual addition. Run fluor.preprocess and
% fluor.process functions to get the desired results.

%% import packages

import mouse.*

%% read the excel file to get the list of file names

paramPath = what('bauerParams');
hbLoc = fullfile(paramPath.path,'ledSpectra');
fluorLoc = fullfile(paramPath.path,'probeSpectra');
extCoeffFile = fullfile(paramPath.path,'prahl_extinct_coef.txt');
fluorEmissionFile = string(fullfile(fluorLoc,'jrgeco1a_emission.txt'));
hbSpecies = 2:3;
fluorSpecies = 1;
fluorDetrend = true;
hbDetrend = true;
muspFcn = @(x,y) (40*(x/500).^-1.16)'*y;
ledFiles = ["TwoCam_Mightex525_BP_Pol.txt", ...
    "TwoCam_Mightex525_BP_Pol.txt", ...
    "TwoCam_TL625_Pol.txt"];

dataFileName = "D:\data\190217-R1M2124KET-stim3.mat";
maskFileName = "C:\Users\Kenny\Box\ToKenny\190217-R1M2124KET-LandmarksandMarks.mat";
saveFileLoc = "D:\data\190217-R1M2124KET";
fs = 16.667;
%% preprocess and process
disp('preprocess and process');

% get led files
for i = 1:numel(hbSpecies)
    chInd = hbSpecies(i);
    hbLEDFiles(i) = string(fullfile(hbLoc,ledFiles(chInd)));
end
fluorLEDFiles = string(fullfile(hbLoc,ledFiles(fluorSpecies)));

% load mask
mask = load(maskFileName);
mask.isbrain = logical(mask.isbrain);

% get optical properties
hbOP = physics.OpticalProperty();
hbOP.ExtinctCoeffFile = extCoeffFile;
hbOP.LightSourceFiles = hbLEDFiles;
hbOP.Musp = muspFcn;

fluorInOP = physics.OpticalProperty();
fluorInOP.ExtinctCoeffFile = extCoeffFile;
fluorInOP.LightSourceFiles = fluorLEDFiles;
fluorInOP.Musp = muspFcn;

fluorOutOP = physics.OpticalProperty();
fluorOutOP.ExtinctCoeffFile = extCoeffFile;
fluorOutOP.LightSourceFiles = fluorEmissionFile;
fluorOutOP.Musp = muspFcn;

hbProc = process.HbProcessor();
hbProc.OpticalProperty = hbOP;
hbProc.Mask = mask.isbrain;
hbProc.Detrend = hbDetrend;
hbProc.AffineMarkers = mask.I;

fluorProc = process.FluorProcessor();
fluorProc.OpticalPropertyIn = fluorInOP;
fluorProc.OpticalPropertyOut = fluorOutOP;
fluorProc.Detrend = fluorDetrend;
fluorProc.AffineMarkers = mask.I;

% get raw data
raw = load(dataFileName);
raw = raw.raw;
rawTime = 1:size(raw,4); rawTime = rawTime./fs;

% process hb
xform_datahb = hbProc.process(raw(:,:,hbSpecies,:));

% process fluor
[xform_datafluorCorr, xform_datafluor] = fluorProc.process(raw(:,:,fluorSpecies,:),xform_datahb);

warning('off','all')
hbProcInfo = struct(hbProc);
fluorProcInfo = struct(fluorProc);
warning('on','all')

hbFileName = strcat(saveFileLoc,"-datahb.mat");
save(hbFileName,'hbProcInfo','hbSpecies','rawTime','xform_datahb','-v7.3');

fluorFileName = strcat(saveFileLoc,"-dataFluor.mat");
save(fluorFileName,'fluorProcInfo','fluorSpecies','rawTime','xform_datafluor',...
    'xform_datafluorCorr','-v7.3');

end