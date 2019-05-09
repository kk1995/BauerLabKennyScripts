function processRaw(excelFile,rows)

% this function gives an example of how excel file is read, the data is
% loaded, invalid frames are removed, and processed to save hemoglobin
% dynamics data.

%% read excel file to get information about each mouse run

[~,~,excelData] = xlsread(excelFile,1,['A1:' xlscol(7) num2str(max(rows))]);

runInd = 0;
for row = rows % for each row of excel file
    dataLoc = fullfile(excelData{row,3},num2str(excelData{row,1})); % where raw data is located
    D = dir(dataLoc); D(1:2) = [];
    
    for file = 1:numel(D) % for each file
        sessionType = excelData{row,6}; sessionType = sessionType(3:end-2);
        saveFileName = D(file).name; saveFileName = saveFileName(1:end-4);
        if contains(D(file).name,excelData{row,2}) && contains(D(file).name,sessionType) % if the right data file
            runInd = runInd + 1;
            runInfo(runInd).rawFile = fullfile(D(file).folder,D(file).name);
            runInfo(runInd).saveMaskFilePrefix = fullfile(excelData{row,4},num2str(excelData{row,1}),saveFileName(1:end-1));
            runInfo(runInd).saveDataFilePrefix = fullfile(excelData{row,4},num2str(excelData{row,1}),saveFileName);
            runInfo(runInd).samplingRate = excelData{row,7};
            runInfo(runInd).system = excelData{row,5};
            runInfo(runInd).session = sessionType;
        end
    end
end

% provide information about the processing stream
paramPath = what('bauerParams'); % path to bauerParams module
sourceSpectraLoc = fullfile(paramPath.path,'ledSpectra'); % path to led spectra text files
extCoeffFile = string(fullfile(paramPath.path,'prahl_extinct_coef.txt'));
fluorSpectraFile = string(fullfile(paramPath.path,'probeSpectra','gcamp6f_emission.txt')); % which file describes fluor emission spectra
numCh = 4; % reader parameter. how many channels in image file?
hbChInd = 2:4; % which channels should be used for hemoglobin?
fluorChInd = 1; % which channel should be used for fluorescence?
invalidFrameInd = 1; % which time frame should be removed (not even used for dark frame calculation)
darkFrameInd = []; % which time frame is dark frame?
detrendHb = true; % should raw data for hemoglobin be temporally detrended?
detrendFluor = true; % should raw data for fluorescence be temporally detrended?
muspFcn = @(x,y) (40*(x/500).^-1.16)'*y; % parametric equation for reduced scattering coefficient

%% run wl generation for each trial
disp('get wl image and mask');

runNum = numel(runInfo);

for runInd = 1:runNum % for each run
    disp(['Trial # ' num2str(runInd) '/' num2str(runNum)]);
    
    % find the full mask file directory. This file will be checked for
    % mask. If this file does not exist, following if/else statement
    % creates the file.
    maskFileName = strcat(runInfo(runInd).saveMaskFilePrefix,"-LandmarksandMask.mat");
    saveFolder = fileparts(maskFileName);
    
    systemInfo = sysInfo(runInfo(runInd).system); % find information about the system
    rgbOrder = systemInfo.rgb; % which channels are red, green, and blue?
    
    % instantiate VideosReader - reads the raw files to output matrix
    reader = mouse.read.VideosReader();
    reader.ReaderObject = mouse.read.TiffVideoReader;
    reader.ReaderObject.ChNum = numCh;
    reader.DarkFrameInd = darkFrameInd;
    reader.InvalidInd = invalidFrameInd;
    reader.FreqIn = runInfo(runInd).samplingRate;
    reader.FreqOut = runInfo(runInd).samplingRate;
    
    % create the white light image and mask file if it does not exist
    if ~exist(maskFileName)
        
        [isbrain,xform_isbrain,I,WL] = getMask(runInfo(runInd).rawFile,reader,rgbOrder);
        
        if ~exist(saveFolder)
            mkdir(saveFolder);
        end
        
        save(maskFileName,'isbrain','I','xform_isbrain','WL','-v7.3');
    end
end

%% preprocess and process
disp('preprocess and process');

for runInd = 1:runNum
    disp(['Trial # ' num2str(runInd) '/' num2str(runNum)]);
    
    maskFileName = [runInfo(runInd).saveMaskFilePrefix,'-LandmarksandMask.mat']; % mask file to save'
    dataFileName = runInfo(runInd).rawFile;
    saveFileDataHb = [runInfo(runInd).saveDataFilePrefix,'-datahb.mat']; % hemoglobin file to save
    saveFileDataFluor = [runInfo(runInd).saveDataFilePrefix,'-datafluor.mat']; % hemoglobin file to save
    saveFolder = fileparts(dataFileName);
    
    systemInfo = sysInfo(runInfo(runInd).system); % find information about the system
    ledFiles = systemInfo.LEDFiles; % which channels are red, green, and blue?
    
    % get led files
    for i = 1:numel(hbChInd)
        chInd = hbChInd(i);
        hbLEDFiles{i} = fullfile(sourceSpectraLoc,ledFiles{chInd});
    end
    for i = 1:numel(fluorChInd)
        chInd = fluorChInd(i);
        fluorLEDFiles{i} = fullfile(sourceSpectraLoc,ledFiles{chInd});
    end
    
    % load mask
    mask = load(maskFileName);
    isbrain = mask.isbrain;
    
    % instantiate VideosReader
    reader = mouse.read.VideosReader();
    reader.ReaderObject = mouse.read.TiffVideoReader; % which raw file reader should be used? (tiff, dat)
    reader.ReaderObject.ChNum = numCh; % how many channels?
    reader.DarkFrameInd = darkFrameInd; % which time frames are dark?
    reader.InvalidInd = invalidFrameInd; % which time frames are invalid?
    reader.FreqIn = runInfo(runInd).samplingRate; % what is the sampling rate of raw data?
    reader.FreqOut = runInfo(runInd).samplingRate; % what should be the output sampling rate?
    reader.TimeFrames = [];
    
    % get optical properties of hemoglobin
    hbOP = mouse.physics.OpticalProperty();
    hbOP.ExtinctCoeffFile = extCoeffFile; % what is the extinction coefficient? (txt file)
    hbOP.LightSourceFiles = hbLEDFiles; % what are the light sources? (txt file)
    hbOP.Musp = muspFcn; % what is the reduced scattering coefficient? (function)
    
    % instantiate HbProcessor - processes raw matrix to hemoglobin data
    % (procOIS)
    hbProc = mouse.process.HbProcessor();
    hbProc.OpticalProperty = hbOP; % what are the hemoglobin optical properties?
    hbProc.Detrend = detrendHb; % should we detrend hemoglobin?
    
    % get optical properties of excitation light
    fluorInOP = mouse.physics.OpticalProperty();
    fluorInOP.ExtinctCoeffFile = extCoeffFile;
    fluorInOP.LightSourceFiles = fluorLEDFiles; % the LED file describing excitation light spectra
    fluorInOP.Musp = muspFcn;
    
    % get optical properties of emission light
    fluorOutOP = mouse.physics.OpticalProperty();
    fluorOutOP.ExtinctCoeffFile = extCoeffFile;
    fluorOutOP.LightSourceFiles = fluorSpectraFile; % the file describing emission light spectra
    fluorOutOP.Musp = muspFcn;
    
    % instantiate HbProcessor - processes raw matrix and hemoglobin to
    % fluor
    fluorProc = mouse.process.FluorProcessor();
    fluorProc.Detrend = detrendFluor;
    fluorProc.OpticalPropertyIn = fluorInOP;
    fluorProc.OpticalPropertyOut = fluorOutOP;
    
    disp('read');
    [raw,rawTime] = reader.read(dataFileName);
    
    disp('process hb');
    datahb = hbProc.process(raw(:,:,hbChInd,:));
    
    disp('process fluor');
    datafluor = fluorProc.process(raw(:,:,fluorChInd,:),datahb);
    
    disp('affine transform');
    xform_datahb = mouse.process.affineTransform(datahb,mask.I);
    xform_datafluor = mouse.process.affineTransform(datafluor,mask.I);
    xform_isbrain = mouse.process.affineTransform(isbrain,mask.I);
    
    disp('save');
    warning('off','all')
    readerInfo = struct(reader);
    hbProcInfo = struct(hbProc);
    fluorProcInfo = struct(fluorProc);
    warning('on','all')
    
    % save processed data
    if ~exist(saveFolder)
        mkdir(saveFolder);
    end
    fs = readerInfo.FreqOut;
    
    % save the processed data in hemoglobin data file
    save(saveFileDataHb,'dataFileName','readerInfo','hbProcInfo','fs',...
        'isbrain','xform_isbrain','hbChInd','rawTime','xform_datahb','-v7.3');
    
    % save the processed fluor data in fluorescence data file
    save(saveFileDataFluor,'dataFileName','readerInfo','fluorProcInfo',...
        'fs','isbrain','xform_isbrain','fluorChInd','rawTime','xform_datafluor','-v7.3');
end

end

function [isbrain,xform_isbrain,affineMarkers,WL] = getMask(fileNames,reader,rgbOrder)
%getMask Outputs mask data from raw data
%   By providing which files to read, as well as the reader object and
%   indices of red, green, and blue LEDs, we instantiate a GUI that runs
%   shows the white light image and allows user to determine the mask.

badDataInd = unique([reader.DarkFrameInd reader.InvalidInd]);
realDataStart = max(badDataInd) + 1;
reader.TimeFrames = 1:realDataStart;
[raw,~] = reader.read(fileNames);
raw = raw(:,:,:,size(raw,4));
raw = single(raw);
WL = mouse.process.getWL(raw,rgbOrder);
affineMarkers = mouse.process.getLandmarks(WL);
isbrain = mouse.process.getMask(WL);
xform_isbrain = mouse.process.affineTransform(isbrain,affineMarkers);
end