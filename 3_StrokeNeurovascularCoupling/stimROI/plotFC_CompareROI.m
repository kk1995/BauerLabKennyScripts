% loads in the roi and plots

wlFile = 'D:\data\170126\170126-2528_baseline-LandmarksandMask.mat';
maskFile = 'D:\data\zachRosenthal\_meta\mask.mat';
dataFile = 'D:\data\zachRosenthal\_stim\baseline_ROI_FC_GSR.mat';
dataFile2 = 'D:\data\zachRosenthal\_stim\week8_ROI_FC_GSR.mat';

load(wlFile); % xform_WL
load(maskFile); % maskData

freqInd = 1;
species = 1;

%% load stim files
load('D:\data\zachRosenthal\_stim\ROI R 75.mat');
stimLocL{1} = roiR75;
load('D:\data\zachRosenthal\_stim\ROI R 75 wk8.mat');
stimLocL{2} = roiR75wk8;

%% isolate fc data to plot


data = cell(2,2);
maskList = cell(2,2);
load(dataFile);
data{1,1} = squeeze(nanmean(fcData{1}(:,:,freqInd,species,:),5));
data{1,2} = squeeze(nanmean(fcData{4}(:,:,freqInd,species,:),5));

load(dataFile2);
data{2,1} = squeeze(nanmean(fcData{1}(:,:,freqInd,species,:),5));
data{2,2} = squeeze(nanmean(fcData{4}(:,:,freqInd,species,:),5));

maskList{1,1} = nanmean(maskData{1},3) > 0.5;
maskList{1,2} = nanmean(maskData{4},3) > 0.5;
maskList{2,1} = nanmean(maskData{1},3) > 0.5;
maskList{2,2} = nanmean(maskData{4},3) > 0.5;

speciesNum = size(fcData{1},4);
cMap = jet(100);

f1 = figure('Position',[100 100 450 400]);
p = panel();
p.pack('h',{0.43 0.43});
p(1).pack(2);
p(2).pack(2);
p.margin = [0 0 3 0];
p.select('all');

for week = 1:2
    for roiInd = 1:2
        ax = p(week,roiInd).select();
        
        % plot fc data
        plotData = data{roiInd,week};
        mask = maskList{roiInd,week};
        
        if week == 2
            s = plotBrain(ax,plotData,mask,[-1 1],cMap,true);
        else
            s = plotBrain(ax,plotData,mask,[-1 1],cMap);
        end
        % plot contour
        contour = stimLocL{roiInd};
        
        s2 = plotContour(s,contour,'k');
    end
end