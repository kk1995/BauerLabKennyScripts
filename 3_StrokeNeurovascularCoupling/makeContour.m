% close all

% loads lag analysis data and plots average over all mice
mainDir = 'D:\data\zachRosenthal\week1_lag_bilateral_0p009to0p5';
saveFigDir = 'D:\figures\3_StrokeNeurovascularCoupling\allMice';
saveFigFile = 'week1_lag_bilateral_0p009to0p5';

useContour = true;
saveFigure = false; % whether to save figures


D = dir(mainDir); D(1:2) = [];

lagMatMean = [];
ampMatMean = [];
maskMean = [];

for i = 1:numel(D)
    fileData = load(fullfile(mainDir,D(i).name));
    lagMatMean = cat(4,lagMatMean,fileData.lagMouse);
    maskMean = cat(3,maskMean,nanmean(fileData.maskMouse,3));
end

% lagMatMean = x y species mice

%% make contour mask of where the infarct site is

contourData = squeeze(lagMatMean(:,:,4,:));
contourData = mean(contourData,3);

maxLag = max(contourData(:));
thr = maxLag/2;

contourMask = contourData > thr;

contourBounds = [find(sum(contourMask,1) > 0,1,'first')  find(sum(contourMask,1) > 0,1,'last'); ...
    find(sum(contourMask,2) > 0,1,'first')  find(sum(contourMask,2) > 0,1,'last')];

% save contourMask
contourFile = 'D:\data\zachRosenthal\contour.mat';
save(contourFile,'contourMask','maskMean');