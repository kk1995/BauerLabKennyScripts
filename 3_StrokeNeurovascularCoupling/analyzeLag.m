function analyzeLag(excelFile,rows,varargin)
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

tLim = 1.5;

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
    "~",num2str(max(rows)),"-dotLagHbTG6-",freqStr,".mat"));

lagTime = [];
lagAmp = [];
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
        
        fs = fluordata.reader.FreqOut;
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
        [lagTimeTrial,lagAmpTrial,~] = mouse.conn.dotLag(data1,data2,edgeLen,round(tZone*fs),corrThr);
        lagTimeTrial = lagTimeTrial./fs;
        
        % plot lag
        dotLagFig = figure('Position',[100 100 900 400]);
        p = panel();
        p.pack();
        p(1).pack(1,2);
        p(1,1,1).select(); imagesc(lagTimeTrial,'AlphaData',maskTrial,[-tLim tLim]); axis(gca,'square');
        xlim([1 size(lagTimeTrial,1)]); ylim([1 size(lagTimeTrial,2)]);
        set(gca,'ydir','reverse'); colorbar; colormap('jet');
        set(gca,'XTick',[]); set(gca,'YTick',[]); title('Lag Time (s)');
        p(1,1,2).select(); imagesc(lagAmpTrial,'AlphaData',maskTrial,[0.3 1]); axis(gca,'square');
        xlim([1 size(lagAmpTrial,1)]); ylim([1 size(lagAmpTrial,2)]);
        set(gca,'ydir','reverse'); colorbar; colormap('jet');
        set(gca,'XTick',[]); set(gca,'YTick',[]); title('Lag Amp');
        
        % save lag data
        dotLagFile = fullfile(saveFileLocs(trialInd),...
            strcat(saveFileDataNames(trialInd),"-dotLagHbTG6-",freqStr,".mat"));
        save(dotLagFile,'lagTimeTrial','lagAmpTrial','tZone','corrThr','edgeLen');
        
        % save lag figure
        dotLagFigFile = fullfile(saveFileLocs(trialInd),...
            strcat(saveFileDataNames(trialInd),"-dotLagHbTG6-",freqStr,".fig"));
        savefig(dotLagFig,dotLagFigFile);
        close(dotLagFig);
        
        lagTime = cat(3,lagTime,lagTimeTrial);
        lagAmp = cat(3,lagAmp,lagAmpTrial);
    end
    % save lag data
    save(lagFile,'lagTime','lagAmp','mask','tZone','corrThr','edgeLen');
end

%% plot average across trials

saveFileLoc = fileparts(saveFileLocs(1));
[~,excelFileName,~] = fileparts(excelFile);

% roi time course
dotLagFig = figure('Position',[100 100 900 400]);
p = panel();
p.pack();
p(1).pack(1,2);
p(1,1,1).select(); imagesc(nanmean(lagTime,3),'AlphaData',nanmean(mask,3),[-tLim tLim]); axis(gca,'square');
xlim([1 size(lagTime,1)]); ylim([1 size(lagTime,2)]);
set(gca,'ydir','reverse'); colorbar; colormap('jet');
set(gca,'XTick',[]); set(gca,'YTick',[]); title('Lag Time (s)');
p(1,1,2).select(); imagesc(nanmean(lagAmp,3),[0.3 1]); axis(gca,'square');
xlim([1 size(lagAmp,1)]); ylim([1 size(lagAmp,2)]);
set(gca,'ydir','reverse'); colorbar; colormap('jet');
set(gca,'XTick',[]); set(gca,'YTick',[]); title('Lag Amp');

% save lag figure
dotLagFigFile = fullfile(saveFileLoc,...
    strcat(string(excelFileName),"-rows",num2str(min(rows)),...
    "~",num2str(max(rows)),"-dotLagHbTG6-",freqStr,".fig"));
savefig(dotLagFig,dotLagFigFile);
close(dotLagFig);

end

