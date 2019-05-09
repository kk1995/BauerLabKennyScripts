function plotGroupROILag(rowList,fRange)

% plots lag relative to region

excelFile = fullfile('D:\data','zach_gcamp_stroke_fc_trials.xlsx');
% rowList = 2:43;
% rowList = 44:83;
% rowList = 84:125;
% rowList = 126:167;

sR = 16.8;
saveFolder = "L:\ProcessedData\3_NeurovascularCoupling";

%%
fMin = fRange(1);
fMax = fRange(2);

% fMin = 0.01;
% fMax = 0.08;

fMinStr = num2str(fMin);
fMinStr(strfind(fMinStr,'.')) = 'p';
fMaxStr = num2str(fMax);
fMaxStr(strfind(fMaxStr,'.')) = 'p';

%%

% make data file list
dataFileList = [];
for row = rowList
    [~, ~, raw]=xlsread(excelFile,1, ['A',num2str(row),':K',num2str(row)]);
    mouseName = raw{2};
    dataDir = raw{5};
    dataFile = [mouseName '-' fMinStr '-' fMaxStr '-roi-lag.mat'];
    dataFileList = [dataFileList string(fullfile(dataDir,dataFile))];
end
dataFileList = unique(dataFileList);

% concatenate multiple mouse lag data
rowInd = 0;
hbTLagTime = [];
hbTLagAmp = [];
fluorLagTime = [];
fluorLagAmp = [];
mask = [];
for dataFile = dataFileList
    rowInd = rowInd + 1;
    disp(['File # ' num2str(rowInd) '/' num2str(numel(dataFileList))]);
    
    try
        mouseData = load(dataFile);
        
        hbTLagTime = cat(5,hbTLagTime,mouseData.hbTLagTime);
        hbTLagAmp = cat(5,hbTLagAmp,mouseData.hbTLagAmp);
        fluorLagTime = cat(5,fluorLagTime,mouseData.fluorLagTime);
        fluorLagAmp = cat(5,fluorLagAmp,mouseData.fluorLagAmp);
        mask = cat(3,mask,mean(mouseData.mask,3) > 0);
    catch
    end
end

%% plot
haveColorBar = false;

roiInd = [1 4];

load('L:\ProcessedData\gcampStimROI.mat'); %stimROIAll
stimROIAll = logical(stimROIAll);
contour = squeeze(stimROIAll(:,:,roiInd(1),roiInd(2)));

% mask
load('L:\ProcessedData\noVasculatureMask.mat');
alpha = mean(mask,3) > 0.5 & leftMask | rightMask;

% wl image
wlData = load('L:\ProcessedData\wl.mat');

plotHbTTime = nanmean(hbTLagTime,5);
plotFluorTime = nanmean(fluorLagTime,5);
plotHbTAmp = nanmean(hbTLagAmp,5);
plotFluorAmp = nanmean(fluorLagAmp,5);

plotHbTTime = squeeze(plotHbTTime(:,:,roiInd(1),roiInd(2)));
plotFluorTime = squeeze(plotFluorTime(:,:,roiInd(1),roiInd(2)));
plotHbTAmp = squeeze(plotHbTAmp(:,:,roiInd(1),roiInd(2)));
plotFluorAmp = squeeze(plotFluorAmp(:,:,roiInd(1),roiInd(2)));

figure('Position',[100 100 500 800]);
ax = subplot('Position',[0.05 0.51 0.72 0.45]);
image(wlData.xform_wl,'AlphaData',wlData.xform_isbrain); hold on;
imagesc(plotHbTAmp,'AlphaData',alpha & ~isnan(plotHbTAmp),[0.3 1]); colormap('jet');
set(ax,'Color','k'); set(ax,'xtick',[]); set(gca,'xticklabel',[]); set(gca,'ytick',[]); set(gca,'yticklabel',[]);
if haveColorBar
    origPos = get(ax,'Position');
    cbPos = origPos; cbPos(1) = origPos(1) + origPos(3) + 0.04; cbPos(3) = 0.86 - cbPos(1);
    cbPos(2) = origPos(2) + 0.1*origPos(4); cbPos(4) = origPos(4)*0.8;
    colorbar('Position',cbPos);
    set(ax,'Position',origPos);
end
mouse.plot.plotContour(ax,contour);
set(ax,'FontSize',14);

ax = subplot('Position',[0.05 0.04 0.72 0.45]);
image(wlData.xform_wl,'AlphaData',wlData.xform_isbrain); hold on;
imagesc(plotFluorAmp,'AlphaData',alpha & ~isnan(plotFluorAmp),[0.3 1]); colormap('jet');
set(ax,'Color','k'); set(ax,'xtick',[]); set(gca,'xticklabel',[]); set(gca,'ytick',[]); set(gca,'yticklabel',[]);
if haveColorBar
    origPos = get(ax,'Position');
    cbPos = origPos; cbPos(1) = origPos(1) + origPos(3) + 0.04; cbPos(3) = 0.86 - cbPos(1);
    cbPos(2) = origPos(2) + 0.1*origPos(4); cbPos(4) = origPos(4)*0.8;
    colorbar(ax,'Position',cbPos);
    set(ax,'Position',origPos);
end
mouse.plot.plotContour(ax,contour);
set(ax,'FontSize',14);

figure('Position',[500 100 500 800]);
ax = subplot('Position',[0.05 0.51 0.72 0.45]);
image(wlData.xform_wl,'AlphaData',wlData.xform_isbrain); hold on;
imagesc(plotHbTTime,'AlphaData',alpha & ~isnan(plotHbTTime),[-0.7 0.7]); colormap('jet');
set(ax,'Color','k'); set(ax,'xtick',[]); set(gca,'xticklabel',[]); set(gca,'ytick',[]); set(gca,'yticklabel',[]);
if haveColorBar
    origPos = get(ax,'Position');
    cbPos = origPos; cbPos(1) = origPos(1) + origPos(3) + 0.04; cbPos(3) = 0.86 - cbPos(1);
    cbPos(2) = origPos(2) + 0.1*origPos(4); cbPos(4) = origPos(4)*0.8;
    colorbar('Position',cbPos);
    set(ax,'Position',origPos);
end
mouse.plot.plotContour(ax,contour);
set(ax,'FontSize',14);

ax = subplot('Position',[0.05 0.04 0.72 0.45]);
image(wlData.xform_wl,'AlphaData',wlData.xform_isbrain); hold on;
imagesc(plotFluorTime,'AlphaData',alpha & ~isnan(plotFluorTime),[-0.5 0.5]); colormap('jet');
set(ax,'Color','k'); set(ax,'xtick',[]); set(gca,'xticklabel',[]); set(gca,'ytick',[]); set(gca,'yticklabel',[]);
if haveColorBar
    origPos = get(ax,'Position');
    cbPos = origPos; cbPos(1) = origPos(1) + origPos(3) + 0.04; cbPos(3) = 0.86 - cbPos(1);
    cbPos(2) = origPos(2) + 0.1*origPos(4); cbPos(4) = origPos(4)*0.8;
    colorbar('Position',cbPos);
    set(ax,'Position',origPos);
end
mouse.plot.plotContour(ax,contour);
set(ax,'FontSize',14);
end