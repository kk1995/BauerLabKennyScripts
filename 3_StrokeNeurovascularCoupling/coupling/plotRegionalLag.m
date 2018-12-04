dsRatio = 4;

%% find roi
load('D:\data\atlas.mat','AtlasSeedsFilled');
roiLocs = AtlasSeedsFilled;
mask = roiLocs > 0;
roiLocs(:,65:128) = roiLocs(:,65:128)+20;
roiLocs(~mask) = 0;

roiLocs = mouse.math.dsSpace(roiLocs,dsRatio,false);

roiIndices = unique(roiLocs)'; roiIndices(roiIndices==0) = []; % find the roi available

seedCenters = mouse.expSpecific.findSeedCenters(roiLocs);

mask = mouse.math.dsSpace(mask,4,false);

pixNum = numel(mask);

%% get roi projection lag for each file
xlsFile = 'D:\data\Stroke Study 1 sorted.xlsx';
dataDir = 'D:\data\zachRosenthal\baseline_projLag';

lagAmpOxy = nan(pixNum,pixNum,14);
lagTimeOxy = lagAmpOxy;
lagAmpG6 = lagAmpOxy;
lagTimeG6 = lagAmpOxy;
lagAmpOxyG6 = lagAmpOxy;
lagTimeOxyG6 = lagAmpOxy;

for row = 1:14
    disp(['row # ' num2str(row)]);
    [~, ~, rowData]=xlsread(xlsFile,1, ['A',num2str(row),':F',num2str(row)]);
    mouseName = rowData{2};
    lagAmpOxyMouse = nan(pixNum,pixNum,3);
    lagTimeOxyMouse = lagAmpOxyMouse;
    lagAmpG6Mouse = lagAmpOxyMouse;
    lagTimeG6Mouse = lagAmpOxyMouse;
    lagAmpOxyG6Mouse = lagAmpOxyMouse;
    lagTimeOxyG6Mouse = lagAmpOxyMouse;
    
    for run = 1:3
        dataFile = fullfile(dataDir,[mouseName '-run' num2str(run) '-projLagOxyG6-ds4.mat']);
        runData = load(dataFile);
        lagAmpOxyMouse(:,:,run) = runData.lagAmpOxy;
        lagTimeOxyMouse(:,:,run) = runData.lagTimeOxy;
        lagAmpG6Mouse(:,:,run) = runData.lagAmpG6;
        lagTimeG6Mouse(:,:,run) = runData.lagTimeG6;
        lagAmpOxyG6Mouse(:,:,run) = runData.lagAmpOxyG6;
        lagTimeOxyG6Mouse(:,:,run) = runData.lagTimeOxyG6;
    end
    
    lagAmpOxy(:,:,row) = nanmean(lagAmpOxyMouse,3);
    lagTimeOxy(:,:,row) = nanmean(lagTimeOxyMouse,3);
    lagAmpG6(:,:,row) = nanmean(lagAmpG6Mouse,3);
    lagTimeG6(:,:,row) = nanmean(lagTimeG6Mouse,3);
    lagAmpOxyG6(:,:,row) = nanmean(lagAmpOxyG6Mouse,3);
    lagTimeOxyG6(:,:,row) = nanmean(lagTimeOxyG6Mouse,3);
end

lagAmpOxy = nanmean(lagAmpOxy,3);
lagTimeOxy = nanmean(lagTimeOxy,3);
lagAmpG6 = nanmean(lagAmpG6,3);
lagTimeG6 = nanmean(lagTimeG6,3);
lagAmpOxyG6 = nanmean(lagAmpOxyG6,3);
lagTimeOxyG6 = nanmean(lagTimeOxyG6,3);

%% plot projection lag amp
cMap = jet(100);
cMap2 = gray(100);

f1 = figure('Position',[100 100 1000 400]);
p = panel(f1);
panelRowSize = repmat(1/4,1,4);
panelColSize = repmat(1/11,1,11);
p.pack(panelRowSize,panelColSize);
p.margin = [2 2 2 2];
for roiIndex = roiIndices
    row = ceil(roiIndex/10); col = mod(roiIndex-1,10)+1;
    ax = p(row,col).select();
    set(ax,'Visible','off');
    
    roiLoc = roiLocs == roiIndex;
    seedCenter = seedCenters(roiIndex==roiIndices,:);
    roiData = reshape(nanmean(lagAmpOxyG6(roiLoc,:),1),size(roiLocs));
    
    if roiIndex == max(roiIndices)
        addCBar = true;
    else
        addCBar = false;
    end
    ax = mouse.plot.plotBrain(ax,roiData,mask,[0 1],cMap,addCBar);
    ax = mouse.plot.plotNodes(ax,seedCenter,1,[0 1],cMap2,32);
    hold on; title(num2str(roiIndex));
    set(gca,'xtick',[]); set(gca,'ytick',[]);
end
%% lag oxy

f2 = figure('Position',[100 100 1000 400]);
p = panel(f2);
panelRowSize = repmat(1/4,1,4);
panelColSize = repmat(1/11,1,11);
p.pack(panelRowSize,panelColSize);
p.margin = [2 2 2 2];
for roiIndex = roiIndices
    row = ceil(roiIndex/10); col = mod(roiIndex-1,10)+1;
    ax = p(row,col).select();
    set(ax,'Visible','off');
    
    roiLoc = roiLocs == roiIndex;
    seedCenter = seedCenters(roiIndex==roiIndices,:);
    roiData = reshape(nanmean(lagTimeOxy(:,roiLoc),2),size(roiLocs));
    
    if roiIndex == max(roiIndices)
        addCBar = true;
    else
        addCBar = false;
    end
    ax = mouse.plot.plotBrain(ax,roiData,mask,[-0.5 0.5],cMap,addCBar,-0.002);
    ax = mouse.plot.plotNodes(ax,seedCenter,1,[0 1],cMap2,32);
    hold on; title(num2str(roiIndex));
    set(gca,'xtick',[]); set(gca,'ytick',[]);
end

%% lag gcamp

f3 = figure('Position',[100 100 1000 400]);
p = panel(f3);
panelRowSize = repmat(1/4,1,4);
panelColSize = repmat(1/11,1,11);
p.pack(panelRowSize,panelColSize);
p.margin = [2 2 2 2];
for roiIndex = roiIndices
    row = ceil(roiIndex/10); col = mod(roiIndex-1,10)+1;
    ax = p(row,col).select();
    set(ax,'Visible','off');
    
    roiLoc = roiLocs == roiIndex;
    seedCenter = seedCenters(roiIndex==roiIndices,:);
    roiData = reshape(nanmean(lagTimeG6(:,roiLoc),2),size(roiLocs));
    
    if roiIndex == max(roiIndices)
        addCBar = true;
    else
        addCBar = false;
    end
    ax = mouse.plot.plotBrain(ax,roiData,mask,[-0.25 0.25],cMap,addCBar,-0.002);
    ax = mouse.plot.plotNodes(ax,seedCenter,1,[0 1],cMap2,32);
    hold on; title(num2str(roiIndex));
    set(gca,'xtick',[]); set(gca,'ytick',[]);
end

%% lag oxy-gcamp

f4 = figure('Position',[100 100 1000 400]);
p = panel(f4);
panelRowSize = repmat(1/4,1,4);
panelColSize = repmat(1/11,1,11);
p.pack(panelRowSize,panelColSize);
p.margin = [2 2 2 2];
for roiIndex = roiIndices
    row = ceil(roiIndex/10); col = mod(roiIndex-1,10)+1;
    ax = p(row,col).select();
    set(ax,'Visible','off');
    
    roiLoc = roiLocs == roiIndex;
    seedCenter = seedCenters(roiIndex==roiIndices,:);
    roiData = reshape(nanmean(lagTimeOxyG6(:,roiLoc),2),size(roiLocs));
    
    if roiIndex == max(roiIndices)
        addCBar = true;
    else
        addCBar = false;
    end
    ax = mouse.plot.plotBrain(ax,roiData,mask,[-0.5 0.5],cMap,addCBar,-0.002);
    ax = mouse.plot.plotNodes(ax,seedCenter,1,[0 1],cMap2,32);
    hold on; title(num2str(roiIndex));
    set(gca,'xtick',[]); set(gca,'ytick',[]);
end

%% lag oxy seed - gcamp

f5 = figure('Position',[100 100 1000 400]);
p = panel(f5);
panelRowSize = repmat(1/4,1,4);
panelColSize = repmat(1/11,1,11);
p.pack(panelRowSize,panelColSize);
p.margin = [2 2 2 2];
for roiIndex = roiIndices
    row = ceil(roiIndex/10); col = mod(roiIndex-1,10)+1;
    ax = p(row,col).select();
    set(ax,'Visible','off');
    
    roiLoc = roiLocs == roiIndex;
    seedCenter = seedCenters(roiIndex==roiIndices,:);
    roiData = reshape(nanmean(lagTimeOxyG6(roiLoc,:),1),size(roiLocs));
    
    if roiIndex == max(roiIndices)
        addCBar = true;
    else
        addCBar = false;
    end
    ax = mouse.plot.plotBrain(ax,roiData,mask,[-0.5 0.5],cMap,addCBar,-0.002);
    ax = mouse.plot.plotNodes(ax,seedCenter,1,[0 1],cMap2,32);
    hold on; title(num2str(roiIndex));
    set(gca,'xtick',[]); set(gca,'ytick',[]);
end