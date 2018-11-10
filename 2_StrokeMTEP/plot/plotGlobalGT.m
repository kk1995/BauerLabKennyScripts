close all;

load('D:\data\StrokeMTEP\NodalConnectivity.mat');
% load('D:\data\StrokeMTEP\NodalConnectivityDetailedMotor.mat');

load('D:\data\atlas.mat');

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