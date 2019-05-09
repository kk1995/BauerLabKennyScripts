function fitGammaParameters(excelFile,rowsToRead,rowsToFit,varargin)
%fitGammaParameters Fits gamma parameters to other data and save the results
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
    parameters.freqBand = [0.01 4; 0.01 4]; % 1st row = fluor
end

freqStr = [num2str(parameters.freqBand(1,1)),'-',num2str(parameters.freqBand(1,2)),...
    '-',num2str(parameters.freqBand(2,1)),'-',num2str(parameters.freqBand(2,2))];
freqStr(strfind(freqStr,'.')) = 'p';
freqStr = string(freqStr);

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
    "~",num2str(max(rowsToRead)),"-gammaFitG6HbT-",freqStr,".mat"));

% file that fit result will be saved to.
fitFile = fullfile(saveFileLoc,...
    strcat(string(excelFileName),"-rows",num2str(min(rowsToFit)),...
    "~",num2str(max(rowsToFit)),"-gammaFit2OtherPointsG6HbT-",freqStr,".mat"));

% load parameter
load(lagFile);
T(r2 < 0.5) = nan; A(r2 < 0.5) = nan; W(r2 < 0.5) = nan;
T = nanmean(T,3); A = nanmean(A,3); W = nanmean(W,3);
fluordata = load(fluorFiles(1)); fs = fluordata.readerInfo.FreqOut;

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
            strcat(saveFileDataNames(trialInd),"-gammaFit2OtherPointsG6HbT-",freqStr,".mat"));
        
        maskTrial = load(maskFiles(trialInd));
        maskTrial = maskTrial.xform_isbrain;
        
        if exist(dotLagFile)
            load(dotLagFile,'TTrial','WTrial','ATrial','rTrial','r2Trial');
            disp('premade file loaded');
        else
            
            hbdata = load(hbFiles(trialInd));
            fluordata = load(fluorFiles(trialInd));
            try
                xform_datahb = hbdata.data_hb;
            catch
                xform_datahb = hbdata.xform_datahb;
            end
            xform_datahbT = sum(xform_datahb,3);
            try
                xform_datafluorCorr = fluordata.data_fluorCorr;
            catch
                xform_datafluorCorr = fluordata.xform_datafluorCorr;
            end
            
            fs = fluordata.readerInfo.FreqOut;
            time = fluordata.rawTime;
            
            % filtering
            xform_datafluorCorr = highpass(xform_datafluorCorr,parameters.freqBand(1,1),16.8);
            xform_datafluorCorr = lowpass(xform_datafluorCorr,parameters.freqBand(1,2),16.8);
            xform_datahbT = highpass(xform_datahbT,parameters.freqBand(2,1),16.8);
            xform_datahbT = lowpass(xform_datahbT,parameters.freqBand(2,2),16.8);
            
            data1 = squeeze(sum(xform_datahb,3));
            data2 = squeeze(xform_datafluorCorr);
            
            % find goodness of fit
            t = 0:504; t = t./16.8;
            dataLen = size(data2,3);
            rTrial = nan(128); r2Trial = rTrial;
            for y = 1:128
                for x = 1:128
                    pixHb = squeeze(data1(y,x,:));
                    pixFluor = squeeze(data2(y,x,:));
                    if sum(isnan(pixHb)) > 0
                        rTrial(y,x) = nan;
                        r2Trial(y,x) = nan;
                    else
                        try
                            impulseResp = mouse.math.hrfGamma(t,T(y,x),W(y,x),A(y,x));
                            pixHbPred = conv(pixFluor,impulseResp);
                            pixHbPred = pixHbPred(1:dataLen);
                            rTrial(y,x) = corr(pixHbPred,pixHb);
                            r2Trial(y,x) = 1 - var(pixHbPred - pixHb)/var(pixHb);
                        catch
                        end
                    end
                end
            end
            
            % z score correlation
            rTrial = atanh(rTrial); rTrial = real(rTrial);
            
            % save lag data
            save(dotLagFile,'rTrial','r2Trial','tZone','corrThr','edgeLen');
        end
        
        % plot lag
        dotLagFig = figure('Position',[100 100 700 400]);
        p = panel();
        p.pack();
        p(1).pack(1,2);
        p(1,1,1).select();
        imagesc(rTrial,'AlphaData',maskTrial,[0.3 2]); axis(gca,'square');
        xlim([1 size(rTrial,1)]); ylim([1 size(rTrial,2)]);
        set(gca,'ydir','reverse'); colorbar; colormap('jet');
        set(gca,'XTick',[]); set(gca,'YTick',[]); title('Correlation');
        p(1,1,2).select();
        imagesc(r2Trial,'AlphaData',maskTrial,[0 1]); axis(gca,'square');
        xlim([1 size(r2Trial,1)]); ylim([1 size(r2Trial,2)]);
        set(gca,'ydir','reverse'); colorbar; colormap('jet');
        set(gca,'XTick',[]); set(gca,'YTick',[]); title('Goodness of fit');
        
        % save lag figure
        dotLagFigFile = fullfile(saveFileLocs(trialInd),...
            strcat(saveFileDataNames(trialInd),"-gammaFit2OtherPointsG6HbT-",freqStr,".fig"));
        savefig(dotLagFig,dotLagFigFile);
        close(dotLagFig);
        
        r = cat(3,r,rTrial);
        r2 = cat(3,r2,r2Trial);
        mask = cat(3,mask,maskTrial);
    end
    
    % save lag data
    save(fitFile,'r','r2','mask');
end

%% plot average across trials

r2(isinf(r2)) = nan;
r2(r2 < 0) = 0;

load('L:\ProcessedData\noVasculatureMask.mat');
wlData = load('L:\ProcessedData\wl.mat');
load('D:\ProcessedData\zachInfarctROI.mat');

saveFileLoc = fileparts(saveFileLocs(1));
[~,excelFileName,~] = fileparts(excelFile);
alphaData = nanmean(mask,3);
alphaData = alphaData >= 0.5;

alphaData = alphaData & (leftMask | rightMask);

% roi time course
dotLagFig = figure('Position',[100 100 400 650]);
p = panel();
p.margintop = 10;
p.marginright = 10;
p.pack();
p(1).pack(2,1);
p(1,1,1).select();
image(wlData.xform_wl,'AlphaData',wlData.xform_isbrain);
set(gca,'Color','k');
set(gca,'FontSize',16);
hold on;
imagesc(nanmean(r,3),'AlphaData',alphaData,[0.3 1.5]); axis(gca,'square');
xlim([1 size(r,1)]); ylim([1 size(r,2)]);
set(gca,'ydir','reverse'); colorbar; colormap('jet');
set(gca,'XTick',[]); set(gca,'YTick',[]);
P = mask2poly(infarctroi);
plot(P.X,P.Y,'k','LineWidth',3);
hold off;

p(1,2,1).select();
set(gca,'Color','k');
set(gca,'FontSize',16);
image(wlData.xform_wl,'AlphaData',wlData.xform_isbrain);
hold on;
imagesc(nanmean(r2,3),'AlphaData',alphaData,[0 0.8]); axis(gca,'square');
xlim([1 size(r2,1)]); ylim([1 size(r2,2)]);
set(gca,'ydir','reverse'); colorbar; colormap('jet');
set(gca,'XTick',[]); set(gca,'YTick',[]);
P = mask2poly(infarctroi);
plot(P.X,P.Y,'k','LineWidth',3);
hold off;

% save lag figure
dotLagFigFile = fullfile(saveFileLoc,...
    strcat(string(excelFileName),"-rows",num2str(min(rowsToFit)),...
    "~",num2str(max(rowsToFit)),"-gammaFit2OtherPointsG6HbT-",freqStr,".fig"));
savefig(dotLagFig,dotLagFigFile);
close(dotLagFig);

end

