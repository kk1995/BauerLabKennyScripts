% loads in the roi and plots

wlFile = 'D:\data\170126\170126-2528_baseline-LandmarksandMask.mat';
maskFile = 'D:\data\zachRosenthal\_meta\mask.mat';
dataFile = 'D:\data\zachRosenthal\_stim\baseline_ROI_Lag.mat';
load(dataFile);
lagAmp1 = lagAmp;
lagTime1 = lagTime;
dataFile = 'D:\data\zachRosenthal\_stim\week8_ROI_Lag.mat';
load(dataFile);
lagAmp(1:2) = lagAmp1(1:2);
lagTime(1:2) = lagTime1(1:2);

load(wlFile); % xform_WL
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

%% plot lag time

if freqInd == 1
    cLim = [-0.5 0.5];
else
    cLim = [-0.03 0.03];
end

speciesNum = size(lagTime{1},4);
cMap = jet(100);

f1 = figure('Position',[100 100 800 365]);
p = panel();
p.pack('h',{0.23 0.23 0.23 0.23});
p.pack(speciesNum, 4);
for n = 1:4
    p(n).pack(2);
end
p.margin = [0 0 1 0];
% p.margin = [2 0 10 0];
% p.select('all');
for week = 1:4
    for species = 1:speciesNum
        ax = p(week,species).select();
        set(ax,'Color','k');
        set(gca,'xtick',[])
        set(gca,'xticklabel',[])
        set(gca,'ytick',[])
        set(gca,'yticklabel',[])
        axis(ax,'square');
        
        % plot fc data
        plotData = squeeze(nanmean(lagTime{week}(:,:,freqInd,species,:),5));
        mask = nanmean(maskData{week},3);
        mask = mask > 0.5;
        
        if week == 4
            ax = mouseAnalysis.plot.plotBrain(ax,plotData,mask,cLim,cMap,true,0.02);
            set(ax(end),'FontSize',16);
        else
            ax = mouseAnalysis.plot.plotBrain(ax,plotData,mask,cLim,cMap);
        end
        
        if week < 3
            stimWeek = 1;
        else
            stimWeek = 4;
        end
        
        % plot contour
        contour = stimLoc{stimWeek};
        
        ax = mouseAnalysis.plot.plotContour(ax,contour,'k');
    end
end

%% plot lag amp
cLim = [0 1];

speciesNum = size(lagAmp{1},4);
cMap = jet(100);

f1 = figure('Position',[100 100 800 380]);
p = panel();
p.pack('h',{0.23 0.23 0.23 0.23});
p.pack(speciesNum, 4);
for n = 1:4
    p(n).pack(2);
end
p.margin = [0 0 3 0];
% p = panel();
% p.pack(speciesNum, 4);
% p.margin = [2 0 10 0];

for week = 1:4
    for species = 1:speciesNum
        ax = p(week,species).select();
        set(ax,'Color','k');
        set(gca,'xtick',[])
        set(gca,'xticklabel',[])
        set(gca,'ytick',[])
        set(gca,'yticklabel',[])
        axis(ax,'square');
        
        % plot fc data
        plotData = squeeze(nanmean(lagAmp{week}(:,:,freqInd,species,:),5));
        mask = nanmean(maskData{week},3);
        mask = mask > 0.5;
        
        if week == 4
            ax = mouseAnalysis.plot.plotBrain(ax,plotData,mask,cLim,cMap,true);
        else
            ax = mouseAnalysis.plot.plotBrain(ax,plotData,mask,cLim,cMap);
        end
        
        if week < 3
            stimWeek = 1;
        else
            stimWeek = 4;
        end
        
        % plot contour
        contour = stimLoc{stimWeek};
        
        ax = mouseAnalysis.plot.plotContour(ax,contour,'k');
    end
end