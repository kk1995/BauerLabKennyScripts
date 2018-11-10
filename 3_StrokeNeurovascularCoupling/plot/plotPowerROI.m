dataDir = 'D:\data\zachRosenthal\';
contourFile = 'D:\data\zachRosenthal\contour.mat';
bloodMaskFile = 'D:\data\zachRosenthal\bloodMask.mat';
wlFile = 'D:\data\170126\170126-2528_baseline-LandmarksandMask.mat';
saveDir = 'D:\data\zachRosenthal\_summary';
saveFile = 'avgPower.mat';
speciesName = ["HbO","HbR","HbT","GCaMP"];

%%
load(wlFile); % xform_WL
load(contourFile); % contourMask
load(bloodMaskFile); % bloodMask
load('D:\data\atlas.mat');
mask = AtlasSeedsFilled>0;
%% get avg data
load(fullfile(saveDir,saveFile));
%% plot

speciesNum = size(infarctData{1},1);
f1 = figure('Position',[100 50 1000 900]);
p = panel();
p.pack(speciesNum, 4);
p.margin = [8 12 0 3];
p.de.margin = 12;
for week = 1:4
    for species = 1:speciesNum
        ax = p(species,week).select();
        plotData1 = log(nonInfarctData{week}(species,:,:));
        plotData1 = mean(plotData1,3);
        plotData2 = log(infarctData{week}(species,:,:));
        plotData2 = mean(plotData2,3);
        
        plot(f,plotData1,f,plotData2);
        xlim([0 5]);
        xlabel('frequency (Hz)');
        ylabel('power (log)');
        if week == 4 && species == 4
            legend('non-infarct','infarct');
        end
    end
end
% make subplots square
axesHandles = findobj(get(f1,'Children'), 'flat','Type','axes');
axis(axesHandles,'square')

%% plot with error bar

speciesNum = size(infarctData{1},1);
f1 = figure('Position',[100 50 1000 900]);
p = panel();
p.pack(speciesNum, 4);
p.margin = [8 15 0 3];
p.de.margin = 12;

lowerInd = 1:4:numel(f);
fLower = f(lowerInd);
fLower = log(fLower);

for week = 1:4
    for species = 1:speciesNum
        ax = p(species,week).select();
        tempData = squeeze(log(nonInfarctData{week}(species,:,:)));
        tempData = tempData';
        tempData = double(tempData);
        tempData = tempData(:,lowerInd);
        plotData1 = tempData;
        
        tempData = squeeze(log(infarctData{week}(species,:,:)));
        tempData = tempData';
        tempData = double(tempData);
        tempData = tempData(:,lowerInd);
        plotData2 = tempData;
        
        hold on;
        p1 = shadedErrorBar(fLower,plotData1,{@mean,@std},'lineprops','-b','patchSaturation',0.16);
        p2 = shadedErrorBar(fLower,plotData2,{@mean,@std},'lineprops','-r','patchSaturation',0.16);
        hold off;
        xlim([min(fLower),max(fLower)]);
        xlabel('frequency (Hz, log)');
        ylabel('power (log)');
        if week == 4 && species == 4
            legend([p1.mainLine p2.mainLine],'non-infarct','infarct');
        end
    end
end
% make subplots square
axesHandles = findobj(get(f1,'Children'), 'flat','Type','axes');
axis(axesHandles,'square')

%% plot with error bar baseline vs week1

speciesNum = size(infarctData{1},1);
f1 = figure('Position',[200 150 1000 600]);
p = panel();
p.pack(2, 4);
p.margin = [10 15 3 3];
p.de.margin = 12;

lowerInd = 1:4:numel(f);
fLower = f(lowerInd);

for cond = 1:2
    if cond == 1
        plotData = nonInfarctData;
    else
        plotData = infarctData;
    end
    for species = 1:speciesNum
        ax = p(cond,species).select();
        tempData = squeeze(log(plotData{1}(species,:,:)));
        tempData = tempData';
        tempData = double(tempData);
        tempData = tempData(:,lowerInd);
        plotData1 = tempData;
        
        tempData = squeeze(log(plotData{2}(species,:,:)));
        tempData = tempData';
        tempData = double(tempData);
        tempData = tempData(:,lowerInd);
        plotData2 = tempData;
        
        hold on;
        p1 = shadedErrorBar(fLower,plotData1,{@mean,@std},'lineprops','-b','patchSaturation',0.16);
        p2 = shadedErrorBar(fLower,plotData2,{@mean,@std},'lineprops','-r','patchSaturation',0.16);
        hold off;
        xlim([min(fLower),max(fLower)]);
        xlabel('frequency (Hz, log)');
        ylabel('power (log)');
        if week == 4 && species == 4
            legend([p1.mainLine p2.mainLine],'baseline','week 1');
        end
    end
end
% make subplots square
axesHandles = findobj(get(f1,'Children'), 'flat','Type','axes');
axis(axesHandles,'square')
