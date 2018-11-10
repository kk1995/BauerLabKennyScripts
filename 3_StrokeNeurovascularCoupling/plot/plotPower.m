dataDir = 'D:\data\zachRosenthal\';
contourFile = 'D:\data\zachRosenthal\contour.mat';
wlFile = 'D:\data\170126\170126-2528_baseline-LandmarksandMask.mat';

sR = 16.81;
speciesName = ["HbO","HbR","HbT","GCaMP"];
corrThr = 0.3;

%%
load(wlFile); % xform_WL
load(contourFile);
load('D:\data\atlas.mat');
mask = AtlasSeedsFilled>0;
%% get avg data

avgData = cell(4,1);
for species = 1:4
    avgDataWeek = [];
    if species == 1
        week = 'baseline';
    elseif species == 2
        week = 'week1';
    elseif species == 3
        week = 'week4';
    else
        week = 'week8';
    end
    weekDir = [dataDir week '_power'];
    mouseFileList = dir(weekDir); mouseFileList(1:2) = [];

    for mouse = 1:numel(mouseFileList)
        mouseFileDir = fullfile(weekDir,mouseFileList(mouse).name);
        load(mouseFileDir); % metaData, dataFreq
        avgDataWeek = cat(5,avgDataWeek,dataFreq);
    end
    
    avgDataWeek = nanmean(avgDataWeek,5);
    avgData{species} = avgDataWeek;
end

%% plot

% low freq
freqInd = 2;

% clim
if freqInd == 1
    cLim = [1e-3 4e-3; 1e-3 3.5e-3; 2e-4 1.2e-3; 0.003 0.015];
else
    cLim = [1e-3 3.5e-3; 1e-3 3e-3; 2e-4 8e-4; 0.003 0.012];
end
speciesNum = size(avgData{1},3);
f1 = figure('Position',[100 50 1000 900]);
p = panel();
p.pack(4, 4);
p.margin = [2 2 20 0];
p.de.margin = 2;
for week = 1:4
    for species = 1:4
        %         ax = subplot(4,4,i);
        ax = p(species,week).select();
        plotData = squeeze(avgData{week}(:,:,species,freqInd));
        
        
        alphaData = mask;
        alphaData(alphaData < 1) = 0; % at least 50% of mice need to have data in that pix
        alphaData(isnan(plotData)) = 0;
        plotData(alphaData == 0) = nan;
        
        plotMouseBrain(ax,xform_WL,plotData,contourMask);
        caxis(cLim(species,:));
        set(gca,'Ydir','reverse')
        set(gca,'Visible','off');
        colormap('jet');
        if week == 4
            s4Pos = get(ax,'position');
            cb = colorbar('FontSize',8);
            set(ax,'Position',s4Pos);
            cPos = [s4Pos(1)+s4Pos(3) s4Pos(2)+0.03];
            cPos(1) = cPos(1) - 0.015;
            cPos = [cPos 0.015 s4Pos(4)-0.06];
            set(cb,'position',cPos);
        end
    end
end
% make subplots square
axesHandles = findobj(get(f1,'Children'), 'flat','Type','axes');
axis(axesHandles,'square')

%% plot difference

% clim
if freqInd == 1
    cLim = [-1e-3 1e-3; -1e-3 1e-3; -3e-4 3e-4; -0.02 0.02];
else
    cLim = [-1e-3 1e-3; -1e-3 1e-3; -2e-4 2e-4; -0.02 0.02];
end

f2 = figure('Position',[100 50 800 900]);
p = panel();
p.pack(4, 3);
p.margin = [2 2 20 0];
p.de.margin = 2;
for week = 2:4
    for species = 1:4
        %         ax = subplot(4,4,i);
        ax = p(species,week-1).select();
        plotData = squeeze(avgData{week}(:,:,species,freqInd)-avgData{1}(:,:,species,freqInd));
        
        
        alphaData = mask;
        alphaData(alphaData < 1) = 0; % at least 50% of mice need to have data in that pix
        alphaData(isnan(plotData)) = 0;
        plotData(alphaData == 0) = nan;
        
        plotMouseBrain(ax,xform_WL,plotData,contourMask);
%         caxis(cLim(species,:));
        set(gca,'Ydir','reverse')
        set(gca,'Visible','off');
        colormap('jet');
        if week == 4
            s4Pos = get(ax,'position');
            cb = colorbar('FontSize',8);
            set(ax,'Position',s4Pos);
            cPos = [s4Pos(1)+s4Pos(3) s4Pos(2)+0.03];
            cPos(1) = cPos(1) - 0.015;
            cPos = [cPos 0.015 s4Pos(4)-0.06];
            set(cb,'position',cPos);
        end
    end
end
% make subplots square
axesHandles = findobj(get(f2,'Children'), 'flat','Type','axes');
axis(axesHandles,'square')