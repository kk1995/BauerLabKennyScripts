% close all

% loads lag analysis data and plots average over all mice
mainDir = 'D:\data\zachRosenthal\week1_lag_bilateral_0p009to0p5';
saveFigDir = 'D:\figures\3_StrokeNeurovascularCoupling\allMice';
saveFigFile = 'week1_lag_bilateral_0p009to0p5';

useContour = true;
saveFigure = false; % whether to save figures


D = dir(mainDir); D(1:2) = [];

lagMatMean = cell(4,1);
ampMatMean = cell(4,1);
maskMean = cell(4,1);

for i = 1:numel(D)
    load(fullfile(mainDir,D(i).name));
    for species = 1:numel(lagMat)
        lagMatMean{species} = cat(3,lagMatMean{species},nanmean(lagMat{species},3));
        ampMatMean{species} = cat(3,ampMatMean{species},nanmean(ampMat{species},3));
        maskMean{species} = cat(3,maskMean{species},nanmean(mask{species},3));
    end
end

%% make contour mask of where the infarct site is

if useContour
    contourData = mean(lagMatMean{4},3);
    
    maxLag = max(contourData(:));
    thr = maxLag/2;
    
    contourMask = contourData > thr;
    
    contourBounds = [find(sum(contourMask,1) > 0,1,'first')  find(sum(contourMask,1) > 0,1,'last'); ...
        find(sum(contourMask,2) > 0,1,'first')  find(sum(contourMask,2) > 0,1,'last')];
    % [xmin, xmax; ymin ymax];
else
    contourMask = true(size(lagMatMean{1},1),size(lagMatMean{1},2));
    contourBounds = [1 size(lagMatMean{1},2); 1 size(lagMatMean{1},1)];
end

%% plot
f1 = figure('Position',[0 200 1900 600]);
for species = 1:numel(lagMat)
    
    for mouse = 1:size(lagMatMean{species},3)
        ind = mouse+(species-1)*size(lagMatMean{species},3);
        subplot(numel(lagMat),size(lagMatMean{species},3),ind);
        
        if species == 1
            cMin = -0.25; cMax = 0.25;
        elseif species == 2
            cMin = -0.25; cMax = 0.25;
        else
            cMin = -0.25; cMax = 0.25;
        end
        
        plotData = lagMatMean{species}(:,:,mouse);
        alphaData = maskMean{species}(:,:,mouse);
        alphaData(alphaData < 0.6) = 0; % at least 50% of mice need to have data in that pix
        alphaData(~contourMask) = 0;
        
        plotData = plotData(contourBounds(2,1):contourBounds(2,2),contourBounds(1,1):contourBounds(1,2));
        alphaData = alphaData(contourBounds(2,1):contourBounds(2,2),contourBounds(1,1):contourBounds(1,2));

        
        image1 = imagesc(plotData,[cMin cMax]);
        set(image1,'AlphaData',alphaData);
        set(gca,'Visible','off');
        colormap('jet');
        if mouse == size(lagMatMean{species},3)
            
            s4Pos = get(gca,'position');
            colorbar();
            
            set(gca,'Position',s4Pos);
        end
    end
end
% make subplots square
axesHandles = findobj(get(f1,'Children'), 'flat','Type','axes');
axis(axesHandles,'square')

if saveFigure
if useContour
    savefig(f1,fullfile(saveFigDir,[saveFigFile '_time_contour']));
else
    savefig(f1,fullfile(saveFigDir,[saveFigFile '_time']));
end
end

f2 = figure('Position',[0 200 1900 600]);
for species = 1:numel(lagMat)
    
    for mouse = 1:size(ampMatMean{species},3)
        ind = mouse+(species-1)*size(ampMatMean{species},3);
        subplot(numel(lagMat),size(ampMatMean{species},3),ind);
        
        if species == 1
            cMin = -1; cMax = 1;
        elseif species == 2
            cMin = -5; cMax = 5;
        else
            cMin = -2; cMax = 2;
        end
        
        plotData = ampMatMean{species}(:,:,mouse);
        alphaData = maskMean{species}(:,:,mouse);
        alphaData(alphaData < 0.6) = 0; % at least 50% of mice need to have data in that pix
        alphaData(~contourMask) = 0;
        
        plotData = plotData(contourBounds(2,1):contourBounds(2,2),contourBounds(1,1):contourBounds(1,2));
        alphaData = alphaData(contourBounds(2,1):contourBounds(2,2),contourBounds(1,1):contourBounds(1,2));

        image1 = imagesc(plotData,[0 1]);
        set(image1,'AlphaData',alphaData);
        set(gca,'Visible','off');
        colormap('jet');
        if mouse == size(ampMatMean{species},3)
            
            s4Pos = get(gca,'position');
            colorbar();
            
            set(gca,'Position',s4Pos);
        end
    end
end

% make subplots square
axesHandles = findobj(get(f2,'Children'), 'flat','Type','axes');
axis(axesHandles,'square')

if saveFigure
if useContour
    savefig(f2,fullfile(saveFigDir,[saveFigFile '_amp_contour']));
else
    savefig(f2,fullfile(saveFigDir,[saveFigFile '_amp']));
end
end
%% avg plot
f3 = figure('Position',[100 200 300 600]);
for species = 1:numel(lagMat)
    subplot(numel(lagMat),1,species);
    
    
    if species == 1
        cMin = -0.25; cMax = 0.25;
    elseif species == 2
        cMin = -0.25; cMax = 0.25;
    else
        cMin = -0.25; cMax = 0.25;
    end
    
    plotData = mean(lagMatMean{species},3);
    alphaData = mean(maskMean{species},3);
    alphaData(alphaData < 0.6) = 0; % at least 50% of mice need to have data in that pix
    alphaData(~contourMask) = 0;
    
    plotData = plotData(contourBounds(2,1):contourBounds(2,2),contourBounds(1,1):contourBounds(1,2));
    alphaData = alphaData(contourBounds(2,1):contourBounds(2,2),contourBounds(1,1):contourBounds(1,2));

    image1 = imagesc(plotData,[cMin cMax]);
    set(image1,'AlphaData',alphaData);
    set(gca,'Visible','off');
    colormap('jet');
    
    s4Pos = get(gca,'position');
    colorbar();
    
    set(gca,'Position',s4Pos);
end

% make subplots square
axesHandles = findobj(get(f3,'Children'), 'flat','Type','axes');
axis(axesHandles,'square')

f4 = figure('Position',[100 200 300 600]);
for species = 1:numel(lagMat)
    subplot(numel(lagMat),1,species);
    
    
    plotData = mean(ampMatMean{species},3);
    alphaData = mean(maskMean{species},3);
    alphaData(alphaData < 0.6) = 0; % at least 50% of mice need to have data in that pix
    alphaData(~contourMask) = 0;
    
    plotData = plotData(contourBounds(2,1):contourBounds(2,2),contourBounds(1,1):contourBounds(1,2));
    alphaData = alphaData(contourBounds(2,1):contourBounds(2,2),contourBounds(1,1):contourBounds(1,2));

    image1 = imagesc(plotData,[0 1]);
    set(image1,'AlphaData',alphaData);
    set(gca,'Visible','off');
    colormap('jet');
    
    s4Pos = get(gca,'position');
    colorbar();
    
    set(gca,'Position',s4Pos);
end

% make subplots square
axesHandles = findobj(get(f4,'Children'), 'flat','Type','axes');
axis(axesHandles,'square')