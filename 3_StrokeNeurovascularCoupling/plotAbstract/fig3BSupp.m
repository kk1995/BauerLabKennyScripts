% file for WL
wlFile = 'D:\data\170205\170205-2541 week 1-LandmarksandMask.mat';
load(wlFile,'WL');

% file for mask
maskFile = 'D:\data\zachRosenthal\week1mask.mat';
load(maskFile); % mask

% file for L cortex seed
lSeedFile = 'D:\data\zachRosenthal\_stim\ROI R 75.mat';
load(lSeedFile);
lROI = roiR75;
clear roiR75;

% file for second L cortex seed
lSeedFile2 = 'D:\data\zachRosenthal\_stim\ROI R 75 wk8.mat';
load(lSeedFile2);
lROI2 = roiR75wk8;
clear roiR75wk8;

% file for R cortex seed
rSeedFile = 'D:\data\zachRosenthal\_stim\ROI L 75.mat';
load(rSeedFile);
rROI = roiL75;
clear roiL75;

%% plot

mask = mask >= 0.8;
f1 = figure();
s1 = mouseAnalysis.plot.plotBrain(f1,WL,mask);
s2 = mouseAnalysis.plot.plotContour(s1,lROI,'k','-',4);
s3 = mouseAnalysis.plot.plotContour(s2,lROI2,'k','-',4);
mouseAnalysis.plot.plotContour(s3,rROI,'b','-',4);