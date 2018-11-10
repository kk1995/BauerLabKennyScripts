close all;

load('D:\data\StrokeMTEP\NodalConnectivity.mat');
% load('D:\data\StrokeMTEP\NodalConnectivityDetailedMotor.mat');

load('D:\data\atlas.mat','mask','mask2');
mask = mask & mask2;

xRotAngle = 90;

corrMapAll = [];
D_weiAll = [];
iterNum = 100;

% roiInd = [4:11 13:15 24:31 33:35]; % regions I am interested in showing
% roiInd = [2:20 22:40]; % whole brain
% roiInd = [2 4:20 22 24:40]; % whole brain but without RS
% roiInd = [13:20 24:29 33:40]; % out of 40 ind, only PC 1
% roiInd = [12:18 22:25 29:42];
% roiInd = [12:16 22:25 29:34 37:42];
% roiInd = [2:18 20:42];
roiInd = [22 24:40]; % R hemisphere without RS

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
    
    for mouse = 1:size(data{cond},3)
        outputTemp = graphTheoryMeasures(data{cond}(:,:,mouse));
        output{cond}.local.clusterCoefficient(:,mouse) = outputTemp.local.clusterCoefficient;
        output{cond}.local.pathLength(:,mouse) = outputTemp.local.pathLength;
        output{cond}.local.strength(:,mouse) = outputTemp.local.strength;
        output{cond}.local.betweenness(:,mouse) = outputTemp.local.betweenness;
        output{cond}.local.hub(:,mouse) = outputTemp.local.hub;
        output{cond}.global.clusterCoefficient(mouse) = outputTemp.global.clusterCoefficient;
        output{cond}.global.pathLength(mouse) = outputTemp.global.pathLength;
        output{cond}.global.smallWorldness(mouse) = outputTemp.global.smallWorldness;
        output{cond}.global.smallWorldPropensity(mouse) = outputTemp.global.smallWorldPropensity;
    end
end

%%

nodeLoc = seedCenter(roiInd,:);
nodeSize = 64;

c1 = [1 1 1]; c2 = [1 0 0];
cMap = twoColor(c1,c2,100);

% cMap = viridis(100);

load('D:\data\170126\170126-2541_baseline-LandmarksandMask.mat','xform_WL'); % get wl image
load('D:\data\atlas.mat','AtlasSeedsFilled'); % load mask

whiteLight = mean(xform_WL,3);
condNum = numel(output);

f1 = figure('Position',[50 50 condNum*300 900]);
p = panel();
p.pack(3, 3);
p.margin = [2 2 20 2];
p.de.margin = 2;
for cond = 1:condNum
    addColorBar = false;
    if cond == condNum
        addColorBar = true;
    end
    
    % pathlength
    nodeVal = nanmean(output{cond}.local.pathLength,2);
    s = p(1,cond).select();
    s = plotWL(s,whiteLight,mask);
    s = plotNodes(s,nodeLoc,nodeVal,[2 8],cMap,nodeSize,addColorBar);
    
    % cluster coefficient
    nodeVal = nanmean(output{cond}.local.clusterCoefficient,2);
    s = p(2,cond).select();
    s = plotWL(s,whiteLight,mask);
    s = plotNodes(s,nodeLoc,nodeVal,[0.1 0.5],cMap,nodeSize,addColorBar);
    
    % strength
    nodeVal = nanmean(output{cond}.local.strength,2);
    s = p(3,cond).select();
    s = plotWL(s,whiteLight,mask);
    s = plotNodes(s,nodeLoc,nodeVal,[1 9],cMap,nodeSize,addColorBar);
%     
%     plotNodeBrain(subplot(3,condNum,cond),whiteLight,mask,...
%         seedCenter(roiInd,:),nanmean(output{cond}.local.pathLength,2),[2.5 7]);
% 
%     plotNodeBrain(subplot(3,condNum,cond+condNum),whiteLight,mask,...
%         seedCenter(roiInd,:),nanmean(output{cond}.local.clusterCoefficient,2),[0.2 0.5]);
% 
%     plotNodeBrain(subplot(3,condNum,cond+condNum*2),whiteLight,mask,...
%         seedCenter(roiInd,:),nanmean(output{cond}.local.strength,2),[2 10]);
end

%% get significance
pairs = nchoosek(1 : numel(data), 2);
if numel(data) == 4 % do not compare data 2 and 3 if 4 conditions
    pairs = pairs([1 2 3 5 6],:);
end
pairNum = size(pairs,1);

pVal = cell(3,pairNum);
for pair = 1:pairNum
    for ind = 1:numel(roiInd)
        test1 = output{pairs(pair,1)}.local.pathLength(ind,:);
        test2 = output{pairs(pair,2)}.local.pathLength(ind,:);
        [~,pValTemp] = ttest2(test1,test2);
        pVal{1,pair} = [pVal{1,pair} pValTemp];
        
        test1 = output{pairs(pair,1)}.local.clusterCoefficient(ind,:);
        test2 = output{pairs(pair,2)}.local.clusterCoefficient(ind,:);
        [~,pValTemp] = ttest2(test1,test2);
        pVal{2,pair} = [pVal{2,pair} pValTemp];
        
        test1 = output{pairs(pair,1)}.local.strength(ind,:);
        test2 = output{pairs(pair,2)}.local.strength(ind,:);
        [~,pValTemp] = ttest2(test1,test2);
        pVal{3,pair} = [pVal{3,pair} pValTemp];
    end
    
    pVal{1,pair} = holmBonf(pVal{1,pair});
    pVal{2,pair} = holmBonf(pVal{2,pair});
    pVal{3,pair} = holmBonf(pVal{3,pair});
end


%% plot the differences
blueRedMap = blueWhiteRed(100);
ringThickness = 2;

f4 = figure('Position',[150 50 pairNum*300 900]);
p = panel();
p.pack(3, 3);
p.margin = [2 2 20 2];
p.de.margin = 2;
for pair = 1:pairNum
    addColorBar = false;
    if pair == pairNum
        addColorBar = true;
    end
    
    % pathlength
    nodeVal = nanmean(output{pairs(pair,2)}.local.pathLength,2) - ...
        nanmean(output{pairs(pair,1)}.local.pathLength,2);
    s = p(1,pair).select();
    s = plotBrain(s,whiteLight,mask);
    s = plotNodes(s,nodeLoc,nodeVal,[-3 3],blueRedMap,nodeSize,addColorBar);
    s = plotScatter(s,nodeLoc(pVal{1,pair}>0,:),zeros(sum(pVal{1,pair}),1),...
        [0 1],gray(100),nodeSize*3,ringThickness);
    
    % cluster coefficient
    nodeVal = nanmean(output{pairs(pair,2)}.local.clusterCoefficient,2) - ...
        nanmean(output{pairs(pair,1)}.local.clusterCoefficient,2);
    s = p(2,pair).select();
    s = plotBrain(s,whiteLight,mask);
    s = plotNodes(s,nodeLoc,nodeVal,[-0.15 0.15],blueRedMap,nodeSize,addColorBar);
    s = plotScatter(s,nodeLoc(pVal{2,pair}>0,:),zeros(sum(pVal{2,pair}),1),...
        [0 1],gray(100),nodeSize*3,ringThickness);
    
    % strength
    nodeVal = nanmean(output{pairs(pair,2)}.local.strength,2) - ...
        nanmean(output{pairs(pair,1)}.local.strength,2);
    s = p(3,pair).select();
    s = plotBrain(s,whiteLight,mask);
    s = plotNodes(s,nodeLoc,nodeVal,[-3 3],blueRedMap,nodeSize,addColorBar);
    s = plotScatter(s,nodeLoc(pVal{3,pair}>0,:),zeros(sum(pVal{3,pair}),1),...
        [0 1],gray(100),nodeSize*3,ringThickness);
    
end