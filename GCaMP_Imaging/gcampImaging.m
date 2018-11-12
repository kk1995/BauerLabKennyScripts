function [raw, time, xform_hb, xform_gcamp, xform_gcampCorr, isbrain, xform_isbrain, markers] ...
    = gcampImaging(tiffFileName, systemInfo, sessionInfo, ledDir, extCoeffDir, varargin)
%gcampImaging Processes tiff file to output hemoglobin data, gcamp, and
%corrected gcamp data
%   Input:
%       tiffFileName = tiff file name. A string array. Should include the
%       directory as well. If multiple string is given, then the function
%       assumes that second file is a continuation of first file.
%       systemInfo = information about the imaging system used, such as
%       which channels are rgb, and which LED files to use
%       sessionInfo = information about the session, including sampling
%       rate of data and lowpass highpass filtering options.
%       ledDir = directory of where the led spectrum text files are
%       extCoeffDir = directory of where hb extinction coefficients are 
%       isbrain (optional) = brain mask. If isbrain isn't given, then a GUI
%       opens that user interacts with to make the mask. (needs to be
%       provided with markers)
%       markers (optional) = brain markers (needs to be provided with
%       isbrain)
%   Output:
%       xform_hb
%       xform_gcamp
%       xform_gcampCorr
%       isbrain
%       xform_isbrain
%       markers

if ~isstring(tiffFileName)
    error('Input tiff file names have to be string array');
end

if numel(varargin) < 1
    getMask = true;
else
    getMask = false;
    isbrain = varargin{1};
    markers = varargin{2};
    
    isbrain = isbrain > 0;
end

% gcamp specific parameters
speciesNum = 4;
hbSpecies = 2:4; % which LED channels are for hemoglobin?
gcampSpecies = 1; % which LED channels are for gcamp?
blueWavelength = 454; % nm
greenWavelength = 512; % nm
bluePath = 5.6E-4; % m
greenPath = 5.7E-4; % m

bandpassFluor = true;

extCoeffFile = strcat(extCoeffDir,"prahl_extinct_coef.txt");

%% load tif file and convert it to mat file

disp('load tif file');

freqIn = sessionInfo.framerate; % sampling rate
freqOut = sessionInfo.freqout;

if freqOut == freqIn
    raw = mouse.preprocess.loadTiffRawMultiple(tiffFileName,speciesNum);
    time = 0:size(raw,4) - 1;
    time = time./freqIn;
    
else
    disp(['  downsample from ' num2str(freqIn) ' Hz to ' num2str(freqOut) ' Hz']);
    
    [time,raw] = mouse.preprocess.loadTiffResample(tiffFileName,speciesNum,freqIn,freqOut);
end

fs = freqOut;

% get rid of first frame since it is usually nonsensical
raw(:,:,:,1) = [];
time(1) = [];

%% make mask

if getMask % only if the mask has to be gotten
    rgbInd = systemInfo.rgb;
    WL = squeeze(raw(:,:,rgbInd,1)); % makes nxnx3 array for white light image
    
    % get landmarks and save mask file
    [isbrain, markers] = mouse.expSpecific.getLandMarksandMask(WL);
end

%% get hemoglobin data

disp('get hemoglobin data');

for ind = 1:numel(systemInfo.LEDFiles)
    systemInfo.LEDFiles(ind) = strcat(ledDir,systemInfo.LEDFiles(ind));
end

highpassFreq = sessionInfo.highpass;
lowpassFreq = sessionInfo.lowpass;
bandpassFreq = [highpassFreq lowpassFreq];

[hbData, ~, ~]= ...
    mouse.expSpecific.procOIS(raw(:,:,hbSpecies,:), fs, bandpassFreq, ...
    systemInfo.LEDFiles(hbSpecies), extCoeffFile, isbrain);
% hbData is in unit of mole/L

xform_hb = mouse.expSpecific.transformHb(hbData, markers);
%% get gcamp data

disp('get gcamp data');

gcamp = raw(:,:,gcampSpecies,:);
gcamp = mouse.expSpecific.procFluor(gcamp,fs,bandpassFreq,bandpassFluor); % detrending occurs

xform_gcamp = mouse.expSpecific.transformHb(gcamp, markers);

%% correct gcamp for hemoglobin

[lambda, extCoeff] = mouse.expSpecific.getHbExtCoeff(extCoeffFile);

blueLambdaInd = find(lambda == blueWavelength);
greenLambdaInd = find(lambda == greenWavelength);

hbOAbsCoeff = extCoeff([blueLambdaInd greenLambdaInd],1);
hbRAbsCoeff = extCoeff([blueLambdaInd greenLambdaInd],2);

xform_gcampCorr = mouse.physics.correctHb(xform_gcamp,xform_hb,...
    hbOAbsCoeff,hbRAbsCoeff,bluePath,greenPath);

xform_isbrain = mouse.expSpecific.transformHb(isbrain, markers);

end

