function analyzeGlobalLag(excelFile,rows,varargin)
%analyzeLag Analyze lag and save the results
%   Inputs:
%       parameters = filtering and other analysis parameters
%           .lowpass = low pass filter thr (if empty, no low pass)
%           .highpass = high pass filter thr (if empty, no high pass)

if numel(varargin) > 0
    parameters = varargin{1};
else
    parameters.lowpass = 0.5; %1/30 Hz
    parameters.highpass = 0.009;
end

freqStr = [num2str(parameters.highpass),'-',num2str(parameters.lowpass)];
freqStr(strfind(freqStr,'.')) = 'p';
freqStr = string(freqStr);

if contains(excelFile,'stim')
    tLim = 1.5;
else
    tLim = 0.5;
end

edgeLen = 3;
tZone = 2;
corrThr = 0.3;

%% import packages

import mouse.*

%% read the excel file to get the list of file names

trialInfo = expSpecific.extractExcel(excelFile,rows);

saveFileLocs = trialInfo.saveFolder;
saveFileMaskNames = trialInfo.saveFilePrefixMask;
saveFileDataNames = trialInfo.saveFilePrefixData;

trialNum = numel(saveFileLocs);

%% get list of processed files

maskFiles = [];
fluorFiles = [];
hbFiles = [];

for trialInd = 1:trialNum
    maskFile = string(fullfile(saveFileLocs(trialInd),...
        strcat(saveFileMaskNames(trialInd),"-LandmarksandMask.mat")));
    maskFiles = [maskFiles maskFile];
    
    hbFile = string(fullfile(saveFileLocs(trialInd),...
        strcat(saveFileDataNames(trialInd),"-datahb.mat")));
    hbFiles = [hbFiles hbFile];
    
    fluorFile = string(fullfile(saveFileLocs(trialInd),...
        strcat(saveFileDataNames(trialInd),"-dataFluor.mat")));
    fluorFiles = [fluorFiles fluorFile];
end

%% load each file and find block response

saveFileLoc = fileparts(saveFileLocs(1));
[~,excelFileName,~] = fileparts(excelFile);
lagFile = fullfile(saveFileLoc,...
    strcat(string(excelFileName),"-rows",num2str(min(rows)),...
    "~",num2str(max(rows)),"-globalLagHbTG6-",freqStr,".mat"));

covResult = [];
mask = [];

if exist(lagFile)
    load(lagFile);
else
    for trialInd = 1:trialNum
        disp(['Trial # ' num2str(trialInd)]);
        maskTrial = load(maskFiles(trialInd));
        maskTrial = maskTrial.xform_isbrain;
        mask = cat(3,mask,maskTrial);
        
        hbdata = load(hbFiles(trialInd));
        fluordata = load(fluorFiles(trialInd));
        try
            xform_datahb = hbdata.data_hb;
        catch
            xform_datahb = hbdata.xform_datahb;
        end
        try
            xform_datafluorCorr = fluordata.data_fluorCorr;
        catch
            xform_datafluorCorr = fluordata.xform_datafluorCorr;
        end
        
        fs = fluordata.readerInfo.FreqOut;
        time = fluordata.rawTime;
        
        % filtering
        if ~isempty(parameters.highpass)
            xform_datahb = highpass(xform_datahb,parameters.highpass,fs);
            xform_datafluorCorr = highpass(xform_datafluorCorr,parameters.highpass,fs);
        end
        if ~isempty(parameters.lowpass)
            xform_datahb = lowpass(xform_datahb,parameters.lowpass,fs);
            xform_datafluorCorr = lowpass(xform_datafluorCorr,parameters.lowpass,fs);
        end
        
        data1 = squeeze(sum(xform_datahb,3));
        data2 = squeeze(xform_datafluorCorr);
        [~,~,covResultTrial] = mouse.conn.dotLag(data1,data2,edgeLen,round(tZone*fs),corrThr);
        avgCovResult = nanmean(covResultTrial(maskTrial,:),1);
        
        time = -floor(numel(avgCovResult)/2):floor(numel(avgCovResult)/2);
        time = time./fs;
        
        % save lag data
        globalLagFile = fullfile(saveFileLocs(trialInd),...
            strcat(saveFileDataNames(trialInd),"-globalLagHbTG6-",freqStr,".mat"));
        save(globalLagFile,'time','maskTrial','covResultTrial');
        
        covResult = cat(1,covResult,avgCovResult);
    end
    % save lag data
    save(lagFile,'time','covResult','mask');
end

end

