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

lagAmpOxy = nan(pixNum,14);
lagTimeOxy = lagAmpOxy;
lagAmpG6 = lagAmpOxy;
lagTimeG6 = lagAmpOxy;
lagAmpOxyG6 = lagAmpOxy;
lagTimeOxyG6 = lagAmpOxy;
lagAmpG6Oxy = lagAmpOxy;
lagTimeG6Oxy = lagAmpOxy;

for row = 1:14
    disp(['row # ' num2str(row)]);
    [~, ~, rowData]=xlsread(xlsFile,1, ['A',num2str(row),':F',num2str(row)]);
    mouseName = rowData{2};
    lagAmpOxyMouse = nan(pixNum,3);
    lagTimeOxyMouse = lagAmpOxyMouse;
    lagAmpG6Mouse = lagAmpOxyMouse;
    lagTimeG6Mouse = lagAmpOxyMouse;
    lagAmpOxyG6Mouse = lagAmpOxyMouse;
    lagTimeOxyG6Mouse = lagAmpOxyMouse;
    lagAmpG6OxyMouse = lagAmpOxyMouse;
    lagTimeG6OxyMouse = lagAmpOxyMouse;
    
    for run = 1:3
        dataFile = fullfile(dataDir,[mouseName '-run' num2str(run) '-projLagOxyG6-ds4.mat']);
        runData = load(dataFile);
        lagAmpOxyMouse(:,run) = nanmean(runData.lagAmpOxy,2);
        lagTimeOxyMouse(:,run) = nanmean(runData.lagTimeOxy,2);
        lagAmpG6Mouse(:,run) = nanmean(runData.lagAmpG6,2);
        lagTimeG6Mouse(:,run) = nanmean(runData.lagTimeG6,2);
        lagAmpOxyG6Mouse(:,run) = nanmean(runData.lagAmpOxyG6,2); % how much each pixel's oxy lags behind all other gcamp
        lagTimeOxyG6Mouse(:,run) = nanmean(runData.lagTimeOxyG6,2);
        lagAmpG6OxyMouse(:,run) = nanmean(runData.lagAmpOxyG6,1); % how much each pixel's gcamp lags behind all other oxy
        lagTimeG6OxyMouse(:,run) = nanmean(runData.lagTimeOxyG6,1);
    end
    
    lagAmpOxy(:,row) = nanmean(lagAmpOxyMouse,2);
    lagTimeOxy(:,row) = nanmean(lagTimeOxyMouse,2);
    lagAmpG6(:,row) = nanmean(lagAmpG6Mouse,2);
    lagTimeG6(:,row) = nanmean(lagTimeG6Mouse,2);
    lagAmpOxyG6(:,row) = nanmean(lagAmpOxyG6Mouse,2);
    lagTimeOxyG6(:,row) = nanmean(lagTimeOxyG6Mouse,2);
    lagAmpG6Oxy(:,row) = nanmean(lagAmpG6OxyMouse,2);
    lagTimeG6Oxy(:,row) = nanmean(lagTimeG6OxyMouse,2);
end

lagAmpOxy = nanmean(lagAmpOxy,2);
lagTimeOxy = nanmean(lagTimeOxy,2);
lagAmpG6 = nanmean(lagAmpG6,2);
lagTimeG6 = nanmean(lagTimeG6,2);
lagAmpOxyG6 = nanmean(lagAmpOxyG6,2);
lagTimeOxyG6 = nanmean(lagTimeOxyG6,2);
lagAmpG6Oxy = nanmean(lagAmpG6Oxy,2);
lagTimeG6Oxy = nanmean(lagTimeG6Oxy,2);

%% plot projection lag amp
cMap = jet(100);
cMap2 = gray(100);

figure;
plotData = reshape(lagAmpG6Oxy,sqrt(numel(lagAmpG6Oxy)),sqrt(numel(lagAmpG6Oxy)));
imagesc(plotData,'AlphaData',mask,[0 1]); colormap('jet');
colorbar;
set(gca,'Visible','off');
set(gca,'xtick',[]); set(gca,'ytick',[]);

%% lag oxy

figure;
plotData = reshape(lagTimeOxy,sqrt(numel(lagTimeOxy)),sqrt(numel(lagTimeOxy)));
imagesc(plotData,'AlphaData',mask,[-0.5 0.5]); colormap('jet');
colorbar;
set(gca,'Visible','off');
set(gca,'xtick',[]); set(gca,'ytick',[]);

%% lag gcamp

figure;
plotData = reshape(lagTimeG6,sqrt(numel(lagTimeG6)),sqrt(numel(lagTimeG6)));
imagesc(plotData,'AlphaData',mask,[-0.5 0.5]); colormap('jet');
colorbar;
set(gca,'Visible','off');
set(gca,'xtick',[]); set(gca,'ytick',[]);

%% lag oxy pix behind gcamp

figure;
plotData = reshape(lagTimeOxyG6,sqrt(numel(lagTimeOxyG6)),sqrt(numel(lagTimeOxyG6)));
imagesc(plotData,'AlphaData',mask,[-0.5 0.5]); colormap('jet');
colorbar;
set(gca,'Visible','off');
set(gca,'xtick',[]); set(gca,'ytick',[]);

%% lag oxy pix behind gcamp

figure;
plotData = reshape(lagTimeG6Oxy,sqrt(numel(lagTimeG6Oxy)),sqrt(numel(lagTimeG6Oxy)));
imagesc(plotData,'AlphaData',mask,[-0.5 0.5]); colormap('jet');
colorbar;
set(gca,'Visible','off');
set(gca,'xtick',[]); set(gca,'ytick',[]);