function analyzeLag(excelFile,rows,varargin)
%analyzeLag Analyze lag and save the results
%   Inputs:
%       parameters = filtering and other analysis parameters
%           .lowpass = low pass filter thr (if empty, no low pass)
%           .highpass = high pass filter thr (if empty, no high pass)

if numel(varargin) > 0
    parameters = varargin{1};
else
    parameters.lowpass = 0.03; %1/30 Hz
    parameters.highpass = [];
end

blockDesign.expectedLoc = [82 100];

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

dotLagTimeTotal = [];
dotLagAmpTotal = [];

for trialInd = 1:trialNum
    disp(['Trial # ' num2str(trialInd)]);
    mask = load(maskFiles(trialInd));
    
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
    
    data1 = squeeze(xform_datahb(:,:,1,:));
    data2 = squeeze(xform_datafluorCorr);
    [lagTime,lagAmp,~] = mouse.conn.dotLag(data1,data2,edgeLen,round(tZone*fs),corrThr);
    lagTime = lagTime./fs;
    
    % plot lag
    dotLagFig = figure('Position',[100 100 900 400]);
    p = panel();
    p.pack();
    p(1).pack(1,2);
    p(1,1,1).select(); imagesc(lagTime,[-tZone*0.6 tZone*0.6]); axis(gca,'square');
    xlim([1 size(lagTime,1)]); ylim([1 size(lagTime,2)]);
    set(gca,'ydir','reverse'); colorbar;
    set(gca,'XTick',[]); set(gca,'YTick',[]); title('Lag Time (s)');
    p(1,1,2).select(); imagesc(lagAmp,[0.3 1]); axis(gca,'square');
    xlim([1 size(lagAmp,1)]); ylim([1 size(lagAmp,2)]);
    set(gca,'ydir','reverse'); colorbar;
    set(gca,'XTick',[]); set(gca,'YTick',[]); title('Lag Amp');
     
    % save lag data
    dotLagFile = fullfile(saveFileLocs(trialInd),...
        strcat(saveFileDataNames(trialInd),"-dotLagHbOG6.mat"));
    save(dotLagFile,'lagTime','lagAmp','tZone','corrThr','edgeLen');
    
    % save lag figure
    dotLagFigFile = fullfile(saveFileLocs(trialInd),...
        strcat(saveFileDataNames(trialInd),"-dotLagHbOG6.fig"));
    savefig(dotLagFig,dotLagFigFile);
    close(dotLagFig);
    
    dotLagTimeTotal = cat(3,dotLagTimeTotal,lagTime);
    dotLagAmpTotal = cat(3,dotLagAmpTotal,lagAmp);
    
    % gs lag
    data = squeeze(xform_datahb(:,:,1,:));
    [lagTime,lagAmp,~] = mouse.conn.gsLag(data,mask.xform_isbrain,edgeLen,round(tZone*fs),corrThr);
    
    % save lag data
    gsLagFile = fullfile(saveFileLocs(trialInd),...
        strcat(saveFileDataNames(trialInd),"-gsLagHbO.mat"));
    save(gsLagFile,'lagTime','lagAmp','mask','tZone','corrThr','edgeLen');
    
    % gs lag gcamp
    data = squeeze(xform_datafluorCorr);
    [lagTime,lagAmp,~] = mouse.conn.gsLag(data,mask.xform_isbrain,edgeLen,round(tZone*fs),corrThr);
    
    % save lag data
    gsLagFile = fullfile(saveFileLocs(trialInd),...
        strcat(saveFileDataNames(trialInd),"-gsLagG6.mat"));
    save(gsLagFile,'lagTime','lagAmp','mask','tZone','corrThr','edgeLen');
end

%% plot average across trials

saveFileLoc = fileparts(saveFileLocs(1));
[~,excelFileName,~] = fileparts(excelFile);

% roi time course
dotLagFig = figure('Position',[100 100 900 400]);
p = panel();
p.pack();
p(1).pack(1,2);
p(1,1,1).select(); imagesc(nanmean(dotLagTimeTotal,3),[-tZone*0.6 tZone*0.6]); axis(gca,'square');
xlim([1 size(dotLagTimeTotal,1)]); ylim([1 size(dotLagTimeTotal,2)]);
set(gca,'ydir','reverse'); colorbar;
set(gca,'XTick',[]); set(gca,'YTick',[]); title('Lag Time (s)');
p(1,1,2).select(); imagesc(nanmean(dotLagAmpTotal,3),[0.3 1]); axis(gca,'square');
xlim([1 size(dotLagAmpTotal,1)]); ylim([1 size(dotLagAmpTotal,2)]);
set(gca,'ydir','reverse'); colorbar;
set(gca,'XTick',[]); set(gca,'YTick',[]); title('Lag Amp');

% save lag figure
dotLagFigFile = fullfile(saveFileLoc,...
    strcat(string(excelFileName),"-rows",num2str(min(rows)),...
    "~",num2str(max(rows)),"-dotLagHbOG6.fig"));
savefig(dotLagFig,dotLagFigFile);
close(dotLagFig);

end

