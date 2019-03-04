function probeImaging_190225(varargin)

% fluor is imaged at 0.2 Hz, and rest are imaged at 1 Hz. Speckle is
% channel 5.

if numel(varargin) > 0
    excelFile = varargin{1};
else
    excelFile = 'D:\data\probeAndSpeckle.xlsx';
end

if numel(varargin) > 1
    rows = varargin{2};
else
    rows = 2:3;
end

%% import packages

import mouse.*

[~,~,excelData] = xlsread(excelFile,1,['A1:' xlscol(6) num2str(max(rows))]);

trialNum = 0;
for row = rows
    trialNum = trialNum + 1;
    dataLoc = fullfile(excelData{row,3},num2str(excelData{row,1}));
    D = dir(dataLoc); D(1:2) = [];
    
    sessionType = excelData{row,6}; sessionType = sessionType(3:end-2);
    sessionType = string(sessionType);
    preFileName = strcat(num2str(excelData{row,1}),"-",string(excelData{row,2}),"-",sessionType,"-Pre.tif");
    preFile = string(fullfile(D(1).folder,preFileName));
    trialInfo(trialNum).rawFile = preFile;
    preFileName = char(preFileName);
    saveMaskFilePrefix = strcat(fullfile(excelData{row,4},num2str(excelData{row,1}),...
        preFileName(1:end-8)));
    saveMaskFilePrefix = string(saveMaskFilePrefix);
    trialInfo(trialNum).saveMaskFilePrefix = saveMaskFilePrefix;
    trialInfo(trialNum).saveDataFilePrefix = strcat(saveMaskFilePrefix,"-Pre");
    trialInfo(trialNum).samplingRate = 1;
    
    trialNum = trialNum + 1;
    postFilePrefix = strcat(num2str(excelData{row,1}),"-",string(excelData{row,2}),"-",sessionType,"-Post");
    postFileList = [];
    for file = 1:numel(D)
        if contains(D(file).name,postFilePrefix)
            postFileList = [postFileList string(fullfile(D(file).folder,D(file).name))];
        end
    end
    trialInfo(trialNum).rawFile = postFileList;
    trialInfo(trialNum).saveMaskFilePrefix = saveMaskFilePrefix;
    trialInfo(trialNum).saveDataFilePrefix = strcat(saveMaskFilePrefix,"-Post");
    trialInfo(trialNum).samplingRate = 1;
end

%% read the excel file to get the list of file names

paramPath = what('bauerParams');
sourceSpectraLoc = fullfile(paramPath.path,'ledSpectra');
fluorLoc = fullfile(paramPath.path,'probeSpectra');
extCoeffFile = fullfile(paramPath.path,'prahl_extinct_coef.txt');
fluorEmissionFile = string(fullfile(fluorLoc,'6-nbdg_emission.txt'));
rgbOrder = [4 2 NaN];
numCh = 5;
hbChInd = 2:4;
fluorChInd = 1;
speckleChInd = 5;
invalidFrameInd = 1;
darkFrameInd = 1:5;
detrendHb = false;
detrendFluor = false;
muspFcn = @(x,y) (40*(x/500).^-1.16)'*y;
hbSourceFiles = ["TL_530nm_515LPF_Pol.txt", ...
        "East3410OIS1_TL_617_Pol.txt", ...
        "East3410OIS1_TL_625_Pol.txt"];
fluorSourceFiles = "M470nm_SPF_pol.txt";
binSize = 4;
fluorBaselineFcn = @(x) mean(x(:,:,:,1:round(0.1*size(x,4))),4);
% get led files
for i = 1:numel(hbSourceFiles)
    hbSourceFiles(i) = string(fullfile(sourceSpectraLoc,hbSourceFiles(i)));
end
    
%% run wl generation for each trial
disp('get wl image and mask');

trialNum = numel(trialInfo);

for trial = 1:trialNum
    disp(['Trial # ' num2str(trial) '/' num2str(trialNum)]);
    
    % find the full mask file directory. This file will be checked for
    % mask. If this file does not exist, following if/else statement
    % creates the file.
    maskFileName = strcat(trialInfo(trial).saveMaskFilePrefix,"-LandmarksandMask.mat");
    saveFolder = fileparts(maskFileName);
        
    % instantiate VideosReader
    reader = read.VideosReader();
    reader.ReaderObject = read.TiffVideoReader;
    reader.ReaderObject.SpeciesNum = numCh;
    reader.DarkFrameInd = darkFrameInd;
    reader.InvalidInd = invalidFrameInd;
    reader.FreqIn = trialInfo(trial).samplingRate;
    reader.FreqOut = trialInfo(trial).samplingRate;
    
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
    
    maskFileName = strcat(trialInfo(trial).saveMaskFilePrefix,"-LandmarksandMask.mat");
    dataFileName = strcat(trialInfo(trial).rawFile);
    saveFileDataHb = strcat(trialInfo(trial).saveDataFilePrefix,"-datahb.mat");
    saveFileDataFluor = strcat(trialInfo(trial).saveDataFilePrefix,"-dataFluor.mat");
    saveFileDataSpeckle = strcat(trialInfo(trial).saveDataFilePrefix,"-dataSpeckle.mat");
    saveFolder = fileparts(saveFileDataHb);
    
    % load mask
    mask = load(maskFileName);
    
    % instantiate VideosReader
    reader = read.VideosReader();
    reader.ReaderObject = read.TiffVideoReader;
    reader.ReaderObject.SpeciesNum = numCh;
    reader.DarkFrameInd = darkFrameInd;
    reader.InvalidInd = invalidFrameInd;
    reader.FreqIn = trialInfo(trial).samplingRate;
    reader.FreqOut = trialInfo(trial).samplingRate;
    reader.TimeFrames = [];
    
    affineMarkers = mask.I;
    affineMarkers.bregma = affineMarkers.bregma/binSize;
    affineMarkers.tent = affineMarkers.tent/binSize;
    affineMarkers.OF = affineMarkers.OF/binSize;
    
    % get raw data
    [raw,rawTime,darkFrames] = reader.read(dataFileName);
    rawTime = rawTime - size(darkFrames,4)./trialInfo(trial).samplingRate;
    
    % remove dark light intensity
    for i = 1:numCh
        if i == 1
            raw(:,:,i,:) = raw(:,:,i,:) - mean(darkFrames(:,:,i,1:5:size(darkFrames,4)),4);
        else
            raw(:,:,i,:) = raw(:,:,i,:) - mean(darkFrames(:,:,i,:),4);
        end
    end
    
    hbRaw = zeros(size(raw,1)/binSize,size(raw,2)/binSize,numel(hbChInd),size(raw,4));
    for species = 1:size(hbRaw,3)
        for t = 1:size(hbRaw,4)
            hbRaw(:,:,species,t) = mouse.math.bin(raw(:,:,hbChInd(species),t),binSize);
        end
    end
    
    fluorRaw = zeros(size(raw,1)/binSize,size(raw,2)/binSize,numel(fluorChInd),size(raw,4));
    for species = 1:size(fluorRaw,3)
        for t = 1:size(fluorRaw,4)
            fluorRaw(:,:,species,t) = mouse.math.bin(raw(:,:,fluorChInd(species),t),binSize);
        end
    end
    
    speckleRaw = squeeze(raw(:,:,speckleChInd,:));
    maskBinned = mouse.math.bin(mask.isbrain,binSize);
    maskBinned = maskBinned >= 0.5;
    
    clear raw
    
    % process hb
    hbOP = physics.OpticalProperty();
    hbOP.ExtinctCoeffFile = extCoeffFile;
    hbOP.LightSourceFiles = hbSourceFiles;
    hbOP.Musp = muspFcn;
    
    hbProc = process.HbProcessor();
    hbProc.OpticalProperty = hbOP;
    hbProc.Mask = maskBinned;
    hbProc.Detrend = detrendHb;
    hbProc.AffineMarkers = affineMarkers;
    
    xform_datahb = hbProc.process(hbRaw);
    clear hbRaw
    
    % process fluor
    fluorTimeInd = 1:5:size(fluorRaw,4);
    fluorTime = rawTime(fluorTimeInd);
    fluorRaw = fluorRaw(:,:,:,fluorTimeInd);
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
    [xform_datafluorCorr, xform_datafluor] = fluorProc.process(fluorRaw,xform_datahb(:,:,:,fluorTimeInd));
    clear fluorRaw
    
    % process speckle
    spProc = process.SpeckleProcessor();
    spProc.AffineMarkers = mask.I;
    
    xform_cbf = spProc.process(speckleRaw);
    clear speckleRaw
    
    warning('off','all')
    readerInfo = struct(reader);
    hbProcInfo = struct(hbProc);
    fluorProcInfo = struct(fluorProc);
    spProcInfo = struct(spProc);
    warning('on','all')
    
    % save processed data
    if ~exist(saveFolder)
        mkdir(saveFolder);
    end
    save(saveFileDataHb,'dataFileName','readerInfo','hbProcInfo',...
        'hbChInd','rawTime','xform_datahb','-v7.3');
    save(saveFileDataFluor,'dataFileName','readerInfo','fluorProcInfo',...
        'fluorChInd','rawTime','fluorTime','xform_datafluor','xform_datafluorCorr','-v7.3');
    save(saveFileDataSpeckle,'dataFileName','readerInfo','spProcInfo',...
        'speckleChInd','rawTime','xform_cbf','-v7.3');
end

end