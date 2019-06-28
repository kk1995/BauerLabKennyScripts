function runsInfo = parseTiffRunsProbe(excelFile,excelRows)
%parseTiffRuns Parses information from excel sheet about tiff runs and
%outputs information about each run

runsInfo = [];

excelData = readtable(excelFile);
tableRows = excelRows - 1;

totalRunInd = 0;
for row = tableRows % for each row of excel file
    % required info for each excel row
    rawDataLoc = excelData{row,'RawDataLocation'}; rawDataLoc = rawDataLoc{1};
    recDate = num2str(excelData{row,'Date'});
    if iscell(recDate)
        recDate = recDate{1};
    else
        recDate = num2str(recDate);
    end
    saveLoc = excelData{row,'SaveLocation'}; saveLoc = saveLoc{1};
    mouseName = excelData{row,'Mouse'}; mouseName = mouseName{1};
    sessionType = excelData{row,'Session'}; sessionType = sessionType{1}(3:end-2);
    system = excelData{row,'System'}; system = system{1};
    samplingRate = excelData{row,'SamplingRate'};
    
    dataLoc = fullfile(rawDataLoc,recDate); % where raw data is located
    D = dir(dataLoc); D(1:2) = [];
    
    % find out valid files
    validFile = false(1,numel(D));
    for file = 1:numel(D)
        validFile(file) = contains(D(file).name,'.tif') ...
            && contains(D(file).name,['-' mouseName '-']);
    end
    validFiles = D(validFile);
    
    % for each run, create a listing on output
    for run = 1:2
        totalRunInd = totalRunInd + 1;
        
        runFiles = false(numel(validFiles),1);
        if run == 1
            for i = 1:numel(validFiles)
                runFiles(i) = contains(validFiles(i).name,'Pre');
            end
        else
            for i = 1:numel(validFiles)
                runFiles(i) = contains(validFiles(i).name,'Post');
            end
        end
        runFiles = validFiles(runFiles);
        
        runFilesList = cell(1,numel(runFiles));
        for file = 1:numel(runFiles)
            runFilesList{file} = fullfile(runFiles(file).folder,runFiles(file).name);
        end
        
        % default
        qc = true;
        samplingRateHb = min([samplingRate,2]); % hb sampling rate
        samplingRateFluor = samplingRate;
        samplingRateCbf = min([samplingRate,2]);
        stimRoiSeed = [63 30]/128;
        stimStartTime = 5;
        stimEndTime = 10;
        blockLen = 60;
        affineTransform = true;
        window = [-5 5 -5 5]; % y min, y max, x min, x max (in mm)
        numDarkFrames = 0;
        detrendHb = 1;
        detrendFluor = 1;
        saveRaw = 0;
        
        % get common file name for both mask and data files
        saveFolder = fullfile(saveLoc,recDate);
        saveFileName = runFiles(1).name; [~,saveFileName] = fileparts(saveFileName);
        
        % get mask file name
        dashInd = strfind(saveFileName,'-');
        saveMaskFile = [saveFileName(1:dashInd(end)-1) '-LandmarksAndMask.mat'];
        saveMaskFile = fullfile(saveLoc,recDate,saveMaskFile);
        
        % get data file name
        saveFilePrefix = saveFileName;
        saveFilePrefix = fullfile(saveLoc,recDate,saveFilePrefix);
        saveRawFile = [saveFilePrefix '-dataRaw.mat'];
        saveHbFile = [saveFilePrefix '-dataHb.mat'];
        saveFluorFile = [saveFilePrefix '-dataFluor.mat'];
        saveCbfFile = [saveFilePrefix '-dataCbf.mat'];
        
        % get qc file name
        saveRawQCFig = [saveFilePrefix '-rawQC'];
        saveFCQCFig = [saveFilePrefix '-fcQC'];
        saveStimQCFig = [saveFilePrefix '-stimQC'];
        saveRawQCFile = [saveFilePrefix '-rawQC.mat'];
        saveFCQCFile = [saveFilePrefix '-fcQC.mat'];
        saveStimQCFile = [saveFilePrefix '-stimQC.mat'];
        
        % get system info and values dependent on system
        systemInfo = mouse.expSpecific.sysInfo(system);
        numCh = systemInfo.numLEDs;
        lightSourceFiles = systemInfo.LEDFiles;
        fluorFiles = systemInfo.fluorFiles;
        rgbInd = systemInfo.rgb;
        gbox = systemInfo.gbox;
        gsigma = systemInfo.gsigma;
        validThr = systemInfo.validThr;
        numInvalidFrames = systemInfo.numInvalidFrames;
        binFactor = systemInfo.binFactor;
        hbChInd = systemInfo.chHb;
        fluorChInd = systemInfo.chFluor;
        speckleChInd = systemInfo.chSpeckle;
        
        % check if these values are stated in excel. If so, override.
        variableNames = {'NumCh','HbChInd','FluorChInd','SpeckleChInd','RGBInd',...
            'GBox','GSigma','ValidThreshold','NumDarkFrames','NumInvalidFrames',...
            'DetrendHb','DetrendFluor','SaveRaw','SaveMaskFile','SaveRawFile',...
            'SaveHbFile','SaveFluorFile','SaveCbfFile','QC','SamplingRateHb',...
            'SamplingRateFluor','SamplingRateCbf','StimRoiSeed','StimStartTime','StimEndTime',...
            'BlockLen','BinFactor','AffineTransform','Window'};
        expectedType = [1,1,1,1,1,...
            1,1,1,1,1,...
            1,1,1,2,2,...
            2,2,2,1,1,...
            1,1,1,1,1,...
            1,1,1,1]; % 1 means double, 2 means char
        defaultVal = {numCh,hbChInd,fluorChInd,speckleChInd,rgbInd,...
            gbox,gsigma,validThr,numDarkFrames,numInvalidFrames,...
            detrendHb,detrendFluor,saveRaw,saveMaskFile,saveRawFile,...
            saveHbFile,saveFluorFile,saveCbfFile,qc,samplingRateHb,...
            samplingRateFluor,samplingRateCbf,stimRoiSeed,stimStartTime,stimEndTime,...
            blockLen,binFactor,affineTransform,window};
        
        for varInd = 1:numel(variableNames)
            varOutName = variableNames{varInd}; varOutName(1) = lower(varOutName(1));
            eval([varOutName ' = defaultVal{varInd};']); % define default values
            varExists = sum(~cellfun(@isempty,strfind(...
                excelData.Properties.VariableNames,variableNames{varInd}))) > 0;
            if varExists
                cellData = excelData{row,variableNames{varInd}};
                if expectedType(varInd) == 1 % expected double
                    if iscell(cellData)
                        if ~isempty(cellData)
                            cellData = cellfun(@str2double,strsplit(cellData{1},','));
                            eval([varOutName ' = cellData;']);
                        end
                    elseif isnan(cellData)
                    else
                        eval([varOutName ' = cellData;']);
                    end
                elseif expectedType(varInd) == 2 % expected char array
                    if iscell(cellData) && ~isempty(cellData)
                        eval([varOutName ' = cellData;']);
                    end
                end
            end
        end
        
        darkFramesInd = 1:numDarkFrames;
        invalidFramesInd = 1:numInvalidFrames;
        
        % add to struct
        runsInfo(totalRunInd).excelRow = row + 1;
        runsInfo(totalRunInd).mouseName = mouseName;
        runsInfo(totalRunInd).recDate = recDate;
        runsInfo(totalRunInd).run = run;
        runsInfo(totalRunInd).samplingRate = samplingRate;
        runsInfo(totalRunInd).samplingRateHb = samplingRateHb;
        runsInfo(totalRunInd).samplingRateFluor = samplingRateFluor;
        runsInfo(totalRunInd).samplingRateCbf = samplingRateCbf;
        runsInfo(totalRunInd).darkFramesInd = darkFramesInd;
        runsInfo(totalRunInd).invalidFramesInd = invalidFramesInd;
        runsInfo(totalRunInd).rawFile = runFilesList;
        runsInfo(totalRunInd).lightSourceFiles = lightSourceFiles;
        runsInfo(totalRunInd).fluorFiles = fluorFiles;
        runsInfo(totalRunInd).numCh = numCh;
        runsInfo(totalRunInd).binFactor = binFactor;
        runsInfo(totalRunInd).rgbInd = rgbInd;
        runsInfo(totalRunInd).hbChInd = hbChInd;
        runsInfo(totalRunInd).fluorChInd = fluorChInd;
        runsInfo(totalRunInd).speckleChInd = speckleChInd;
        runsInfo(totalRunInd).window = window;
        runsInfo(totalRunInd).gbox = gbox;
        runsInfo(totalRunInd).gsigma = gsigma;
        runsInfo(totalRunInd).detrendHb = detrendHb;
        runsInfo(totalRunInd).detrendFluor = detrendFluor;
        runsInfo(totalRunInd).qc = qc;
        runsInfo(totalRunInd).stimRoiSeed = stimRoiSeed;
        runsInfo(totalRunInd).stimStartTime = stimStartTime;
        runsInfo(totalRunInd).stimEndTime = stimEndTime;
        runsInfo(totalRunInd).blockLen = blockLen;
        runsInfo(totalRunInd).validThr = validThr;
        runsInfo(totalRunInd).saveRaw = saveRaw;
        runsInfo(totalRunInd).saveFolder = saveFolder;
        runsInfo(totalRunInd).saveMaskFile = saveMaskFile;
        runsInfo(totalRunInd).saveFilePrefix = saveFilePrefix;
        runsInfo(totalRunInd).saveRawFile = saveRawFile;
        runsInfo(totalRunInd).saveHbFile = saveHbFile;
        runsInfo(totalRunInd).saveFluorFile = saveFluorFile;
        runsInfo(totalRunInd).saveCbfFile = saveCbfFile;
        runsInfo(totalRunInd).saveRawQCFig = saveRawQCFig;
        runsInfo(totalRunInd).saveFCQCFig = saveFCQCFig;
        runsInfo(totalRunInd).saveStimQCFig = saveStimQCFig;
        runsInfo(totalRunInd).saveRawQCFile = saveRawQCFile;
        runsInfo(totalRunInd).saveFCQCFile = saveFCQCFile;
        runsInfo(totalRunInd).saveStimQCFile = saveStimQCFile;
        runsInfo(totalRunInd).system = system;
        runsInfo(totalRunInd).session = sessionType;
        runsInfo(totalRunInd).affineTransform = affineTransform;
    end
end
end

