function analyzeGlobalLag(excelFile,rows,varargin)
%analyzeLag Analyze lag with global signal and save the results
%   Inputs:
%       parameters = filtering and other analysis parameters
%           .lowpass = low pass filter thr (if empty, no low pass)
%           .highpass = high pass filter thr (if empty, no high pass)
% assumes that the frame rate for the trials is the same

if numel(varargin) > 0
    parameters = varargin{1};
else
    parameters.lowpass = 0.08; %1/30 Hz
    parameters.highpass = 0.01;
end

freqStr = [num2str(parameters.highpass),'-',num2str(parameters.lowpass)];
freqStr(strfind(freqStr,'.')) = 'p';
freqStr = string(freqStr);

if contains(excelFile,'stim')
    tLimHb = 2;
    tLimFluor = 1;
    aLimHb = [0.3 1.5];
    aLimFluor = [0.3 2.5];
else
    tLimHb = 1;
    tLimFluor = 0.5;
    aLimHb = [0.3 1.5];
    aLimFluor = [0.3 2.5];
end

edgeLen = 3;
tZone = 2;
corrThr = 0.3;
fs = 16.8;
ySize = 128; xSize = 128;

validRange = round(tZone*fs);

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
    "~",num2str(max(rows)),"-gsLagHbTG6-",freqStr,".mat"));

covResultHb = nan(ySize,xSize,2*validRange+1);
covResultFluor = covResultHb;
lagTimeHb = [];
lagAmpHb = [];
lagTimeFluor = [];
lagAmpFluor = [];
mask = [];

if exist(lagFile)
    load(lagFile);
else
    for trialInd = 1:trialNum
        disp(['Trial # ' num2str(trialInd)]);
        
        globalLagTrialFile = fullfile(saveFileLocs(trialInd),...
            strcat(saveFileDataNames(trialInd),"-gsLagHbTG6-",freqStr,".mat"));
        
        if exist(globalLagTrialFile)
            disp('using premade file');
            load(globalLagTrialFile);
        else
            % get brain mask data
            maskTrial = load(maskFiles(trialInd));
            maskTrial = maskTrial.xform_isbrain;
            
            % get data to analyze
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
            data1 = squeeze(sum(xform_datahb,3));
            data2 = squeeze(xform_datafluorCorr);
            
            % filtering
            if ~isempty(parameters.highpass)
                data1 = highpass(data1,parameters.highpass,fs);
                data2 = highpass(data2,parameters.highpass,fs);
            end
            if ~isempty(parameters.lowpass)
                data1 = lowpass(data1,parameters.lowpass,fs);
                data2 = lowpass(data2,parameters.lowpass,fs);
            end
            
            [lagTimeHbTrial,lagAmpHbTrial,covResultHbTrial] = ...
                mouse.conn.gsLag(data1,maskTrial,edgeLen,validRange,corrThr);
            [lagTimeFluorTrial,lagAmpFluorTrial,covResultFluorTrial] = ...
                mouse.conn.gsLag(data2,maskTrial,edgeLen,validRange,corrThr);
            
            % change unit of lag time to seconds
            lagTimeHbTrial = lagTimeHbTrial./fs;
            lagTimeFluorTrial = lagTimeFluorTrial./fs;
            
            % z score corr
            lagAmpHbTrial = atanh(lagAmpHbTrial); lagAmpHbTrial = real(lagAmpHbTrial);
            lagAmpFluorTrial = atanh(lagAmpFluorTrial); lagAmpFluorTrial = real(lagAmpFluorTrial);
            covResultHbTrial = atanh(covResultHbTrial); covResultHbTrial = real(covResultHbTrial);
            covResultFluorTrial = atanh(covResultFluorTrial); covResultFluorTrial = real(covResultFluorTrial);
            
            % time points to save
            time = -validRange:validRange;
            time = time./fs;
            
            % save lag data
            save(globalLagTrialFile,'time','maskTrial','lagTimeHbTrial',...
                'lagAmpHbTrial','lagTimeFluorTrial','lagAmpFluorTrial',...
                'covResultHbTrial','covResultFluorTrial','-v7.3');
        end
        
        % make plots
        trialFigFile1 = fullfile(saveFileLocs(trialInd),...
            strcat(saveFileDataNames(trialInd),"-gsLagHbT-",freqStr,".fig"));
        trialFig = figure('Position',[100 100 900 400]);
        p = panel();
        p.pack();
        p(1).pack(1,2);
        p(1,1,1).select(); imagesc(lagTimeHbTrial,'AlphaData',maskTrial,[-tLimHb tLimHb]); axis(gca,'square');
        xlim([1 xSize]); ylim([1 ySize]);
        set(gca,'ydir','reverse'); colorbar; colormap('jet');
        set(gca,'XTick',[]); set(gca,'YTick',[]); title('Lag Time (s)');
        p(1,1,2).select(); imagesc(lagAmpHbTrial,'AlphaData',maskTrial,aLimHb); axis(gca,'square');
        xlim([1 xSize]); ylim([1 ySize]);
        set(gca,'ydir','reverse'); colorbar; colormap('jet');
        set(gca,'XTick',[]); set(gca,'YTick',[]); title('Lag Amp');
        savefig(trialFig,trialFigFile1);
        close(trialFig);
        
        trialFigFile2 = fullfile(saveFileLocs(trialInd),...
            strcat(saveFileDataNames(trialInd),"-gsLagG6-",freqStr,".fig"));
        trialFig = figure('Position',[100 100 900 400]);
        p = panel();
        p.pack();
        p(1).pack(1,2);
        p(1,1,1).select(); imagesc(lagTimeFluorTrial,'AlphaData',maskTrial,[-tLimFluor tLimFluor]); axis(gca,'square');
        xlim([1 xSize]); ylim([1 ySize]);
        set(gca,'ydir','reverse'); colorbar; colormap('jet');
        set(gca,'XTick',[]); set(gca,'YTick',[]); title('Lag Time (s)');
        p(1,1,2).select(); imagesc(lagAmpFluorTrial,'AlphaData',maskTrial,aLimFluor); axis(gca,'square');
        xlim([1 xSize]); ylim([1 ySize]);
        set(gca,'ydir','reverse'); colorbar; colormap('jet');
        set(gca,'XTick',[]); set(gca,'YTick',[]); title('Lag Amp');
        savefig(trialFig,trialFigFile2);
        close(trialFig);
        
        % concatenate over trials
        covResultHbTrial(isnan(covResultHbTrial)) = 0;
        covResultFluorTrial(isnan(covResultFluorTrial)) = 0;
        
        covResultHb = covResultHb + covResultHbTrial;
        covResultFluor = covResultFluor + covResultFluorTrial;
        lagTimeHb = cat(3,lagTimeHb,lagTimeHbTrial);
        lagAmpHb = cat(3,lagAmpHb,lagAmpHbTrial);
        lagTimeFluor = cat(3,lagTimeFluor,lagTimeFluorTrial);
        lagAmpFluor = cat(3,lagAmpFluor,lagAmpFluorTrial);
        mask = cat(3,mask,maskTrial);
    end
    
    covResultHb = covResultHb./sum(mask,3);
    covResultFluor = covResultFluor./sum(mask,3);
    
    % save lag data
    save(lagFile,'time','mask','lagTimeHb','lagAmpHb','lagTimeFluor',...
        'lagAmpFluor','covResultHb','covResultFluor','-v7.3');
    
end

% make plots
saveFileLoc = fileparts(saveFileLocs(1));
[~,excelFileName,~] = fileparts(excelFile);

load('L:\ProcessedData\noVasculatureMask.mat');
wlData = load('L:\ProcessedData\wl.mat');
load('D:\ProcessedData\zachInfarctROI.mat');

alphaData = nanmean(mask,3);
alphaData = alphaData >= 0.5;
alphaData = alphaData & (leftMask | rightMask);

trialFigFile1 = fullfile(saveFileLoc,...
    strcat(string(excelFileName),"-rows",num2str(min(rows)),...
    "~",num2str(max(rows)),"-gsLagHbT-",freqStr,".fig"));
trialFig = figure('Position',[100 100 400 900]);
subplot('Position',[0.05 0.52 0.9 0.4]);
image(wlData.xform_wl,'AlphaData',wlData.xform_isbrain);
hold on;
set(gca,'Color','k');
set(gca,'FontSize',16);
% goodPix = nanmean(lagAmpHb,3) >= 0.5943;
goodPix = sum(lagAmpHb > 0.5943,3)./sum(mask,3) > 0.5;
imagesc(nanmean(lagTimeHb,3),'AlphaData',alphaData & goodPix,[-tLimHb tLimHb]); axis(gca,'square');
xlim([1 size(lagTimeHb,1)]); ylim([1 size(lagTimeHb,2)]);
set(gca,'ydir','reverse'); colorbar; colormap('jet');
set(gca,'XTick',[]); set(gca,'YTick',[]); title('Lag Time (s)');
subplot('Position',[0.05 0.1 0.9 0.4]);
image(wlData.xform_wl,'AlphaData',wlData.xform_isbrain);
hold on;
set(gca,'Color','k');
set(gca,'FontSize',16);
imagesc(nanmean(lagAmpHb,3),'AlphaData',alphaData,aLimHb); axis(gca,'square');
xlim([1 size(lagTimeHb,1)]); ylim([1 size(lagTimeHb,2)]);
set(gca,'ydir','reverse'); colorbar; colormap('jet');
set(gca,'XTick',[]); set(gca,'YTick',[]); title('Lag Amp');
savefig(trialFig,trialFigFile1);
close(trialFig);

trialFigFile2 = fullfile(saveFileLoc,...
    strcat(string(excelFileName),"-rows",num2str(min(rows)),...
    "~",num2str(max(rows)),"-gsLagG6-",freqStr,".fig"));
trialFig = figure('Position',[100 100 400 900]);
subplot('Position',[0.05 0.52 0.9 0.4]);
image(wlData.xform_wl,'AlphaData',wlData.xform_isbrain);
hold on;
set(gca,'Color','k');
set(gca,'FontSize',16);
% goodPix = nanmean(lagAmpFluor,3) >= 0.5943;
goodPix = sum(lagAmpFluor > 0.5943,3)./sum(mask,3) > 0.5;
imagesc(nanmean(lagTimeFluor,3),'AlphaData',alphaData & goodPix,[-tLimFluor tLimFluor]); axis(gca,'square');
xlim([1 size(lagTimeFluor,1)]); ylim([1 size(lagTimeFluor,2)]);
set(gca,'ydir','reverse'); colorbar; colormap('jet');
set(gca,'XTick',[]); set(gca,'YTick',[]); title('Lag Time (s)');
subplot('Position',[0.05 0.1 0.9 0.4]);
image(wlData.xform_wl,'AlphaData',wlData.xform_isbrain);
hold on;
set(gca,'Color','k');
set(gca,'FontSize',16);
imagesc(nanmean(lagAmpFluor,3),'AlphaData',alphaData,aLimFluor); axis(gca,'square');
xlim([1 size(lagTimeFluor,1)]); ylim([1 size(lagTimeFluor,2)]);
set(gca,'ydir','reverse'); colorbar; colormap('jet');
set(gca,'XTick',[]); set(gca,'YTick',[]); title('Lag Amp');
savefig(trialFig,trialFigFile2);
close(trialFig);


end

