function fitLagParameters(excelFile,rowsToRead,rowsToFit,varargin)
%fitLagParameters Fits dot lag parameter (lag time) to other data and save the results
%   Inputs:
%       excelFile
%       rowsToRead = rows that will be used to get parameters to fit for
%       later time points.
%       rowsToFit = rows that will be fitted
%       parameters (optional) = filtering and other analysis parameters
%           .lowpass = low pass filter thr (if empty, no low pass)
%           .highpass = high pass filter thr (if empty, no high pass)

if numel(varargin) > 0
    parameters = varargin{1};
else
    parameters.lowpass = 0.08; %1/30 Hz
    parameters.highpass = 0.01;
    parameters.startTime = 0;
end

if parameters.startTime == 0
    freqStr = [num2str(parameters.highpass),'-',num2str(parameters.lowpass)];
else
    freqStr = [num2str(parameters.highpass),'-',num2str(parameters.lowpass),'-startT-',num2str(parameters.startTime)];
end
freqStr(strfind(freqStr,'.')) = 'p';
freqStr = string(freqStr);

if contains(excelFile,'stim')
    tLim = 1.5;
else
    tLim = 1;
end

edgeLen = 3;
tZone = 2;
corrThr = 0.3;

%% import packages

import mouse.*

%% read the excel file to get the list of file names

trialInfo = expSpecific.extractExcel(excelFile,rowsToFit);

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

% file containing parameters that will be fitted
lagFile = fullfile(saveFileLoc,...
    strcat(string(excelFileName),"-rows",num2str(min(rowsToRead)),...
    "~",num2str(max(rowsToRead)),"-dotLagHbTG6-",freqStr,".mat"));

% file that fit result will be saved to.
fitFile = fullfile(saveFileLoc,...
    strcat(string(excelFileName),"-rows",num2str(min(rowsToFit)),...
    "~",num2str(max(rowsToFit)),"-dotLagFitHbTG6-",freqStr,".mat"));

% load parameter
load(lagFile);
lagTime(lagAmp < 0.3) = nan;
lagTime = nanmean(lagTime,3);
fluordata = load(fluorFiles(1)); fs = fluordata.readerInfo.FreqOut;
lagSamples = lagTime.*fs;
lagSamples = round(lagSamples);

% get maxLag parameter
maxLag = round(tZone*fs);

lagAmp = [];
mask = [];

if exist(fitFile)
    load(fitFile);
else
    for trialInd = 1:trialNum
        disp(['Trial # ' num2str(trialInd)]);
        
        dotLagFile = fullfile(saveFileLocs(trialInd),...
            strcat(saveFileDataNames(trialInd),"-dotLagFitHbTG6-",freqStr,".mat"));
        
        maskTrial = load(maskFiles(trialInd));
        maskTrial = maskTrial.xform_isbrain;
        
        if exist(dotLagFile)
            load(dotLagFile);
        else
            
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
            end
            if ~isempty(parameters.lowpass)
                xform_datahb = lowpass(xform_datahb,parameters.lowpass,fs);
            end
            
            if ~isempty(parameters.highpass)
                xform_datafluorCorr = highpass(xform_datafluorCorr,parameters.highpass,fs);
            end
            if ~isempty(parameters.lowpass)
                xform_datafluorCorr = lowpass(xform_datafluorCorr,parameters.lowpass,fs);
            end
            
            data1 = squeeze(sum(xform_datahb,3));
            data1 = data1(:,:,time >= parameters.startTime);
            data2 = squeeze(xform_datafluorCorr);
            data2 = data2(:,:,time >= parameters.startTime);
            [~,lagAmpTrial,covResult] = mouse.conn.dotLag(data1,data2,edgeLen,maxLag,corrThr);
            
            for y = 1:128
                for x = 1:128
                    ind = mouse.math.matCoor2Ind([y,x],[128 128]);
                    if isnan(lagSamples(y,x))
                        lagAmpTrial(y,x) = nan;
                    else
                        lagAmpTrial(y,x) = covResult(ind,maxLag + 1 + lagSamples(y,x));
                    end
                end
            end
            
            % z score correlation
            lagAmpTrial = atanh(lagAmpTrial); lagAmpTrial = real(lagAmpTrial);
            
            % save lag data
            save(dotLagFile,'lagAmpTrial','tZone','corrThr','edgeLen');
        end
        
        % plot lag
        dotLagFig = figure('Position',[100 100 4500 400]);
        imagesc(lagAmpTrial,'AlphaData',maskTrial,[0.3 2]); axis(gca,'square');
        xlim([1 size(lagAmpTrial,1)]); ylim([1 size(lagAmpTrial,2)]);
        set(gca,'ydir','reverse'); colorbar; colormap('jet');
        set(gca,'XTick',[]); set(gca,'YTick',[]); title('Lag Amp');
        
        % save lag figure
        dotLagFigFile = fullfile(saveFileLocs(trialInd),...
            strcat(saveFileDataNames(trialInd),"-dotLagFitHbTG6-",freqStr,".fig"));
        savefig(dotLagFig,dotLagFigFile);
        close(dotLagFig);
        
        lagAmp = cat(3,lagAmp,lagAmpTrial);
        mask = cat(3,mask,maskTrial);
    end
    % save lag data
    save(fitFile,'lagAmp','mask','tZone','corrThr','edgeLen');
end

%% plot average across trials

load('L:\ProcessedData\noVasculatureMask.mat');
wlData = load('L:\ProcessedData\wl.mat');
load('D:\ProcessedData\zachInfarctROI.mat');

saveFileLoc = fileparts(saveFileLocs(1));
[~,excelFileName,~] = fileparts(excelFile);
alphaData = nanmean(mask,3);
alphaData = alphaData >= 0.5;

alphaData = alphaData & (leftMask | rightMask);

% roi time course
dotLagFig = figure('Position',[100 100 400 325]);
image(wlData.xform_wl,'AlphaData',wlData.xform_isbrain);
set(gca,'Color','k');
set(gca,'FontSize',16);
hold on;
imagesc(nanmean(lagAmp,3),'AlphaData',alphaData,[0.3 2]); axis(gca,'square');
xlim([1 size(lagAmp,1)]); ylim([1 size(lagAmp,2)]);
set(gca,'ydir','reverse'); colorbar; colormap('jet');
set(gca,'XTick',[]); set(gca,'YTick',[]);
P = mask2poly(infarctroi);
plot(P.X,P.Y,'k','LineWidth',3);
hold off;

% save lag figure
dotLagFigFile = fullfile(saveFileLoc,...
    strcat(string(excelFileName),"-rows",num2str(min(rowsToFit)),...
    "~",num2str(max(rowsToFit)),"-dotLagFitHbTG6-",freqStr,".fig"));
savefig(dotLagFig,dotLagFigFile);
close(dotLagFig);

end

