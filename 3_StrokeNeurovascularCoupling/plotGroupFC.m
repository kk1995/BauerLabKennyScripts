function plotGroupFC(fRange)
% plots lag relative to region

excelFile = fullfile('D:\data','zach_gcamp_stroke_fc_trials.xlsx');
rowList{1} = 2:43;
rowList{2} = 44:83;
rowList{3} = 84:125;
rowList{4} = 126:167;

% sR = 16.8;
% saveFolder = "L:\ProcessedData\3_NeurovascularCoupling";

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
haveColorBar = false(1,4); haveColorBar(4) = true;
figure('Position',[200 100 1400 600]);

for i = 1:4
    
    sXStart = 0 + (i-1)*0.24;
    sXWidth = 0.22;
    
    % make data file list
    dataFileList = [];
    for row = rowList{i}
        [~, ~, raw]=xlsread(excelFile,1, ['A',num2str(row),':K',num2str(row)]);
        mouseName = raw{2};
        dataDir = raw{5};
        dataFile = [mouseName '-' fMinStr '-' fMaxStr '-roi-fc.mat'];
        dataFileList = [dataFileList string(fullfile(dataDir,dataFile))];
    end
    dataFileList = unique(dataFileList);
    
    % concatenate multiple mouse lag data
    rowInd = 0;
    hbFC = [];
    fluorFC = [];
    mask = [];
    for dataFile = dataFileList
        rowInd = rowInd + 1;
        disp(['File # ' num2str(rowInd) '/' num2str(numel(dataFileList))]);
        try
            mouseData = load(dataFile);
            
            hbFC = cat(5,hbFC,mouseData.hbFC);
            fluorFC = cat(5,fluorFC,mouseData.fluorFC);
            mask = cat(3,mask,mean(mouseData.mask,3) > 0);
        catch
        end
    end
    
    % plot
    roiInd = [2 1];
    
    load('L:\ProcessedData\gcampStimROI.mat'); %stimROIAll
    stimROIAll = logical(stimROIAll);
    contour = squeeze(stimROIAll(:,:,roiInd(1),roiInd(2)));
    
    % mask
    load('L:\ProcessedData\noVasculatureMask.mat');
    alpha = mean(mask,3) > 0.5 & leftMask | rightMask;
    
    % wl image
    wlData = load('L:\ProcessedData\wl.mat');
    
    plotHbTTime = nanmean(hbFC,5);
    plotFluorTime = nanmean(fluorFC,5);
    
    plotHbTTime = squeeze(plotHbTTime(:,:,roiInd(1),roiInd(2)));
    plotFluorTime = squeeze(plotFluorTime(:,:,roiInd(1),roiInd(2)));
    
    ax = subplot('Position',[sXStart 0.51 sXWidth 0.45]);
    image(wlData.xform_wl,'AlphaData',wlData.xform_isbrain); hold on;
    imagesc(plotHbTTime,'AlphaData',alpha,[-1 1]); colormap('jet');
    set(ax,'Color','k'); set(ax,'xtick',[]); set(gca,'xticklabel',[]); set(gca,'ytick',[]); set(gca,'yticklabel',[]);
    axis(gca,'square');
    if haveColorBar(i)
        origPos = get(ax,'Position');
        cbPos = origPos; cbPos(1) = origPos(1) + origPos(3) + origPos(3)*0.03; cbPos(3) = origPos(3)*0.08;
        cbPos(2) = origPos(2) + 0.1*origPos(4); cbPos(4) = origPos(4)*0.8;
        colorbar('Position',cbPos);
        set(ax,'Position',origPos);
    end
    mouse.plot.plotContour(ax,contour,'g','-',4);
    set(ax,'FontSize',14);
    
    ax = subplot('Position',[sXStart 0.04 sXWidth 0.45]);
    image(wlData.xform_wl,'AlphaData',wlData.xform_isbrain); hold on;
    imagesc(plotFluorTime,'AlphaData',alpha,[-1 1]); colormap('jet');
    set(ax,'Color','k'); set(ax,'xtick',[]); set(gca,'xticklabel',[]); set(gca,'ytick',[]); set(gca,'yticklabel',[]);
    axis(gca,'square');
    if haveColorBar(i)
        origPos = get(ax,'Position');
        cbPos = origPos; cbPos(1) = origPos(1) + origPos(3) + origPos(3)*0.03; cbPos(3) = origPos(3)*0.08;
        cbPos(2) = origPos(2) + 0.1*origPos(4); cbPos(4) = origPos(4)*0.8;
        colorbar('Position',cbPos);
        set(ax,'Position',origPos);
    end
    mouse.plot.plotContour(ax,contour,'g','-',4);
    set(ax,'FontSize',14);
end
end