% loads lag analysis data and plots average over all mice
mainDir = 'D:\data\zachRosenthal\';
contourFile = 'D:\data\zachRosenthal\contour.mat';
wlFile = 'D:\data\170126\170126-2528_baseline-LandmarksandMask.mat';


% cLim = [-0.25 0.25];
cLim = [-0.15 0.15];

useVisualCheck = false;

load(wlFile); % xform_WL
load(contourFile);

lagMat = cell(4,4);
ampMat = cell(4,4);
mask = cell(4,4);

for weekInd = 1:4
    if weekInd == 1
        week = 'baseline';
    elseif weekInd == 2
        week = 'week1';
    elseif weekInd == 3
        week = 'week4';
    else
        week = 'week8';
    end
    subFolder = [week '_lag_bilateral_0p5to5'];
    dataDir = fullfile(mainDir,subFolder);
    D = dir(dataDir); D(1:2) = [];
    for file = 1:numel(D)
        fileData = load(fullfile(dataDir,D(file).name));
        
        % get mouse avg
        for specInd = 1:4
            lagMat{weekInd,specInd} = cat(3,lagMat{weekInd,specInd},fileData.lagMouse(:,:,specInd));
            ampMat{weekInd,specInd} = cat(3,ampMat{weekInd,specInd},fileData.ampMouse(:,:,specInd));
            mask{weekInd,specInd} = cat(3,mask{weekInd,specInd},nanmean(fileData.maskMouse,3));
        end
        
    end
end

% visually checking for control
goodMice = cell(4,4);
if useVisualCheck
    for ind = 1:numel(lagMat)
        f1 = figure('Position',[100 50 800 600]);
        for i = 1:size(lagMat{ind},3); subplot(3,5,i); imagesc(lagMat{ind}(:,:,i),cLim);
            colormap('jet'); title(num2str(i)); end
        % make subplots square
        axesHandles = findobj(get(f1,'Children'), 'flat','Type','axes');
        axis(axesHandles,'square')
        
        prompt = 'Which mice are bad runs (''separate by comma'')?';
        badMice = inputdlg(prompt);
        close(f1);
        badMice = strsplit(badMice{:},',');
        for i = 1:numel(badMice)
            if isempty(badMice{i})
                badMice{i} = [];
            else
                badMice{i} = str2double(badMice{i});
            end
        end
        badMice = cell2mat(badMice);
        
        goodMice{ind} = true(1,size(lagMat{ind},3));
        goodMice{ind}(badMice) = false;
    end
else
    for ind = 1:numel(lagMat)
        goodMice{ind} = true(1,size(lagMat{ind},3));
    end
end

lagMatMean = [];
ampMatMean = [];
for i = 1:numel(lagMat)
    lagMatMean{i} = nanmean(lagMat{i}(:,:,goodMice{i}),3);
    ampMatMean{i} = nanmean(ampMat{i}(:,:,goodMice{i}),3);
    mask{i} = nanmean(mask{i}(:,:,goodMice{i}),3);
end

%% plot

f2 = figure('Position',[100 50 1000 900]);
p = panel();
p.pack(4, 4);
p.margin = [2 2 20 0];
p.de.margin = 2;
for week = 1:4
    for species = 1:4
        i = week + (species-1)*4;
%         ax = subplot(4,4,i);
        ax = p(species, week).select();
        plotData = nan(128,128);
        plotData(:,1:64) = lagMatMean{i}(:,1:64);
        
        
        alphaData = mask{i};
        alphaData(alphaData < 1) = 0; % at least 50% of mice need to have data in that pix
        alphaData(isnan(plotData)) = 0;
        plotData(alphaData == 0) = nan;
        
        plotMouseBrain(ax,xform_WL,plotData,contourMask);
        caxis(cLim);
        set(gca,'Ydir','reverse')
        set(gca,'Visible','off');
        colormap('jet');
        if i == 16
            
            s4Pos = get(ax,'position');
            colorbar('FontSize',8);
            
            set(ax,'Position',s4Pos);
        end
    end
end
% make subplots square
axesHandles = findobj(get(f2,'Children'), 'flat','Type','axes');
axis(axesHandles,'square')
    
f3 = figure('Position',[100 50 1000 900]);
p = panel();
p.pack(4, 4);
p.margin = [2 2 20 0];
p.de.margin = 2;
for week = 1:4
    for species = 1:4
        i = week + (species-1)*4;
%         ax = subplot(4,4,i);
        ax = p(species, week).select();
        plotData = nan(128,128);
        plotData(:,1:64) = ampMatMean{i}(:,1:64);
        
        
        alphaData = mask{i};
        alphaData(alphaData < 1) = 0; % at least 50% of mice need to have data in that pix
        alphaData(isnan(plotData)) = 0;
        plotData(alphaData == 0) = nan;
        
        plotMouseBrain(ax,xform_WL,plotData,contourMask);
        caxis([0 1]);
        set(gca,'Ydir','reverse')
        set(gca,'Visible','off');
        colormap('jet');
        if i == 16
            
            s4Pos = get(ax,'position');
            colorbar('FontSize',8);
            
            set(ax,'Position',s4Pos);
        end
    end
end
% make subplots square
axesHandles = findobj(get(f3,'Children'), 'flat','Type','axes');
axis(axesHandles,'square')