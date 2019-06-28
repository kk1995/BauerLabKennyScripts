function probeImaging_normal(varargin)

if numel(varargin) > 0
    excelFile = varargin{1};
else
    excelFile = 'D:\data\SalineProbeEachTrial.xlsx';
end

if numel(varargin) > 1
    rows = varargin{2};
else
    rows = 2:3;
end

%% import packages

import mouse.*

[~,~,excelData] = xlsread(excelFile,1,['A1:' xlscol(11) num2str(max(rows))]);

trialNum = 0;
for row = rows
    trialNum = trialNum + 1;
    dataLoc = string(excelData{row,3});
    saveLoc = string(excelData{row,5});
    rawFile = fullfile(dataLoc,string(excelData{row,4}));
    trialInfo(trialNum).rawFile = rawFile;
    
    saveMaskFilePrefix = fullfile(saveLoc,string(excelData{row,6}));
    trialInfo(trialNum).saveMaskFilePrefix = saveMaskFilePrefix;
    
    saveDataFilePrefix = fullfile(saveLoc,string(excelData{row,7}));
    trialInfo(trialNum).saveDataFilePrefix = saveDataFilePrefix;
    trialInfo(trialNum).samplingRate = excelData{row,9};
    trialInfo(trialNum).freqOut = excelData{row,10};
    trialInfo(trialNum).system = excelData{row,8};
    trialInfo(trialNum).darkFrameNum = excelData{row,11};
end

%% read the excel file to get the list of file names
paramPath = what('bauerParams');
sourceSpectraLoc = fullfile(paramPath.path,'ledSpectra');
fluorLoc = fullfile(paramPath.path,'probeSpectra');
extCoeffFile = fullfile(paramPath.path,'prahl_extinct_coef.txt');
fluorEmissionFile = string(fullfile(fluorLoc,'fad_emission.txt'));
detrendHb = true;
detrendFluor = true;
muspFcn = @(x,y) (40*(x/500).^-1.16)'*y;
fluorBaselineFcn = @(x) mean(x(:,:,:,1:round(0.1*size(x,4))),4);
    
%% run wl generation for each trial
disp('get wl image and mask');

trialNum = numel(trialInfo);

for trial = 1:trialNum
    disp(['Trial # ' num2str(trial) '/' num2str(trialNum)]);
    
    systemInfo = sysInfo(trialInfo(trial).system);
    rgbOrder = systemInfo.rgb;
    darkFrameInd = 1:trialInfo(trial).darkFrameNum;
    
    % find the full mask file directory. This file will be checked for
    % mask. If this file does not exist, following if/else statement
    % creates the file.
    maskFileName = strcat(trialInfo(trial).saveMaskFilePrefix,"-LandmarksandMask.mat");
    saveFolder = fileparts(maskFileName);
        
    % instantiate VideosReader
    reader = read.VideosReader();
    reader.ReaderObject = read.TiffVideoReader;
    reader.ChNum = systemInfo.numLEDs;
    reader.DarkFrameInd = darkFrameInd;
    reader.InvalidInd = systemInfo.invalidFrameInd;
    reader.FreqIn = trialInfo(trial).samplingRate;
    reader.FreqOut = trialInfo(trial).freqOut;
    
    % create the white light image and mask file if it does not exist
    if ~exist(maskFileName)
        
        [isbrain,xform_isbrain,I,WL] = getMask(trialInfo(trial).rawFile,reader,rgbOrder);
        
        if ~exist(saveFolder)
            mkdir(saveFolder);
        end
        
        save(maskFileName,'isbrain','I','xform_isbrain','WL','-v7.3');
    end
end

%% preprocess and process
disp('preprocess and process');

for trial = 1:trialNum
    disp(['Trial # ' num2str(trial) '/' num2str(trialNum)]);
    
    systemInfo = sysInfo(trialInfo(trial).system);
    hbChInd = systemInfo.hbSource;
    fluorChInd = systemInfo.fluorSource;
    darkFrameInd = 1:trialInfo(trial).darkFrameNum;
    
    maskFileName = strcat(trialInfo(trial).saveMaskFilePrefix,"-LandmarksandMask.mat");
    dataFileName = strcat(trialInfo(trial).rawFile);
    saveFileDataHb = strcat(trialInfo(trial).saveDataFilePrefix,"-datahb.mat");
    saveFileDataFluor = strcat(trialInfo(trial).saveDataFilePrefix,"-dataFluor.mat");
    saveFolder = fileparts(saveFileDataHb);
    
    % load mask
    mask = load(maskFileName);
    
    % instantiate VideosReader
    reader = mouse.read.VideosReader();
    reader.ReaderObject = read.TiffVideoReader;
    reader.ChNum = systemInfo.numLEDs;
    reader.DarkFrameInd = darkFrameInd;
    reader.InvalidInd = systemInfo.invalidFrameInd;
    reader.FreqIn = trialInfo(trial).samplingRate;
    reader.FreqOut = trialInfo(trial).freqOut;
    
    affineMarkers = mask.I;
    
    % get raw data
    [raw,rawTime,darkFrames] = reader.read(dataFileName);
    rawTime = rawTime - size(darkFrames,4)./trialInfo(trial).freqOut;
    
    % remove dark light intensity
    for i = 1:size(raw,3)
        raw(:,:,i,:) = raw(:,:,i,:) - mean(darkFrames(:,:,i,:),4);
    end
    
    hbRaw = raw(:,:,hbChInd,:);
    fluorRaw = raw(:,:,fluorChInd,:);
    
    clear raw
    
    hbSourceFiles = systemInfo.LEDFiles(hbChInd);
    for i = 1:numel(hbSourceFiles)
        hbSourceFiles(i) = fullfile(sourceSpectraLoc,hbSourceFiles(i));
    end
    
    fluorSourceFiles = systemInfo.LEDFiles(fluorChInd);
    for i = 1:numel(fluorSourceFiles)
        fluorSourceFiles(i) = fullfile(sourceSpectraLoc,fluorSourceFiles(i));
    end
    
    % process hb
    hbOP = physics.OpticalProperty();
    hbOP.ExtinctCoeffFile = extCoeffFile;
    hbOP.LightSourceFiles = hbSourceFiles;
    hbOP.Musp = muspFcn;
    
    hbProc = process.HbProcessor();
    hbProc.OpticalProperty = hbOP;
    hbProc.Mask = mask.isbrain;
    hbProc.Detrend = detrendHb;
    hbProc.AffineMarkers = affineMarkers;
    
    xform_datahb = hbProc.process(hbRaw);
    greenRaw = hbRaw(:,:,1,:);
    
    clear hbRaw
    
    % process fluor
    fluorTime = rawTime;
    fluorInOP = physics.OpticalProperty();
    fluorInOP.ExtinctCoeffFile = extCoeffFile;
    fluorInOP.LightSourceFiles = fluorSourceFiles;
    fluorInOP.Musp = muspFcn;
    
    fluorOutOP = physics.OpticalProperty();
    fluorOutOP.ExtinctCoeffFile = extCoeffFile;
    fluorOutOP.LightSourceFiles = fluorEmissionFile;
    fluorOutOP.Musp = muspFcn;
    
    fluorProc = process.FluorProcessor();
    fluorProc.OpticalPropertyIn = fluorInOP;
    fluorProc.OpticalPropertyOut = fluorOutOP;
    fluorProc.Detrend = detrendFluor;
    fluorProc.AffineMarkers = affineMarkers;
    fluorProc.BaselineFunction = fluorBaselineFcn;
%     [xform_datafluorCorr, xform_datafluor] = fluorProc.process(fluorRaw,xform_datahb);
    [xform_datafluorCorr, xform_datafluor] = fluorProc.processGreen(fluorRaw,greenRaw);
    clear fluorRaw
    
    warning('off','all')
    readerInfo = struct(reader);
    hbProcInfo = struct(hbProc);
    fluorProcInfo = struct(fluorProc);
    warning('on','all')
    
    xform_isbrain = mouse.process.affineTransform(mask.isbrain,affineMarkers);
    
    % save processed data
    if ~exist(saveFolder)
        mkdir(saveFolder);
    end
    save(saveFileDataHb,'dataFileName','readerInfo','hbProcInfo',...
        'hbChInd','rawTime','xform_datahb','xform_isbrain','-v7.3');
    save(saveFileDataFluor,'dataFileName','readerInfo','fluorProcInfo',...
        'fluorChInd','rawTime','fluorTime','xform_datafluor','xform_datafluorCorr','xform_isbrain','-v7.3');
end

end