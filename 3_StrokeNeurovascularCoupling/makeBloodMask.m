% close all

% loads lag analysis data and plots average over all mice
mainFile = 'D:\data\zachRosenthal\_summary\avgPower.mat';

load(mainFile);

%% make contour mask of where the infarct site is

contourData = squeeze(avgData{1}(:,:,1,:));
contourData = squeeze(contourData(:,:,1));

maxLag = max(contourData(:));
thr = maxLag/2;

bloodMask = contourData > thr;

% save contourMask
bloodMaskFile = 'D:\data\zachRosenthal\bloodMask.mat';
save(bloodMaskFile,'bloodMask');