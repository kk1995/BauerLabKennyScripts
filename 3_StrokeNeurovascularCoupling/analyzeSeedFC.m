function analyzeSeedFC(excelFile,rows,varargin)
%analyzeSeedFC Analyze fc relative to seed and save the results
%   Inputs:
%       excelFile = directory to excel file to be read
%       rows = which rows in excel file will be read
%       seedInd (optional) = vectorized indices on image that will be used as seed.
%       parameters (optional) = filtering and other analysis parameters
%           .lowpass = low pass filter thr (if empty, no low pass)
%           .highpass = high pass filter thr (if empty, no high pass)
% assumes that the frame rate for the trials is the same

if numel(varargin) > 0
    seedInd = varargin{1};
    seedInd = sort(seedInd);
else
    load('L:\ProcessedData\gcampStimROI.mat');
    stimROIAll = logical(stimROIAll);
    seedInd = find(squeeze(stimROIAll(:,:,2,1)));
end

if numel(varargin) > 1
    parameters = varargin{2};
else
    parameters.lowpass = 0.08; %1/30 Hz
    parameters.highpass = 0.01;
end

freqStr = [num2str(parameters.highpass),'-',num2str(parameters.lowpass)];
freqStr(strfind(freqStr,'.')) = 'p';
freqStr = string(freqStr);

if contains(excelFile,'stim')
    aLimHb = [-1 1];
    aLimFluor = [-1 1];
    if parameters.highpass >= 0.5
        aLimHb = [-1 1];
    aLimFluor = [-1 1];
    end
else
    aLimHb = [-1 1];
    aLimFluor = [-1 1];
    if parameters.highpass >= 0.5
        aLimHb = [-0.5 0.5];
        aLimFluor = [-0.5 0.5];
    end
end

fs = 16.8;
ySize = 128; xSize = 128;

seedSize = numel(seedInd);
seedStart = seedInd(1);

postFix = strcat(freqStr, '-', num2str(seedStart), '-', num2str(seedSize));


roiPlot = false(128); roiPlot(seedInd) = true;

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
    "~",num2str(max(rows)),"-seedFCHbTG6-",postFix,".mat"));

fcHb = [];
fcFluor = [];
mask = [];

if exist(lagFile)
    load(lagFile);
else
    for trialInd = 1:trialNum
        disp(['Trial # ' num2str(trialInd)]);
        
        globalLagTrialFile = fullfile(saveFileLocs(trialInd),...
            strcat(saveFileDataNames(trialInd),"-seedFCHbTG6-",postFix,".mat"));
        
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
            
            % gsr
            data1 = mouse.process.gsr(data1,maskTrial);
            data2 = mouse.process.gsr(data2,maskTrial);
            
            % get functional connectivity matrix
            fcHbTrial = mouse.conn.getFC(data1);
            fcFluorTrial = mouse.conn.getFC(data2);
            
            % only consider values in seed
            fcHbTrial = fcHbTrial(seedInd,:);
            fcFluorTrial = fcFluorTrial(seedInd,:);
            
            % z score corr
            fcHbTrial = atanh(fcHbTrial); fcHbTrial = real(fcHbTrial);
            fcFluorTrial = atanh(fcFluorTrial); fcFluorTrial = real(fcFluorTrial);
            
            % remove infinite values
            fcHbTrial(isinf(fcHbTrial)) = nan;
            fcFluorTrial(isinf(fcFluorTrial)) = nan;
            
            % average over pixels
            fcHbTrial = nanmean(fcHbTrial,1);
            fcFluorTrial = nanmean(fcFluorTrial,1);
            
            % reshape
            fcHbTrial = reshape(fcHbTrial,ySize,xSize);
            fcFluorTrial = reshape(fcFluorTrial,ySize,xSize);
            
            % save lag data
            save(globalLagTrialFile,'maskTrial','fcHbTrial',...
                'fcFluorTrial','-v7.3');
        end
        
        % make plots
        trialFigTrialFile = fullfile(saveFileLocs(trialInd),...
            strcat(saveFileDataNames(trialInd),"-seedFCHbT-",postFix,".fig"));
        trialFig = figure('Position',[100 100 400 800]);
        subplot('Position',[0.05 0.52 0.9 0.4]);
        imagesc(fcHbTrial,'AlphaData',maskTrial,aLimHb); axis(gca,'square');
        xlim([1 xSize]); ylim([1 ySize]);
        set(gca,'ydir','reverse'); colorbar; colormap('jet');
        set(gca,'XTick',[]); set(gca,'YTick',[]); pause(0.1);
        hold on; mouse.plot.plotContour(gca,roiPlot,'k','-',4);
        
        subplot('Position',[0.05 0.1 0.9 0.4]);
        imagesc(fcFluorTrial,'AlphaData',maskTrial,aLimFluor); axis(gca,'square');
        xlim([1 xSize]); ylim([1 ySize]);
        set(gca,'ydir','reverse'); colorbar; colormap('jet');
        set(gca,'XTick',[]); set(gca,'YTick',[]); pause(0.1);
        hold on; mouse.plot.plotContour(gca,roiPlot,'k','-',4);
        savefig(trialFig,trialFigTrialFile);
        close(trialFig);
        
        % concatenate over trials
        fcHb = cat(3,fcHb,fcHbTrial);
        fcFluor = cat(3,fcFluor,fcFluorTrial);
        mask = cat(3,mask,maskTrial);
    end
    
    % save lag data
    save(lagFile,'mask','fcHb','fcFluor','-v7.3');
    
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

trialFigFile = fullfile(saveFileLoc,...
    strcat(string(excelFileName),"-rows",num2str(min(rows)),...
    "~",num2str(max(rows)),"-seedFC-",postFix,".fig"));
trialFig = figure('Position',[100 100 400 800]);
s = subplot('Position',[0.05 0.52 0.9 0.4]);
image(wlData.xform_wl,'AlphaData',wlData.xform_isbrain);
hold on;
set(s,'Color','k');
set(s,'FontSize',16);
imagesc(nanmean(fcHb,3),'AlphaData',alphaData,aLimHb); axis(gca,'square');
xlim([1 xSize]); ylim([1 ySize]);
set(s,'ydir','reverse'); colorbar; colormap('jet');
set(s,'XTick',[]); set(s,'YTick',[]);
pause(0.1);
hold on; mouse.plot.plotContour(s,roiPlot,'k','-',4);


subplot('Position',[0.05 0.1 0.9 0.4]);
image(wlData.xform_wl,'AlphaData',wlData.xform_isbrain);
hold on;
set(gca,'Color','k');
set(gca,'FontSize',16);
imagesc(nanmean(fcFluor,3),'AlphaData',alphaData,aLimFluor); axis(gca,'square');
xlim([1 xSize]); ylim([1 ySize]);
set(gca,'ydir','reverse'); colorbar; colormap('jet');
set(gca,'XTick',[]); set(gca,'YTick',[]);
pause(0.1);
hold on; mouse.plot.plotContour(gca,roiPlot,'k','-',4);

savefig(trialFig,trialFigFile);
close(trialFig);


end

