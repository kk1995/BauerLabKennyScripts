function analyzeBaselineHrfFit(excelFile,rows)
%analyzeBaselineHrfFit Analyze the fit of baseline HRF to other data
%   Inputs:
%       excelFile
%       rows

cLimR = [-1 1];
cLimR2 = [0 1];
cLimA = [0 2E-5];
cLimT = [0 1];

%% import packages

import mouse.*

%% get hrf for each mouse

baseInd = 2:43;
trialInfo = expSpecific.extractExcel(excelFile,baseInd);
saveFileLocs = trialInfo.saveFolder;
saveFileMaskNames = trialInfo.saveFilePrefixMask;
saveFileDataNames = trialInfo.saveFilePrefixData;

mouseName = saveFileMaskNames;
for i = 1:numel(mouseName)
    mouseName(i) = string(mouseName{i}(8:11));
end

trialNum = numel(baseInd);

T_base = [];
A_base = [];
W_base = [];
T_mouse = [];
A_mouse = [];
W_mouse = [];

prevMouseName = mouseName(1);
for trialInd = 1:trialNum
    fitFileTrial = fullfile(saveFileLocs(trialInd),...
        strcat(saveFileDataNames(trialInd),"-gammaFitG6HbT.mat"));
    load(fitFileTrial,'maskTrial','TTrial','WTrial','ATrial','rTrial','r2Trial');
    
    if prevMouseName ~= mouseName(trialInd)
        % get mouse avg
        T_base = cat(3,T_base,nanmean(T_mouse,3));
        A_base = cat(3,A_base,nanmean(A_mouse,3));
        W_base = cat(3,W_base,nanmean(W_mouse,3));
        
        % initialize for new mouse
        T_mouse = [];
        A_mouse = [];
        W_mouse = [];
    end
    
    T_mouse = cat(3,T_mouse,TTrial);
    A_mouse = cat(3,A_mouse,ATrial);
    W_mouse = cat(3,W_mouse,WTrial);
    prevMouseName = mouseName(trialInd);
end

T_base = cat(3,T_base,nanmean(T_mouse,3));
A_base = cat(3,A_base,nanmean(A_mouse,3));
W_base = cat(3,W_base,nanmean(W_mouse,3));

mouseName = unique(mouseName);

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
    "~",num2str(max(rows)),"-gammaFitG6HbT_baselineHRF.mat"));

r = [];
r2 = [];
mask = [];

if exist(fitFile)
    load(fitFile);
else
    for trialInd = 1:trialNum
        disp(['Trial # ' num2str(trialInd)]);
        
        fitFileTrial = fullfile(saveFileLocs(trialInd),...
            strcat(saveFileDataNames(trialInd),"-gammaFitG6HbT_baselineHRF.mat"));
        
        if exist(fitFileTrial)
            load(fitFileTrial,'maskTrial','TTrial','WTrial','ATrial');
        else
            for i = 1:numel(mouseName)
                mouseInd(i) = contains(hbFiles(trialInd),mouseName(i));
            end
            mouseInd = find(mouseInd);
            
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
            
            xform_datafluorCorr = squeeze(xform_datafluorCorr);
            xform_datahbT = squeeze(sum(xform_datahb,3));
            
            hbPred = nan(128,128,size(xform_datahbT,3));
            for xInd = 1:128
                for yInd = 1:128
                    pixelNeural = squeeze(xform_datafluorCorr(yInd,xInd,:))';
                    t = (0:504)./16.8;
                    pixelHrf = mouse.math.hrfGamma(t,T_base(yInd,xInd,mouseInd),...
                        W_base(yInd,xInd,mouseInd),A_base(yInd,xInd,mouseInd));
                    pixHemoPred = conv(pixelNeural,pixelHrf);
                    pixHemoPred = pixHemoPred(1:numel(pixelNeural));
                    hbPred(yInd,xInd,:) = pixHemoPred;
                end
            end
            
            rTrial = nan(128); r2Trial = nan(128);
            for xInd = 1:128
                for yInd = 1:128
                    rTrial(yInd,xInd) = atanh(corr(squeeze(hbPred(yInd,xInd,:)),...
                        squeeze(xform_datahbT(yInd,xInd,:))));
                    r2Trial(yInd,xInd) = 1 - var(squeeze(hbPred(yInd,xInd,:)) ...
                        - squeeze(xform_datahbT(yInd,xInd,:)))/var(squeeze(xform_datahbT(yInd,xInd,:)));
                end
            end
            rTrial = real(rTrial);
            
            % save psd data
            save(fitFileTrial,'maskTrial','rTrial','r2Trial','-v7.3');
        end
        
        % plot power
        fitFig = figure('Position',[100 100 700 350]);
        p = panel();
        p.pack();
        p(1).pack(1,2);
        p(1,1,1).select(); imagesc(rTrial,'AlphaData',maskTrial,cLimR); axis(gca,'square');
        xlim([1 size(rTrial,1)]); ylim([1 size(rTrial,2)]);
        set(gca,'ydir','reverse'); colorbar; colormap('jet');
        set(gca,'XTick',[]); set(gca,'YTick',[]); title('r');
        p(1,1,2).select(); imagesc(r2Trial,'AlphaData',maskTrial,cLimR2); axis(gca,'square');
        xlim([1 size(r2Trial,1)]); ylim([1 size(r2Trial,2)]);
        set(gca,'ydir','reverse'); colorbar; colormap('jet');
        set(gca,'XTick',[]); set(gca,'YTick',[]); title('goodness of fit');
        
        % save lag figure
        fitFigFile = fullfile(saveFileLocs(trialInd),...
            strcat(saveFileDataNames(trialInd),"-gammaFitG6HbT_baselineHRF.fig"));
        savefig(fitFig,fitFigFile);
        close(fitFig);
        
        mask = cat(3,mask,maskTrial);
        r = cat(3,r,rTrial);
        r2 = cat(3,r2,r2Trial);
    end
    
    % save lag data
    save(fitFile,'r','r2','mask','-v7.3');
end

%% plot average across trials

r2(r2 < 0) = 0;

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

% roi time course
fitFig = figure('Position',[100 100 700 350]);
p = panel();
p.pack();
p(1).pack(1,2);
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

% save lag figure
fitFigFile = fullfile(saveFileLoc,...
    strcat(string(excelFileName),"-rows",num2str(min(rows)),...
    "~",num2str(max(rows)),"-gammaFitG6HbT_baselineHRF.fig"));
savefig(fitFig,fitFigFile);
close(fitFig);

end

