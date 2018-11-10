% plots the brain mask with nodes on top of it inter connected.

close all;

load('D:\data\StrokeMTEP\NodalConnectivity.mat','seedCenter','seednames');
load('D:\data\170126\170126-2541_baseline-LandmarksandMask.mat','xform_WL'); % get wl image
load('D:\data\atlas.mat','AtlasSeedsFilled');


nodeSize = 80;

% roiInd = [4:11 13:15 24:31 33:35]; % regions I am interested in showing
% roiInd = [2:20 22:40];
roiInd = [2 4:20 22 24:40];
% roiInd = [13:20 24:29 33:40];
% roiInd = [12:18 22:25 29:42];
% roiInd = [12:16 22:25 29:34 37:42];
% roiInd = [2:18 20:42];

% principal component 1 indices
pcRoiInd = [13:20 24:29 33:40];

%% plot

seedCenter = seedCenter(roiInd,:);

seedVal = zeros(numel(seednames),1);
seedVal(pcRoiInd) = 1;
seedVal = seedVal(roiInd);

whiteLight = xform_WL;
mask = AtlasSeedsFilled>0;
blueRedMap = blueWhiteRed(100,[1 0],true);

f1 = figure('Position',[100 100 600 600]);
plotNodeBrain(f1,whiteLight,mask,...
    seedCenter,seedVal,[0 1],blueRedMap,160,false);