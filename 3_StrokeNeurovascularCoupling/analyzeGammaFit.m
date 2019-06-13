function analyzeGammaFit(excelFile,rows,varargin)
%analyzeLag Analyze lag and save the results
%   Inputs:
%       excelFile
%       rows

cLimR = [0.3 1.5];
cLimR2 = [0 0.8];
cLimA = [0 2E-4];
cLimT = [0 0.5];
cLimW = [0 1];

if numel(varargin) > 0
    parameters = varargin{1};
else
    parameters.freqBand = [0.01 4; 0.01 4]; % 1st row = fluor
end
disp(num2str(parameters.freqBand));

freqStr = [num2str(parameters.freqBand(1,1)),'-',num2str(parameters.freqBand(1,2)),...
    '-',num2str(parameters.freqBand(2,1)),'-',num2str(parameters.freqBand(2,2))];
freqStr(strfind(freqStr,'.')) = 'p';
freqStr = string(freqStr);

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
fitFile = fullfile(saveFileLoc,...
    strcat(string(excelFileName),"-rows",num2str(min(rows)),...
    "~",num2str(max(rows)),"-gammaFitG6HbT-",freqStr,".mat"));

T = [];
A = [];
W = [];
r = [];
r2 = [];
mask = [];

if exist(fitFile)
    load(fitFile);
else
    for trialInd = 1:trialNum
        disp(['Trial # ' num2str(trialInd)]);
        
        fitFileTrial = fullfile(saveFileLocs(trialInd),...
            strcat(saveFileDataNames(trialInd),"-gammaFitG6HbT-",freqStr,".mat"));
        
        if exist(fitFileTrial)
            load(fitFileTrial,'maskTrial','TTrial','WTrial','ATrial','rTrial','r2Trial');
            disp('premade file loaded');
        else
            maskTrial = load(maskFiles(trialInd));
            maskTrial = maskTrial.xform_isbrain;
            
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
            
            xform_datafluorCorr = squeeze(xform_datafluorCorr);
            xform_datahbT = squeeze(sum(xform_datahb,3));
            
            % filter
            xform_datafluorCorr = highpass(xform_datafluorCorr,parameters.freqBand(1,1),16.8);
            xform_datafluorCorr = lowpass(xform_datafluorCorr,parameters.freqBand(1,2),16.8);
            xform_datahbT = highpass(xform_datahbT,parameters.freqBand(2,1),16.8);
            xform_datahbT = lowpass(xform_datahbT,parameters.freqBand(2,2),16.8);
            
            % gsr
%             xform_datafluorCorr = mouse.process.gsr(xform_datafluorCorr,maskTrial);
%             xform_datahbT = mouse.process.gsr(xform_datahbT,maskTrial);
            
            % gamma fit
            [TTrial,WTrial,ATrial,rTrial,r2Trial,hbPred] = interSpeciesGammaFit(xform_datafluorCorr,xform_datahbT);
            
            % save psd data
            save(fitFileTrial,'parameters','maskTrial','TTrial','WTrial','ATrial','rTrial','r2Trial','hbPred','-v7.3');
        end
        
        % plot power
        fitFig = figure('Position',[100 100 1400 350]);
        p = panel();
        p.pack();
        p(1).pack(1,4);
        p(1,1,1).select(); imagesc(rTrial,'AlphaData',maskTrial,cLimR); axis(gca,'square');
        xlim([1 size(rTrial,1)]); ylim([1 size(rTrial,2)]);
        set(gca,'ydir','reverse'); colorbar; colormap('jet');
        set(gca,'XTick',[]); set(gca,'YTick',[]); title('r');
        p(1,1,2).select(); imagesc(r2Trial,'AlphaData',maskTrial,cLimR2); axis(gca,'square');
        xlim([1 size(r2Trial,1)]); ylim([1 size(r2Trial,2)]);
        set(gca,'ydir','reverse'); colorbar; colormap('jet');
        set(gca,'XTick',[]); set(gca,'YTick',[]); title('goodness of fit');
        p(1,1,3).select(); imagesc(ATrial,'AlphaData',maskTrial,cLimA); axis(gca,'square');
        xlim([1 size(ATrial,1)]); ylim([1 size(ATrial,2)]);
        set(gca,'ydir','reverse'); colorbar; colormap('jet');
        set(gca,'XTick',[]); set(gca,'YTick',[]); title('Gamma amp');
        p(1,1,4).select(); imagesc(TTrial,'AlphaData',maskTrial,cLimT); axis(gca,'square');
        xlim([1 size(TTrial,1)]); ylim([1 size(TTrial,2)]);
        set(gca,'ydir','reverse'); colorbar; colormap('jet');
        set(gca,'XTick',[]); set(gca,'YTick',[]); title('Gamma peak time (s)');
        
        % save lag figure
        fitFigFile = fullfile(saveFileLocs(trialInd),...
            strcat(saveFileDataNames(trialInd),"-gammaFitG6HbT.fig"));
        savefig(fitFig,fitFigFile);
        close(fitFig);
        
        mask = cat(3,mask,maskTrial);
        T = cat(3,T,TTrial);
        A = cat(3,A,ATrial);
        W = cat(3,W,WTrial);
        r = cat(3,r,rTrial);
        r2 = cat(3,r2,r2Trial);
    end
    
    % save lag data
    save(fitFile,'T','A','W','r','r2','mask','-v7.3');
end

%% plot average across trials

% badInd = r2 < 0;
badInd = r2 < 0.5;
% badInd = r < 0.5 | r2 < 0;
% badThr = sum(badInd,3) == sum(mask,3);
goodInd = ~badInd;
badThr = sum(goodInd,3) > 0;

% 
T(badInd) = nan;
A(badInd) = nan;
W(badInd) = nan;
r2(r2 < 0) = 0;

T = nanmean(T,3);
A = nanmean(A,3);
W = nanmean(W,3);
r = nanmean(r,3);
r2 = nanmean(r2,3);

load('L:\ProcessedData\noVasculatureMask.mat');
wlData = load('L:\ProcessedData\wl.mat');
load('D:\ProcessedData\zachInfarctROI.mat');

saveFileLoc = fileparts(saveFileLocs(1));
[~,excelFileName,~] = fileparts(excelFile);
alphaData = nanmean(mask,3);
alphaData = alphaData >= (numel(rows)-3)/numel(rows);

alphaData = alphaData & (leftMask | rightMask);
% alphaDataNoNan = alphaData;
alphaDataNoNan = alphaData & badThr;

% roi time course
fitFig = figure('Position',[100 100 1700 350]);
p = panel();
p.pack();
p(1).pack(1,5);
p(1,1,1).select(); image(wlData.xform_wl,'AlphaData',wlData.xform_isbrain); hold on;
imagesc(r,'AlphaData',alphaData,cLimR); axis(gca,'square');
xlim([1 size(r,1)]); ylim([1 size(r,2)]);
set(gca,'ydir','reverse'); colorbar; colormap('jet');
set(gca,'XTick',[]); set(gca,'YTick',[]); title('r');
P = mask2poly(infarctroi);
plot(P.X,P.Y,'k','LineWidth',3);
p(1,1,2).select(); image(wlData.xform_wl,'AlphaData',wlData.xform_isbrain); hold on;
imagesc(r2,'AlphaData',alphaData,cLimR2); axis(gca,'square');
xlim([1 size(r2,1)]); ylim([1 size(r2,2)]);
set(gca,'ydir','reverse'); colorbar; colormap('jet');
set(gca,'XTick',[]); set(gca,'YTick',[]); title('goodness of fit');
P = mask2poly(infarctroi);
plot(P.X,P.Y,'k','LineWidth',3);
p(1,1,3).select(); image(wlData.xform_wl,'AlphaData',wlData.xform_isbrain); hold on;
imagesc(A,'AlphaData',alphaDataNoNan,cLimA); axis(gca,'square');
xlim([1 size(A,1)]); ylim([1 size(A,2)]);
set(gca,'ydir','reverse'); colorbar; colormap('jet');
set(gca,'XTick',[]); set(gca,'YTick',[]); title('Gamma amp');
P = mask2poly(infarctroi);
plot(P.X,P.Y,'k','LineWidth',3);
p(1,1,4).select(); image(wlData.xform_wl,'AlphaData',wlData.xform_isbrain); hold on;
imagesc(T,'AlphaData',alphaDataNoNan,cLimT); axis(gca,'square');
xlim([1 size(T,1)]); ylim([1 size(T,2)]);
set(gca,'ydir','reverse'); colorbar; colormap('jet');
set(gca,'XTick',[]); set(gca,'YTick',[]); title('Gamma peak time (s)');
P = mask2poly(infarctroi);
plot(P.X,P.Y,'k','LineWidth',3);
p(1,1,5).select(); image(wlData.xform_wl,'AlphaData',wlData.xform_isbrain); hold on;
imagesc(W,'AlphaData',alphaDataNoNan,cLimW); axis(gca,'square');
xlim([1 size(T,1)]); ylim([1 size(T,2)]);
set(gca,'ydir','reverse'); colorbar; colormap('jet');
set(gca,'XTick',[]); set(gca,'YTick',[]); title('Gamma full width half max (s)');
P = mask2poly(infarctroi);
plot(P.X,P.Y,'k','LineWidth',3);

% save lag figure
fitFigFile = fullfile(saveFileLoc,...
    strcat(string(excelFileName),"-rows",num2str(min(rows)),...
    "~",num2str(max(rows)),"-gammaFitG6HbT-",freqStr,".fig"));
savefig(fitFig,fitFigFile);
close(fitFig);

end

