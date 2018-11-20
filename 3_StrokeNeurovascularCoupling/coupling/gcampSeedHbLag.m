% fs, data1, data2
% load('K:\Proc2\170126\170126-2541_baseline-dataGCaMP-fc1.mat');
fs = info.framerate;
validInd = round(fs*1); validInd = -validInd:validInd;

load('K:\Proc2\170126\170126-2541_baseline-LandmarksandMask.mat');
mask = mask > 0;

% roi
roiInd = 79+94*128;

% % gsr
% gcamp6corrGSR = mouse.preprocess.gsr(gcamp6corr,mask);
% oxyGSR = mouse.preprocess.gsr(oxy,mask);


% lag
disp('lag analysis')
[lagData,ampData] = crossSeedLag(gcamp6corr,oxy,roiInd,validInd);
lagData = lagData./fs;

%% plot

figure;
imagesc(ampData,'AlphaData',mask,[0 1]); axis(gca,'square'); colormap('jet'); colorbar;

figure;
imagesc(lagData,'AlphaData',mask,[-1 1]); axis(gca,'square'); colormap('jet'); colorbar;