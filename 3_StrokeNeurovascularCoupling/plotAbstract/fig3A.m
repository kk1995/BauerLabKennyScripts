% loads in the roi and plots

wlFile = 'D:\ProcessedData\170126\170126-2528_baseline-fc-LandmarksandMask.mat';
maskFile = 'D:\data\zachRosenthal\_meta\mask.mat';
dataFile = 'D:\data\zachRosenthal\_stim\baseline_ROI_FC_GSR.mat';
load(dataFile);
fcData1 = fcData;
dataFile = 'D:\data\zachRosenthal\_stim\week8_ROI_FC_GSR.mat';
load(dataFile);
fcData(1:2) = fcData1(1:2);

load(maskFile); % maskData

freqInd = 1;

%% load stim files
load('D:\data\zachRosenthal\_stim\ROI R 75.mat');
stimLoc{1} = roiR75;
load('D:\data\zachRosenthal\_stim\ROI R 75 vs baseline wk1 after stroke.mat');
stimLoc{2} = roiR75ofbaselineatwk1;
load('D:\data\zachRosenthal\_stim\ROI R 75 wk4 after stroke.mat');
stimLoc{3} = roiR75wk4;
load('D:\data\zachRosenthal\_stim\ROI R 75 wk8.mat');
stimLoc{4} = roiR75wk8;

% load('D:\data\zachRosenthal\_stim\ROI L 75.mat');
% stimLoc{1} = roiL75;
% stimLoc{2} = roiL75;
% stimLoc{3} = roiL75;
% stimLoc{4} = roiL75;

%% get the fc data

load('L:\ProcessedData\noVasculatureMask.mat');
wlData = load('L:\ProcessedData\wl.mat');

speciesNum = size(fcData{1},4);
cMap = jet(100);

f1 = figure('Position',[100 100 750 365]);
p = panel();
p.pack('h',{0.23 0.23 0.23 0.23});
p.pack(speciesNum, 4);
for n = 1:4
    p(n).pack(2);
end
p.margin = [0 0 1 0];

for week = 1:4
    for species = 1:speciesNum
        ax = p(week,species).select();
        set(ax,'Color','k');
        set(gca,'xtick',[])
        set(gca,'xticklabel',[])
        set(gca,'ytick',[])
        set(gca,'yticklabel',[])
        axis(ax,'square');
        
        image(wlData.xform_wl,'AlphaData',wlData.xform_isbrain);
        xlim([1 size(wlData.xform_wl,1)]); ylim([1 size(wlData.xform_wl,2)]);
        set(gca,'ydir','reverse');
        hold on;
        
        % plot fc data
        plotData = squeeze(nanmean(fcData{week}(:,:,freqInd,species,:),5));
        mask = nanmean(maskData{week},3);
        mask = mask > 0.5;
        mask = mask & (leftMask | rightMask);
        
        if week == 4
            ax = mouse.plot.plotBrain(ax,plotData,mask,[-1 1],cMap,true,0.01);
            set(ax(end),'FontSize',16);
        else
            ax = mouse.plot.plotBrain(ax,plotData,mask,[-1 1],cMap);
        end
        
        if week < 3
            stimWeek = 1;
        else
            stimWeek = 4;
        end
        
        % plot contour
        contour = stimLoc{stimWeek};
        
        ax = mouse.plot.plotContour(ax,contour,'k');
    end
end