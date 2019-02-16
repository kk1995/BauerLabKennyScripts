function fluorImagingEastOIS1Laser_muspHillman(excelFile,rows)

% this script is a wrapper around fluor package that shows how
% the package should be used. As shown, you feed an excel file with file locations,
% then get system and session information either via the functions
% sysInfo.m and sesInfo.m or manual addition. Run fluor.preprocess and
% fluor.process functions to get the desired results.

%% import packages

import mouse.*

%% read the excel file to get the list of file names

trialInfo = expSpecific.extractExcel(excelFile,rows);

rawDataLocs = trialInfo.rawFolder;
rawFileNames = trialInfo.rawFile;
saveFileLocs = trialInfo.saveFolder;
saveFileMaskNames = trialInfo.saveFilePrefixMask;
saveFileDataPrefixes = trialInfo.saveFilePrefixData;
samplingRates = trialInfo.samplingRate;
procSamplingRates = trialInfo.procSamplingRate;

paramPath = what('bauerParams');
hbLoc = fullfile(paramPath.path,'ledSpectra');
fluorLoc = fullfile(paramPath.path,'probeSpectra');
extCoeffFile = fullfile(paramPath.path,'prahl_extinct_coef.txt');
fluorEmissionFile = string(fullfile(fluorLoc,'6-nbdg_emission.txt'));
rgbOrder = [4 NaN 1];
speciesNum = 5; % reader parameter. how many species in image file?
hbSpecies = 1:4;
fluorSpecies = [];
invalidFrameInd = 1;
darkFrameInd = [];
fluorDetrend = false;
hbDetrend = false;
muspFcn = @(x,y) (40*(x/500).^-1.16)'*y;
ledFiles = ["East3410OIS1_TL_470_Pol.txt", ...
        "East3410OIS1_TL_590_Pol.txt", ...
        "East3410OIS1_TL_617_Pol.txt", ...
        "East3410OIS1_TL_625_Pol.txt"];

%% run wl generation for each trial
disp('get wl image and mask');

trialNum = numel(rawDataLocs);

for trial = 1:trialNum
    disp(['Trial # ' num2str(trial) '/' num2str(trialNum)]);
    
    % obtain a string array listing full directory to each image file
    rawDataLoc = rawDataLocs(trial);
    rawFileName = strsplit(rawFileNames(trial),",");
    fileNames = [];
    for fileInd = 1:numel(rawFileName)
        fileNames = [fileNames string(fullfile(rawDataLoc,...
            rawFileName(fileInd)))];
    end
    
    % find the parameters for this trial
    samplingRate = samplingRates(trial);
    procSamplingRate = samplingRate;
    saveFileLoc = saveFileLocs(trial);
    saveFileMaskName = saveFileMaskNames(trial);
    
    % find the full mask file directory. This file will be checked for
    % mask. If this file does not exist, following if/else statement
    % creates the file.
    maskFileName = string(fullfile(saveFileLoc,strcat(saveFileMaskName,"-LandmarksandMask.mat")));
    
    % instantiate VideosReader
    reader = read.VideosReader();
    reader.ReaderObject = read.TiffVideoReader;
    reader.ReaderObject.SpeciesNum = speciesNum;
    reader.DarkFrameInd = darkFrameInd;
    reader.InvalidInd = invalidFrameInd;
    reader.FreqIn = samplingRate;
    reader.FreqOut = procSamplingRate;
    
    % create the white light image and mask file if it does not exist
    if ~exist(maskFileName)
        
        [isbrain,xform_isbrain,I,WL] = getMask(fileNames,reader,rgbOrder);
        
        % save white light image and mask
        if ~exist(saveFileLoc)
            mkdir(saveFileLoc);
        end
        save(maskFileName,'isbrain','I','xform_isbrain','WL','-v7.3');
    end
end

%% preprocess and process
disp('preprocess and process');

for trial = 1:trialNum
    disp(['Trial # ' num2str(trial) '/' num2str(trialNum)]);
    
    % obtain a string array listing full directory to each image file
    rawDataLoc = rawDataLocs(trial);
    rawFileName = strsplit(rawFileNames(trial),",");
    
    fileNames = [];
    for fileInd = 1:numel(rawFileName)
        fileNames = [fileNames string(fullfile(rawDataLoc,...
            rawFileName(fileInd)))];
    end
    
    % get led files
    for i = 1:numel(hbSpecies)
        chInd = hbSpecies(i);
        hbLEDFiles(i) = string(fullfile(hbLoc,ledFiles(chInd)));
    end
    fluorLEDFiles = string(fullfile(hbLoc,ledFiles(fluorSpecies)));
    
    % prefix to be added to saved files
    saveFileDataPrefix = fullfile(saveFileLocs(trial),saveFileDataPrefixes(trial));
    
    % find the parameters for this trial
    samplingRate = samplingRates(trial);
    procSamplingRate = procSamplingRates(trial);
    saveFileLoc = saveFileLocs(trial);
    saveFileMaskName = saveFileMaskNames(trial);
    
    % load mask
    maskFileName = string(fullfile(saveFileLoc,strcat(saveFileMaskName,"-LandmarksandMask.mat")));
    mask = load(maskFileName);
    
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
    
    % instantiate VideosReader
    reader = read.VideosReader();
    reader.ReaderObject = read.TiffVideoReader;
    reader.ReaderObject.SpeciesNum = speciesNum;
    reader.DarkFrameInd = darkFrameInd;
    reader.InvalidInd = invalidFrameInd;
    reader.FreqIn = samplingRate;
    reader.FreqOut = procSamplingRate;
    reader.TimeFrames = [];
    
    hbProc = HbProcessor();
    hbProc.OpticalProperty = hbOP;
    hbProc.Mask = mask.xform_isbrain;
    hbProc.Detrend = hbDetrend;
    hbProc.AffineMarkers = mask.I;
    
    fluorProc = FluorProcessor();
    fluorProc.OpticalPropertyIn = fluorInOP;
    fluorProc.OpticalPropertyOut = fluorOutOP;
    fluorProc.Detrend = fluorDetrend;
    fluorProc.AffineMarkers = mask.I;
    
    [rawTime,xform_datahb,xform_datafluor,xform_datafluorCorr] = hbAndOneFluor(fileNames,reader,...
    hbProc,fluorProc,hbSpecies,fluorSpecies);
    
    % save processed data
    if ~exist(saveFileLoc)
        mkdir(saveFileLoc);
    end
    hbFileName = strcat(saveFileDataPrefix,"-datahb.mat");
    save(hbFileName,'fileNames','reader','hbProc','hbSpecies','rawTime','xform_datahb','-v7.3');
    
    fluorFileName = strcat(saveFileDataPrefix,"-dataFluor.mat");
    save(fluorFileName,'fileNames','reader','fluorProc','fluorSpecies','rawTime','xform_datafluor',...
        'xform_datafluorCorr','-v7.3');
end

end