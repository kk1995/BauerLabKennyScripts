% loads in the roi and plots

% wlFile = 'D:\data\170126\170126-2528_baseline-LandmarksandMask.mat';
atlasFile = 'D:\data\atlas.mat';
% maskFile = 'D:\data\zachRosenthal\_meta\mask.mat';

% load(wlFile); % xform_WL
load(atlasFile,'AtlasSeeds','seednames'); % AtlasSeeds
% load(maskFile); % maskData
labels = seednames(1:20);
%% load stim files
load('D:\data\zachRosenthal\_stim\ROI R 75.mat');
stimLocL{1} = roiR75;
load('D:\data\zachRosenthal\_stim\ROI R 75 vs baseline wk1 after stroke.mat');
stimLocL{2} = roiR75ofbaselineatwk1;
load('D:\data\zachRosenthal\_stim\ROI R 75 wk4 after stroke.mat');
stimLocL{3} = roiR75wk4;
load('D:\data\zachRosenthal\_stim\ROI R 75 wk8.mat');
stimLocL{4} = roiR75wk8;

%% plot
f1 = figure('Position',[100 50 500 500]);
p = subplot(1,1,1);
color = {'k','b','r','m'};
% mask = mean(maskData{1},3) > 0.9;
% ax = plotBrain(p,xform_WL,mask);
mask = AtlasSeeds>0;
AtlasSeeds(AtlasSeeds > 20) = AtlasSeeds(AtlasSeeds > 20) - 20;
cLim = [1 20];
cMap = jet(100);
brainP = [];
[ax, brainP] = plotAtlas(p,AtlasSeeds,labels,cLim,cMap);
contourPlots = [];
for week = 1:4
    contourMask = stimLocL{week};
    [axT, pT] = plotContour(ax,contourMask,color{week});
    contourPlots = [contourPlots pT];
end
legend(contourPlots,'baseline','week 1','week 4','week 8');
% make subplots square
axesHandles = findobj(get(f1,'Children'), 'flat','Type','axes');
axis(axesHandles,'square');