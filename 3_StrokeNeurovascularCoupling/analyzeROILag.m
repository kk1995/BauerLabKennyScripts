function analyzeROILag(excelFile,rows,varargin)
%analyzeLag Analyze lag and save the results
%   Inputs:
%       parameters = filtering and other analysis parameters
%           .lowpass = low pass filter thr (if empty, no low pass)
%           .highpass = high pass filter thr (if empty, no high pass)

if numel(varargin) > 0
    parameters = varargin{1};
else
    parameters.lowpass = 0.08; %1/30 Hz
    parameters.highpass = 0.01;
end

if numel(varargin) > 1
    blockDesign = varargin{2};
else
    blockDesign.expectedLoc = [83 26];
    blockDesign.off = 5;
    blockDesign.on = 5;
    blockDesign.off2 = 10;
end

freqStr = [num2str(parameters.highpass),'-',num2str(parameters.lowpass)];
freqStr(strfind(freqStr,'.')) = 'p';
freqStr = string(freqStr);

if parameters.highpass < 0.5
    tLim = 0.5;
else
    tLim = 0.2;
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

lagTimeHbT = nan(128,128,trialNum);
lagTimeG6 = nan(128,128,trialNum);
lagAmpHbT = nan(128,128,trialNum);
lagAmpG6 = nan(128,128,trialNum);
mask = nan(128,128,trialNum);
roi = nan(128,128,trialNum);

for trialInd = 1:trialNum
    disp(['Trial # ' num2str(trialInd)]);
    maskTrial = load(maskFiles(trialInd));
    maskTrial = maskTrial.xform_isbrain;
    mask(:,:,trialInd) = maskTrial;
    
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
    
    raw = cat(3,xform_datahb,xform_datafluorCorr);
    blockLen = blockDesign.off + blockDesign.on + blockDesign.off2;
    blockCut = round(fs*blockLen);
    [blockData, blockTime] = mouse.expSpecific.blockAvg(raw,time,blockLen,blockCut);
    stimInd = blockTime > blockDesign.off + blockDesign.on - 1 & ...
        blockTime < blockDesign.off + blockDesign.on + 1;
    stimResponse = mean(blockData(:,:,:,stimInd),4); % 128 x 128 x 3

    % get roi
    roiTrial = mouse.expSpecific.getROI(stimResponse(:,:,3),blockDesign.expectedLoc);
    roi(:,:,trialInd) = roiTrial;

    % gs lag
    data = squeeze(sum(xform_datahb,3));
    [lagTimeHbTTrial,lagAmpHbTTrial] = mouse.conn.regionalLag(data,roiTrial,edgeLen,round(tZone*fs),corrThr);
    lagTimeHbTTrial(lagAmpHbTTrial < 0) = nan;
    lagTimeHbTTrial = lagTimeHbTTrial./fs;
    
    lagTimeHbT(:,:,trialInd) = lagTimeHbTTrial;
    lagAmpHbT(:,:,trialInd) = lagAmpHbTTrial;
    
    % save lag data
    gsLagFile = fullfile(saveFileLocs(trialInd),...
        strcat(saveFileDataNames(trialInd),"-roiLagHbT-",freqStr,".mat"));
    save(gsLagFile,'roiTrial','lagTimeHbTTrial','lagAmpHbTTrial','maskTrial','tZone','corrThr','edgeLen');
    
    % gs lag gcamp
    data = squeeze(xform_datafluorCorr);
    [lagTimeG6Trial,lagAmpG6Trial] = mouse.conn.regionalLag(data,roiTrial,edgeLen,round(tZone*fs),corrThr);
    lagTimeG6Trial(lagAmpG6Trial < 0) = nan;
    lagTimeG6Trial = lagTimeG6Trial./fs;
    
    lagTimeG6(:,:,trialInd) = lagTimeG6Trial;
    lagAmpG6(:,:,trialInd) = lagAmpG6Trial;
    
    % save lag data
    gsLagFile = fullfile(saveFileLocs(trialInd),...
        strcat(saveFileDataNames(trialInd),"-roiLagG6-",freqStr,".mat"));
    save(gsLagFile,'roiTrial','lagTimeG6Trial','lagAmpG6Trial','maskTrial','tZone','corrThr','edgeLen');
    
    % gs lag plot
    lagFig = figure('Position',[100 100 700 500]);
    p = panel();
    p.pack();
    p(1).pack(2,2);
    p(1,1,1).select(); imagesc(lagTimeHbTTrial,[-tLim tLim]); axis(gca,'square');
    xlim([1 size(data,1)]); ylim([1 size(data,2)]); colormap('jet');
    set(gca,'ydir','reverse'); colorbar;
    set(gca,'XTick',[]); set(gca,'YTick',[]); title('HbT Lag Time (s)');
    p(1,1,2).select(); imagesc(lagAmpHbTTrial,[0.3 1]); axis(gca,'square');
    xlim([1 size(data,1)]); ylim([1 size(data,2)]); colormap('jet');
    set(gca,'ydir','reverse'); colorbar;
    set(gca,'XTick',[]); set(gca,'YTick',[]); title('HbT Lag Amp');
    p(1,2,1).select(); imagesc(lagTimeG6Trial,[-tLim/2 tLim/2]); axis(gca,'square');
    xlim([1 size(data,1)]); ylim([1 size(data,2)]); colormap('jet');
    set(gca,'ydir','reverse'); colorbar;
    set(gca,'XTick',[]); set(gca,'YTick',[]); title('G6 Lag Time (s)');
    p(1,2,2).select(); imagesc(lagAmpG6Trial,[0.3 1]); axis(gca,'square');
    xlim([1 size(data,1)]); ylim([1 size(data,2)]); colormap('jet');
    set(gca,'ydir','reverse'); colorbar;
    set(gca,'XTick',[]); set(gca,'YTick',[]); title('G6 Lag Amp');
    
    % save lag figure
    lagFigFile = fullfile(saveFileLocs(trialInd),...
        strcat(saveFileDataNames(trialInd),"-roiLagHbTG6-",freqStr,".fig"));
    savefig(lagFig,lagFigFile);
    close(lagFig);
    
end

%% plot average across trials

saveFileLoc = fileparts(saveFileLocs(1));
[~,excelFileName,~] = fileparts(excelFile);

% save lag data
gsLagFile = fullfile(saveFileLoc,...
    strcat(string(excelFileName),"-rows",num2str(min(rows)),...
    "~",num2str(max(rows)),"-roiLagHbTG6-",freqStr,".mat"));
save(gsLagFile,'roi','lagTimeHbT','lagAmpHbT','lagTimeG6','lagAmpG6','mask','tZone','corrThr','edgeLen');

% gs lag plot
lagFig = figure('Position',[100 100 1000 500]);
p = panel();
p.pack();
p(1).pack(2,3);
p(1,1,1).select(); imagesc(nanmean(roi,3),'AlphaData',nanmean(mask,3)); axis(gca,'square');
xlim([1 size(data,1)]); ylim([1 size(data,2)]);
set(gca,'ydir','reverse'); colorbar;
set(gca,'XTick',[]); set(gca,'YTick',[]); title('ROI');
p(1,2,1).select(); imagesc(nanmean(roi,3),'AlphaData',nanmean(mask,3)); axis(gca,'square');
xlim([1 size(data,1)]); ylim([1 size(data,2)]);
set(gca,'ydir','reverse'); colorbar;
set(gca,'XTick',[]); set(gca,'YTick',[]); title('ROI');
p(1,1,2).select(); imagesc(nanmean(lagTimeHbT,3),'AlphaData',nanmean(mask,3),[-tLim tLim]); axis(gca,'square');
xlim([1 size(data,1)]); ylim([1 size(data,2)]); colormap('jet');
set(gca,'ydir','reverse'); colorbar;
set(gca,'XTick',[]); set(gca,'YTick',[]); title('HbT Lag Time (s)');
p(1,1,3).select(); imagesc(nanmean(lagAmpHbT,3),'AlphaData',nanmean(mask,3),[0.3 1]); axis(gca,'square');
xlim([1 size(data,1)]); ylim([1 size(data,2)]); colormap('jet');
set(gca,'ydir','reverse'); colorbar;
set(gca,'XTick',[]); set(gca,'YTick',[]); title('HbT Lag Amp');
p(1,2,2).select(); imagesc(nanmean(lagTimeG6,3),'AlphaData',nanmean(mask,3),[-tLim/2 tLim/2]); axis(gca,'square');
xlim([1 size(data,1)]); ylim([1 size(data,2)]); colormap('jet');
set(gca,'ydir','reverse'); colorbar;
set(gca,'XTick',[]); set(gca,'YTick',[]); title('G6 Lag Time (s)');
p(1,2,3).select(); imagesc(nanmean(lagAmpG6,3),'AlphaData',nanmean(mask,3),[0.3 1]); axis(gca,'square');
xlim([1 size(data,1)]); ylim([1 size(data,2)]); colormap('jet');
set(gca,'ydir','reverse'); colorbar;
set(gca,'XTick',[]); set(gca,'YTick',[]); title('G6 Lag Amp');

% save lag figure
lagFigFile = fullfile(saveFileLoc,...
    strcat(string(excelFileName),"-rows",num2str(min(rows)),...
    "~",num2str(max(rows)),"-roiLagHbTG6-",freqStr,".fig"));
savefig(lagFig,lagFigFile);
close(lagFig);

end

