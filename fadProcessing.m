function fadProcessing(excelFile,rows)

% this function gives an example of how excel file is read, the data is
% loaded, invalid frames are removed, and processed to save hemoglobin and
% fluorescence dynamics data.
% The excel file uses the format Annie uses, which has one mouse data per
% row and minimal amount of information about sampling rate and other
% parameters. Thus, some of these parameters are assumed and hardcoded
% here.
%
% Inputs:
%   excelFile = character array of the excel file to be read
%   rows = which rows in the excel file should be read and processed?

%% parameters
numCh = 4; % reader parameter. how many channels in image file?
hbChInd = 2:4; % which channels should be used for hemoglobin?
fluorChInd = 1; % which channel should be used for fluorescence?
fluorEmissionTxtFile = 'fad_emission.txt'; % text file for describing fluorophore emission spectra
numDarkFrames = 5; % which time frame is dark frame?
detrendHb = true; % should raw data for hemoglobin be temporally detrended?
detrendFluor = true; % should raw data for fluorescence be temporally detrended?
saveRaw = false; % should raw data (downsampled) be saved?

%% read excel file to get information about each mouse run

excelData = readtable(excelFile);

runInd = 0;
for row = rows-1 % for each row of excel file
    rawDataLoc = excelData{row,'RawDataLocation'}; rawDataLoc = rawDataLoc{1};
    recDate = num2str(excelData{row,'Date'});
    saveLoc = excelData{row,'SaveLocation'}; saveLoc = saveLoc{1};
    mouseName = excelData{row,'Mouse'}; mouseName = mouseName{1};
    sessionType = excelData{row,'Session'}; sessionType = sessionType{1}(3:end-2);
    system = excelData{row,'System'}; system = system{1};
    samplingRate = excelData{row,'SamplingRate'};
    
    dataLoc = fullfile(rawDataLoc,recDate); % where raw data is located
    D = dir(dataLoc); D(1:2) = [];
    
    for file = 1:numel(D) % for each file
        validFile = contains(D(file).name,mouseName) && contains(D(file).name,sessionType);
        if validFile % if the right data file
            runInd = runInd + 1;
            
            saveFileName = D(file).name; saveFileName = saveFileName(1:end-4);
            saveMaskPrefix = strfind(saveFileName,'-'); saveMaskPrefix = saveFileName(1:saveMaskPrefix(end)-1);
            saveDataPrefix = saveFileName;
            
            runInfo(runInd).rawFile = fullfile(D(file).folder,D(file).name);
            runInfo(runInd).saveMaskFilePrefix = fullfile(saveLoc,...
                recDate,saveMaskPrefix);
            runInfo(runInd).saveDataFilePrefix = fullfile(saveLoc,...
                recDate,saveDataPrefix);
            runInfo(runInd).samplingRate = samplingRate;
            runInfo(runInd).system = system;
            runInfo(runInd).session = sessionType;
        end
    end
end

% provide information about the processing stream
paramPath = what('bauerParams'); % path to bauerParams module
sourceSpectraLoc = fullfile(paramPath.path,'ledSpectra'); % path to led spectra text files
extCoeffFile = fullfile(paramPath.path,'prahl_extinct_coef.txt');
fluorSpectraFile = cellstr(fullfile(paramPath.path,'probeSpectra',fluorEmissionTxtFile)); % which file describes fluor emission spectra
muspFcn = @(x,y) (40*(x/500).^-1.16)'*y; % parametric equation for reduced scattering coefficient

%% run wl generation for each trial
disp('get wl image and mask');

runNum = numel(runInfo);

for runInd = 1:runNum % for each run
    disp(['Trial # ' num2str(runInd) '/' num2str(runNum)]);
    
    % find the full mask file directory. This file will be checked for
    % mask. If this file does not exist, following if/else statement
    % creates the file.
    maskFileName = [runInfo(runInd).saveMaskFilePrefix,'-LandmarksandMask.mat'];
    saveFolder = fileparts(maskFileName);
    
    systemInfo = sysInfo(runInfo(runInd).system); % find information about the system
    rgbOrder = systemInfo.rgb; % which channels are red, green, and blue?
    invalidFrameInd = systemInfo.invalidFrameInd;
    
    % instantiate VideosReader - reads the raw files to output matrix
    reader = mouse.read.VideosReader();
    reader.ReaderObject = mouse.read.TiffVideoReader;
    reader.ChNum = numCh;
    reader.DarkFrameInd = 1:numDarkFrames;
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
    saveFileRaw = [runInfo(runInd).saveDataFilePrefix,'-raw.mat']; % raw file to save
    saveFigRawQC = [runInfo(runInd).saveDataFilePrefix,'-rawQC.fig']; % raw file to save
    saveFigFCQC = [runInfo(runInd).saveDataFilePrefix,'-fcQC.fig']; % raw file to save
    saveFileDataHb = [runInfo(runInd).saveDataFilePrefix,'-datahb.mat']; % hemoglobin file to save
    saveFileDataFluor = [runInfo(runInd).saveDataFilePrefix,'-datafluor.mat']; % hemoglobin file to save
    saveFolder = fileparts(dataFileName);
    
    systemInfo = sysInfo(runInfo(runInd).system); % find information about the system
    ledFiles = systemInfo.LEDFiles; % which channels are red, green, and blue?
    invalidFrameInd = systemInfo.invalidFrameInd;
    validThr = systemInfo.validThr;
    sessionType = runInfo(runInd).session;
    fs = runInfo(runInd).samplingRate;
    
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
    reader.ChNum = numCh; % how many channels?
    reader.DarkFrameInd = 1:numDarkFrames; % which time frames are dark?
    reader.InvalidInd = invalidFrameInd; % which time frames are invalid?
    reader.FreqIn = fs; % what is the sampling rate of raw data?
    reader.FreqOut = fs; % what should be the output sampling rate?
    
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
    % use reader object to read the data files
    [raw,rawTime] = reader.read(dataFileName);
    
    disp('process hb');
    % output hb data from led intensity data
    datahb = hbProc.process(raw(:,:,hbChInd,:));
    
    disp('process fluor');
    % output fluor data from led intensity data
    datafluorCorr = fluorProc.process(raw(:,:,fluorChInd,:),datahb);
    
    disp('affine transform');
    xform_datahb = mouse.process.affineTransform(datahb,mask.I);
    xform_datafluorCorr = mouse.process.affineTransform(datafluorCorr,mask.I);
    xform_isbrain = mouse.process.affineTransform(isbrain,mask.I);
    
    disp('quality control');
    % check for movement. These outputs are saved with processed data
    invalidData = mouse.qc.checkRange(raw,validThr);
    representativeCh = hbChInd(1);
    qcRawFig = mouse.expSpecific.qcRaw(rawTime,raw,representativeCh);
    savefig(qcRawFig,saveFigRawQC);
    close(qcRawFig);
    
    % make qc fc fig if fc session
    if contains(sessionType,'fc')
        fcFig = mouse.expSpecific.qcFC(sum(xform_datahb,3),xform_isbrain,fs);
        savefig(fcFig,saveFigFCQC);
        close(fcFig);
    end
    
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
    
    if saveRaw
        save(saveFileRaw,'dataFileName','readerInfo','invalidData',...
            'rawTime','raw','-v7.3');
    end
    
    % save the processed data in hemoglobin data file
    save(saveFileDataHb,'dataFileName','hbProcInfo','fs',...
        'isbrain','xform_isbrain','hbChInd','rawTime','xform_datahb','-v7.3');
    
    % save the processed fluor data in fluorescence data file
    save(saveFileDataFluor,'dataFileName','fluorProcInfo','fs',...
        'isbrain','xform_isbrain','fluorChInd','rawTime','xform_datafluorCorr','-v7.3');
end

end

function [isbrain,xform_isbrain,affineMarkers,WL] = getMask(fileNames,reader,rgbOrder)
%getMask Outputs mask data from raw data
%   By providing which files to read, as well as the reader object and
%   indices of red, green, and blue LEDs, we instantiate a GUI that runs
%   shows the white light image and allows user to determine the mask.

badDataInd = unique([reader.DarkFrameInd reader.InvalidInd]);
realDataStart = max(badDataInd) + 1;
reader.LastTimeFrame = realDataStart;
[raw,~] = reader.read(fileNames);
raw = single(raw);
WL = mouse.process.getWL(raw,rgbOrder);
affineMarkers = mouse.process.getLandmarks(WL);
isbrain = mouse.process.getMask(WL);
xform_isbrain = mouse.process.affineTransform(isbrain,affineMarkers);
end