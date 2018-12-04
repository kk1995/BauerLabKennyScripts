% close all;

load('D:\data\StrokeMTEP\NodalConnectivityZ.mat');
load('D:\data\atlas.mat');
seedCenterTotal = seedCenter;
% calculate coordinate of seeds (not just center coordinate)
seed2DCoor = mouse.plot.circleCoor(seedCenterTotal(1,:),3); % sees pixels needed for first seed
seedPix = nan(size(seed2DCoor,2),size(seedCenterTotal,1)); % initializes
for seedInd = 1:size(seedCenterTotal,1)
    seed2DCoor = mouse.plot.circleCoor(seedCenterTotal(seedInd,:),3);
    seedPix(:,seedInd) = seed2DCoor(2,:) + size(isbrain,1)*(seed2DCoor(1,:)-1);
end

xRotAngle = 90;

corrMapAll = [];
D_weiAll = [];
iterNum = 100;

%% get roi indices based on pca
pcInd = 1; % principal component index
clusterSizeThr = 200; % pixels
seedOverlapThr = 0.5; % how much of the seed needs to be in PC region

% index order
maskFile = 'D:\data\atlas.mat';
load(maskFile,'mask','mask2','AtlasSeedsFilled','seednames'); % mask
SeedsUsed=CalcRasterSeedsUsed(mask);
length=size(SeedsUsed,1);
map=[(1:2:length-1) (2:2:length)];
NewSeedsUsed(:,1)=SeedsUsed(map, 1);
NewSeedsUsed(:,2)=SeedsUsed(map, 2);
for n=1:size(NewSeedsUsed,1)
    idx_inv(n)=sub2ind([128,128], NewSeedsUsed(n,2), NewSeedsUsed(n,1)); % get the indices of the Seed coordinates used to organize the Pix-Pix matrix
    idx_inv=idx_inv';
end

% get pca data
pcaFile = 'D:\data\StrokeMTEP\PT_Groups_PCA.mat';
load(pcaFile); % coeff, score

z = scoreWithMean(:,pcInd)*coeff(:,pcInd)';
z = nanmean(z); % 1 x 11188 double
pcaVal = nan(128,128);
pcaVal(idx_inv) = z;

% find clusters of high values
threshold = prctile(abs(pcaVal(:)),95)*0.5;
aboveThr = abs(pcaVal) >= threshold;

% only select clusters that are big enough
clusters = bwconncomp(aboveThr,4);
goodClusters = false(size(clusters.PixelIdxList));
for clusterInd = 1:numel(goodClusters)
    if numel(clusters.PixelIdxList{clusterInd}) >= clusterSizeThr
        goodClusters(clusterInd) = true;
    end
end
clusters.NumObjects = sum(goodClusters);
clusters.PixelIdxList = clusters.PixelIdxList(goodClusters);
bigClusters = false(128,128);
for clusterInd = 1:numel(clusters.PixelIdxList)
    bigClusters(clusters.PixelIdxList{clusterInd}) = true;
end

% find whether a seed is in the PC region
roiInd = [];
for seedInd = 1:size(seedPix,2)
    if sum(bigClusters(seedPix(:,seedInd)))/size(seedPix,1) >= seedOverlapThr
        roiInd = [roiInd seedInd];
    end
end
roiInd(roiInd==3) = [];
roiInd(roiInd==23) = [];

notRoiInd = 1:size(seedPix,2);
notRoiInd(roiInd) = [];
notRoiInd(notRoiInd==1) = [];
notRoiInd(notRoiInd==21) = [];

seedPix = seedPix(:,roiInd);
seedCenterRoi = seedCenterTotal(roiInd,:);
seedCenterNotRoi = seedCenterTotal(notRoiInd,:);


%%
% roiInd = [4:11 13:15 24:31 33:35]; % regions I am interested in showing
% roiInd = [2:20 22:40]; % whole brain
% roiInd = [2 4:20 22 24:40]; % whole brain but without RS
% roiInd = [13:20 24:29 33:40]; % out of 40 ind, only PC 1
% roiInd = [12:18 22:25 29:42];
% roiInd = [12:16 22:25 29:34 37:42];
% roiInd = [2:18 20:42];
% roiInd = [22 24:40]; % R hemisphere without RS

data{1} = Veh_Sham_Nodal_R_Graph;
data{2} = Veh_PT_Nodal_R_Graph;
data{3} = MTEP_PT_Nodal_R_Graph;

% legendStr = {'Vehicle\newline Sham','MTEP\newlineSham'};
% legendStr = {'Vehicle\newline Sham','Vehicle\newline   PT'};
% legendStr = {'MTEP\newlineSham','MTEP\newline  PT'};
% legendStr = {'Vehicle\newline   PT','MTEP\newline  PT'};
% legendStr = {'Vehicle\newline Sham','MTEP\newline  PT'};
% legendStr = {'Vehicle\newline Sham','Vehicle\newline   PT','MTEP\newline  PT'};
legendStr = {'Vehicle\newline Sham','Vehicle\newline   PT','MTEP\newline  PT'};

roiLabels = seednames(roiInd);

for cond = 1:numel(data)
    % dealing with negative values
    data{cond}(data{cond} < 0) = 0;
    
    % making diagonal inf
    for mouseInd = 1:size(data{cond},3)
        data{cond}((1:size(data{cond},1)+1:size(data{cond},1)*size(data{cond},2))+(mouseInd-1)*size(data{cond},1)*size(data{cond},2)) = inf;
    end
    % limiting data to the roi
    data{cond} = data{cond}(roiInd,roiInd,:);
    
    
    % graph theory analysis
    output{cond}.local.clusterCoefficient = nan(size(data{cond},1),size(data{cond},3));
    output{cond}.local.pathLength = nan(size(data{cond},1),size(data{cond},3));
    output{cond}.local.strength = nan(size(data{cond},1),size(data{cond},3));
    output{cond}.local.betweenness = nan(size(data{cond},1),size(data{cond},3));
    output{cond}.local.hub = false(size(data{cond},1),size(data{cond},3));
    output{cond}.global.clusterCoefficient = nan(size(data{cond},3),1);
    output{cond}.global.pathLength = nan(size(data{cond},3),1);
    output{cond}.global.smallWorldness = nan(size(data{cond},3),1);
    output{cond}.global.smallWorldPropensity = nan(size(data{cond},3),1);
    
    for mouseInd = 1:size(data{cond},3)
        outputTemp = mouse.graph.graphTheoryMeasures(data{cond}(:,:,mouseInd));
        output{cond}.local.clusterCoefficient(:,mouseInd) = outputTemp.local.clusterCoefficient;
        output{cond}.local.pathLength(:,mouseInd) = outputTemp.local.pathLength;
        output{cond}.local.strength(:,mouseInd) = outputTemp.local.strength;
        output{cond}.local.betweenness(:,mouseInd) = outputTemp.local.betweenness;
        output{cond}.local.hub(:,mouseInd) = outputTemp.local.hub;
        output{cond}.global.clusterCoefficient(mouseInd) = outputTemp.global.clusterCoefficient;
        output{cond}.global.pathLength(mouseInd) = outputTemp.global.pathLength;
        output{cond}.global.smallWorldness(mouseInd) = outputTemp.global.smallWorldness;
        output{cond}.global.smallWorldPropensity(mouseInd) = outputTemp.global.smallWorldPropensity;
    end
end

%% plot pca
cLim = [0 1];
cMap = gray(100);
cMap2 = hsv(100);
f0 = figure;
ax = mouse.plot.plotBrain(f0,pcaVal,mask&mask2,[-0.01 0.01],'jet');
ax = mouse.plot.plotNodes(ax,seedCenterRoi,1,cLim,cMap,120,false);
ax = mouse.plot.plotScatter(ax,seedCenterRoi,0,cLim,cMap,120,3);
% ax = mouse.plot.plotNodes(ax,seedCenterNotRoi,0.2,cLim,cMap2,32,false);
ax = mouse.plot.plotScatter(ax,seedCenterNotRoi,0,cLim,cMap,32,1.5);
% ax = mouse.plot.plotScatter(ax,seedCenterNotRoi,0,cLim,cMap,96,1,'x');

%% global plot

% pairs to statistically compare
pairs = nchoosek(1 : numel(data), 2);
if numel(data) == 4 % do not compare data 2 and 3
    pairs = pairs([1 2 3 5 6],:);
end

% figure('Position',[20 100 1900 450]);
figure('Position',[20 100 numel(data)*250 300]);
s1 = subplot(1,3,1);
test = [];
boxInd = [];
for cond = 1:numel(data)
    testCond = output{cond}.global.clusterCoefficient;
    test = [test; testCond];
    boxInd = [boxInd; cond*ones(size(testCond))];
end
H = notBoxPlot(test,boxInd);
set([H(:).data],'MarkerSize',4,...
    'markerFaceColor',[1,1,1]*0.25,...
    'markerEdgeColor', 'none');
set([H(:).semPtch],...
    'FaceColor',[30 144 255]./256,...
    'EdgeColor','none');
set([H(:).sdPtch],...
    'FaceColor',[0 191 255]./256,...
    'EdgeColor','none');
set([H(:).mu],...
    'Color',[1,1,1]*0.75)
% boxplot([test1; test2],boxInd,'PlotStyle','Compact','Colors','b');
set(gca,'XTick',1:numel(data),'XTickLabel',legendStr);
set(gca,'TickLength',[0.02 0]);
for pairInd = 1:size(pairs,1)
    cond1 = pairs(pairInd,1);
    cond2 = pairs(pairInd,2);
    test1 = output{cond1}.global.clusterCoefficient;
    test2 = output{cond2}.global.clusterCoefficient;
    [~,pVal] = ttest2(test1,test2);
    title('Cluster coefficient');
    if pVal <= 1E-3
        sigstar({pairs(pairInd,:)},1E-3);
    elseif pVal <= 1E-2
        sigstar({pairs(pairInd,:)},1E-2);
    elseif pVal <= 0.05
        sigstar({pairs(pairInd,:)},0.05);
    else
        sigstar({pairs(pairInd,:)},nan);
    end
end
if numel(data) == 2
    yLim = s1.YLim;
    set(s1,'YLim',[yLim(1)*0.9 yLim(2)]);
    text(0.5,0.05,['p = ' num2str(pVal,'%.2g')],'HorizontalAlignment','center','Units','normalized');
end

s2 = subplot(1,3,2);
test = [];
boxInd = [];
for cond = 1:numel(data)
    testCond = output{cond}.global.pathLength;
    test = [test; testCond];
    boxInd = [boxInd; cond*ones(size(testCond))];
end
H = notBoxPlot(test,boxInd);
set([H(:).data],'MarkerSize',4,...
    'markerFaceColor',[1,1,1]*0.25,...
    'markerEdgeColor', 'none');
set([H(:).semPtch],...
    'FaceColor',[194 24 7]./256,...
    'EdgeColor','none');
set([H(:).sdPtch],...
    'FaceColor',[255 36 0]./256,...
    'EdgeColor','none');
set([H(:).mu],...
    'Color',[1,1,1]*0.75)
% boxplot([test1; test2],boxInd,'PlotStyle','Compact','Colors','r');
set(gca,'XTick',1:numel(data),'XTickLabel',legendStr);
set(gca,'TickLength',[0.02 0]);
for pairInd = 1:size(pairs,1)
    cond1 = pairs(pairInd,1);
    cond2 = pairs(pairInd,2);
    test1 = output{cond1}.global.pathLength;
    test2 = output{cond2}.global.pathLength;
    [~,pVal] = ttest2(test1,test2);
    title('Pathlength');
    if pVal <= 1E-3
        sigstar({pairs(pairInd,:)},1E-3);
    elseif pVal <= 1E-2
        sigstar({pairs(pairInd,:)},1E-2);
    elseif pVal <= 0.05
        sigstar({pairs(pairInd,:)},0.05);
    else
        sigstar({pairs(pairInd,:)},nan);
    end
end
if numel(data) == 2
    yLim = s2.YLim;
    set(s2,'YLim',[yLim(1)*0.9 yLim(2)]);
    text(0.5,0.05,['p = ' num2str(pVal,'%.2g')],'HorizontalAlignment','center','Units','normalized');
end


s3 = subplot(1,3,3);
test = [];
boxInd = [];
for cond = 1:numel(data)
    testCond = output{cond}.global.smallWorldness;
    test = [test; testCond];
    boxInd = [boxInd; cond*ones(size(testCond))];
end
H = notBoxPlot(test,boxInd);
set([H(:).data],'MarkerSize',4,...
    'markerFaceColor',[1,1,1]*0.25,...
    'markerEdgeColor', 'none');
set([H(:).semPtch],...
    'FaceColor',[63 122 77]./256,...
    'EdgeColor','none');
set([H(:).sdPtch],...
    'FaceColor',[0 168 107]./256,...
    'EdgeColor','none');
set([H(:).mu],...
    'Color',[1,1,1]*0.75)
% boxplot([test1; test2],boxInd,'PlotStyle','Compact','Colors','m');
set(gca,'XTick',1:numel(data),'XTickLabel',legendStr);
set(gca,'TickLength',[0.02 0]);
for pairInd = 1:size(pairs,1)
    cond1 = pairs(pairInd,1);
    cond2 = pairs(pairInd,2);
    test1 = output{cond1}.global.smallWorldness;
    test2 = output{cond2}.global.smallWorldness;
    [~,pVal] = ttest2(test1,test2);
    title('Small worldness');
    if pVal <= 1E-3
        sigstar({pairs(pairInd,:)},1E-3);
    elseif pVal <= 1E-2
        sigstar({pairs(pairInd,:)},1E-2);
    elseif pVal <= 0.05
        sigstar({pairs(pairInd,:)},0.05);
    else
        sigstar({pairs(pairInd,:)},nan);
    end
end
if numel(data) == 2
    yLim = s3.YLim;
    set(s3,'YLim',[yLim(1)*0.9 yLim(2)]);
    text(0.5,0.05,['p = ' num2str(pVal,'%.2g')],'HorizontalAlignment','center','Units','normalized');
end