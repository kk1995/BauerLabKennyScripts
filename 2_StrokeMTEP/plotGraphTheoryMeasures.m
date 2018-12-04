close all;

load('D:\data\StrokeMTEP\NodalConnectivityZ.mat');
% load('D:\data\StrokeMTEP\NodalConnectivityDetailedMotor.mat');

load('D:\data\atlas.mat');

xRotAngle = 90;

corrMapAll = [];
D_weiAll = [];
iterNum = 100;

% roiInd = [4:11 13:15 24:31 33:35]; % regions I am interested in showing
% roiInd = [2:20 22:40];
roiInd = [13:20 24:29 33:40];
% roiInd = [12:18 22:25 29:42];
% roiInd = [12:16 22:25 29:34 37:42];
% roiInd = [2:18 20:42];

data1 = Veh_PT_Nodal_R_Graph;
data2 = MTEP_PT_Nodal_R_Graph;

% legendStr = {'Vehicle\newline Sham','MTEP\newlineSham'};
% legendStr = {'Vehicle\newline Sham','Vehicle\newline   PT'};
% legendStr = {'MTEP\newlineSham','MTEP\newline  PT'};
legendStr = {'Vehicle\newline   PT','MTEP\newline  PT'};
% legendStr = {'Vehicle\newline Sham','MTEP\newline  PT'};

roiLabels = seednames(roiInd);

% dealing with negative values
% data1 = abs(data1);
% data2 = abs(data2);
data1(data1 < 0) = 0;
data2(data2 < 0) = 0;

% limiting data to the roi
data1 = data1(roiInd,roiInd,:);
data2 = data2(roiInd,roiInd,:);

% graph theory analysis

output1.local.clusterCoefficient = nan(size(data1,1),size(data1,3));
output1.local.pathLength = nan(size(data1,1),size(data1,3));
output1.local.strength = nan(size(data1,1),size(data1,3));
output1.local.betweenness = nan(size(data1,1),size(data1,3));
output1.local.hub = false(size(data1,1),size(data1,3));
output1.global.clusterCoefficient = nan(size(data1,3),1);
output1.global.pathLength = nan(size(data1,3),1);
output1.global.smallWorldness = nan(size(data1,3),1);
output1.global.smallWorldPropensity = nan(size(data1,3),1);

for mouseInd = 1:size(data1,3)
    outputTemp = mouse.graph.graphTheoryMeasures(data1(:,:,mouseInd));
    output1.local.clusterCoefficient(:,mouseInd) = outputTemp.local.clusterCoefficient;
    output1.local.pathLength(:,mouseInd) = outputTemp.local.pathLength;
    output1.local.strength(:,mouseInd) = outputTemp.local.strength;
    output1.local.betweenness(:,mouseInd) = outputTemp.local.betweenness;
    output1.local.hub(:,mouseInd) = outputTemp.local.hub;
    output1.global.clusterCoefficient(mouseInd) = outputTemp.global.clusterCoefficient;
    output1.global.pathLength(mouseInd) = outputTemp.global.pathLength;
    output1.global.smallWorldness(mouseInd) = outputTemp.global.smallWorldness;
    output1.global.smallWorldPropensity(mouseInd) = outputTemp.global.smallWorldPropensity;
end

output2.local.clusterCoefficient = nan(size(data2,1),size(data2,3));
output2.local.pathLength = nan(size(data2,1),size(data2,3));
output2.local.strength = nan(size(data2,1),size(data2,3));
output2.local.betweenness = nan(size(data2,1),size(data2,3));
output2.local.hub = false(size(data2,1),size(data2,3));
output2.global.clusterCoefficient = nan(size(data2,3),1);
output2.global.pathLength = nan(size(data2,3),1);
output2.global.smallWorldness = nan(size(data2,3),1);
output2.global.smallWorldPropensity = nan(size(data2,3),1);

for mouseInd = 1:size(data2,3)
    outputTemp = mouse.graph.graphTheoryMeasures(data2(:,:,mouseInd));
    output2.local.clusterCoefficient(:,mouseInd) = outputTemp.local.clusterCoefficient;
    output2.local.pathLength(:,mouseInd) = outputTemp.local.pathLength;
    output2.local.strength(:,mouseInd) = outputTemp.local.strength;
    output2.local.betweenness(:,mouseInd) = outputTemp.local.betweenness;
    output2.local.hub(:,mouseInd) = outputTemp.local.hub;
    output2.global.clusterCoefficient(mouseInd) = outputTemp.global.clusterCoefficient;
    output2.global.pathLength(mouseInd) = outputTemp.global.pathLength;
    output2.global.smallWorldness(mouseInd) = outputTemp.global.smallWorldness;
    output2.global.smallWorldPropensity(mouseInd) = outputTemp.global.smallWorldPropensity;
end

%% global plot
% figure('Position',[20 100 1900 450]);
figure('Position',[20 100 550 300]);
s1 = subplot(1,3,1);
test1 = output1.global.clusterCoefficient;
test2 = output2.global.clusterCoefficient;
boxInd = [ones(size(test1)); 2*ones(size(test2))];
H = notBoxPlot([test1; test2],boxInd);
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
set(gca,'XTick',1:2,'XTickLabel',legendStr);
[~,pVal] = ttest2(test1,test2);
text(0.5,0.05,['p = ' num2str(pVal,'%.2g')],'HorizontalAlignment','center','Units','normalized');
title('Cluster coefficient');
yLim = s1.YLim;
set(s1,'YLim',[yLim(1)*0.92 yLim(2)]);
if pVal <= 1E-3
    sigstar({legendStr},1E-3);
elseif pVal <= 1E-2
    sigstar({legendStr},1E-2);
elseif pVal <= 0.05
    sigstar({legendStr},0.05);
else
end

s2 = subplot(1,3,2);
test1 = output1.global.pathLength;
test2 = output2.global.pathLength;
boxInd = [ones(size(test1)); 2*ones(size(test2))];
H = notBoxPlot([test1; test2],boxInd);
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
set(gca,'XTick',1:2,'XTickLabel',legendStr);
[~,pVal] = ttest2(test1,test2);
text(0.5,0.05,['p = ' num2str(pVal,'%.2g')],'HorizontalAlignment','center','Units','normalized');
title('Pathlength');
yLim = s2.YLim;
set(s2,'YLim',[yLim(1)*0.92 yLim(2)]);
if pVal <= 1E-3
    sigstar({legendStr},1E-3);
elseif pVal <= 1E-2
    sigstar({legendStr},1E-2);
elseif pVal <= 0.05
    sigstar({legendStr},0.05);
else
end

s3 = subplot(1,3,3);
test1 = output1.global.smallWorldness;
test2 = output2.global.smallWorldness;
boxInd = [ones(size(test1)); 2*ones(size(test2))];
H = notBoxPlot([test1; test2],boxInd);
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
set(gca,'XTick',1:2,'XTickLabel',legendStr);
[~,pVal] = ttest2(test1,test2);
text(0.5,0.05,['p = ' num2str(pVal,'%.2g')],'HorizontalAlignment','center','Units','normalized');
title('Small-worldness');
yLim = s3.YLim;
set(s3,'YLim',[yLim(1)*0.92 yLim(2)]);
if pVal <= 1E-3
    sigstar({legendStr},1E-3);
elseif pVal <= 1E-2
    sigstar({legendStr},1E-2);
elseif pVal <= 0.05
    sigstar({legendStr},0.05);
else
end

% subplot(1,4,4);
% test1 = output1.global.smallWorldPropensity;
% test2 = output2.global.smallWorldPropensity;
% boxInd = [ones(size(test1)); 2*ones(size(test2))];
% boxplot([test1; test2],boxInd);
% set(gca,'XTick',1:2,'XTickLabel',legendStr);
% [~,pVal] = ttest2(test1,test2);
% if pVal <= 1E-3
%     H=sigstar({legendStr},1E-3);
% elseif pVal <= 1E-2
%     H=sigstar({legendStr},1E-2);
% elseif pVal <= 0.05
%     H=sigstar({legendStr},0.05);
% else
% end
% text(0.5,0.05,['p = ' num2str(pVal,'%.2g')],'HorizontalAlignment','center','Units','normalized');
% title('Small-world Propensity');

%% plot

f1 = figure('Position',[20 500 1900 300]);
% f1 = figure('Position',[50 100 800 700]);
subplot(1,4,1);
y1 = output1.local.pathLength; y2 = output2.local.pathLength;
errorbar(1:numel(roiInd),mean(y1,2),1*std(y1,0,2),'.',...
    'MarkerSize',14);
hold on;
errorbar(1:numel(roiInd),mean(y2,2),1*std(y2,0,2),'.',...
    'MarkerSize',14);
hold off;
title('Pathlength');
set(gca,'XTick',(1:numel(roiInd)));
set(gca,'XTickLabel',roiLabels);
set(gca, 'FontSize', 7);
xtickangle(xRotAngle);
xlim([0.5 numel(roiInd)+0.5]);
ylim([2 12]);
% ylim([2 6]);

subplot(1,4,2);
y1 = output1.local.clusterCoefficient; y2 = output2.local.clusterCoefficient;
errorbar(1:numel(roiInd),mean(y1,2),1*std(y1,0,2),'.',...
    'MarkerSize',14);
hold on;
errorbar(1:numel(roiInd),mean(y2,2),1*std(y2,0,2),'.',...
    'MarkerSize',14);
hold off;
title('Clustering coefficient');
set(gca,'XTick',(1:numel(roiInd)));
set(gca,'XTickLabel',roiLabels);
set(gca, 'FontSize', 7);
xtickangle(xRotAngle);
xlim([0.5 numel(roiInd)+0.5]);
ylim([0.05 0.7]);
% ylim([0.1 0.7]);

subplot(1,4,3);
y1 = output1.local.strength; y2 = output2.local.strength;
errorbar(1:numel(roiInd),mean(y1,2),1*std(y1,0,2),'.',...
    'MarkerSize',14);
hold on;
errorbar(1:numel(roiInd),mean(y2,2),1*std(y2,0,2),'.',...
    'MarkerSize',14);
hold off;
title('Strength');
set(gca,'XTick',(1:numel(roiInd)));
set(gca,'XTickLabel',roiLabels);
set(gca, 'FontSize', 7);
xtickangle(xRotAngle);
xlim([0.5 numel(roiInd)+0.5]);
ylim([1 12]);
% ylim([1 8]);

subplot(1,4,4);
y1 = output1.local.betweenness; y2 = output2.local.betweenness;
errorbar(1:numel(roiInd),mean(y1,2),1*std(y1,0,2),'.',...
    'MarkerSize',14);
hold on;
errorbar(1:numel(roiInd),mean(y2,2),1*std(y2,0,2),'.',...
    'MarkerSize',14);
hold off;
title('Betweenness centrality');
set(gca,'XTick',(1:numel(roiInd)));
set(gca,'XTickLabel',roiLabels);
set(gca, 'FontSize', 7);
xtickangle(xRotAngle);
xlim([0.5 numel(roiInd)+0.5]);
ylim([-10 300]);
% ylim([-10 200]);
% ylim([-10 60]);
legend(legendStr,'Location','northwest');

% subplot(1,3,3);
% y1 = []; y2 = [];
% for i = 1:numel(roiInd)
%     y1 = [y1; smallWorldPropensity{1,i}];
%     y2 = [y2; smallWorldPropensity{2,i}];
% end
% errorbar(1:numel(roiInd),mean(y1,2),1*std(y1,0,2),'.',...
%     'MarkerSize',14);
% hold on;
% errorbar(1:numel(roiInd),mean(y2,2),1*std(y2,0,2),'.',...
%     'MarkerSize',14);
% hold off;
% title('Small-worldness');
% set(gca,'XTick',(1:numel(roiInd)));
% set(gca,'XTickLabel',roiLabels);
% set(gca, 'FontSize', 8);
% xtickangle(xRotAngle);
% xlim([0.5 numel(roiInd)+0.5]);
% ylim([0 7]);


%

figure('Position',[20 100 1900 200]);
subplot(1,4,1);
pval = nan(numel(roiInd),1);
for i = 1:numel(roiInd)
    preStroke = output1.local.pathLength(i,:);
    postStroke = output2.local.pathLength(i,:);
    [~,pval(i)] = ttest2(preStroke,postStroke);
end
pvalLog = log(pval)/log(10);
pthrLog = log(0.05)/log(10);
plot(pvalLog,'o-',...
                'Color',[0 158 169]/255,...
                'LineWidth',1,...
                'MarkerEdgeColor',[0 158 169]/255,...
                'MarkerFaceColor',[0 158 169]/255,...
                'MarkerSize',5);hold on;
plot(repmat(pthrLog,size(pvalLog)),...
                'LineWidth',2,...
                'Color',[193 2 2]/255);
reject = holmBonf(pval);
for i = 1:numel(roiInd)
    if reject(i)
        text(i,-0.5,'*','FontSize',14);
    end
end

hold off;
set(gca,'XTick',(1:numel(roiInd)));
set(gca,'XTickLabel',roiLabels);
set(gca, 'FontSize', 7);

xtickangle(xRotAngle);
xlim([0.5 numel(roiInd)+0.5]);
ylim([-7 0]);
ylabel('p value (log 10)')

subplot(1,4,2);
pval = nan(numel(roiInd),1);
for i = 1:numel(roiInd)
    preStroke = output1.local.clusterCoefficient(i,:);
    postStroke = output2.local.clusterCoefficient(i,:);
    [~,pval(i)] = ttest2(preStroke,postStroke);
end
reject = holmBonf(pval);
pvalLog = log(pval)/log(10);
pthrLog = log(0.05)/log(10);
plot(pvalLog,'o-',...
                'Color',[0 158 169]/255,...
                'LineWidth',1,...
                'MarkerEdgeColor',[0 158 169]/255,...
                'MarkerFaceColor',[0 158 169]/255,...
                'MarkerSize',5);hold on;
plot(repmat(pthrLog,size(pvalLog)),...
                'LineWidth',2,...
                'Color',[193 2 2]/255);
for i = 1:numel(roiInd)
    if reject(i)
        text(i,-0.5,'*','FontSize',14);
    end
end
hold off;
set(gca,'XTick',(1:numel(roiInd)));
set(gca,'XTickLabel',roiLabels);
set(gca, 'FontSize', 7);
xtickangle(xRotAngle);
xlim([0.5 numel(roiInd)+0.5]);
ylim([-7 0]);


subplot(1,4,3);
pval = nan(numel(roiInd),1);
for i = 1:numel(roiInd)
    preStroke = output1.local.strength(i,:);
    postStroke = output2.local.strength(i,:);
    [~,pval(i)] = ttest2(preStroke,postStroke);
end
reject = holmBonf(pval);
pvalLog = log(pval)/log(10);
pthrLog = log(0.05)/log(10);
plot(pvalLog,'o-',...
                'Color',[0 158 169]/255,...
                'LineWidth',1,...
                'MarkerEdgeColor',[0 158 169]/255,...
                'MarkerFaceColor',[0 158 169]/255,...
                'MarkerSize',5);
hold on;
plot(repmat(pthrLog,size(pvalLog)),...
                'LineWidth',2,...
                'Color',[193 2 2]/255);
for i = 1:numel(roiInd)
    if reject(i)
        text(i,-0.5,'*','FontSize',14);
    end
end
hold off;
set(gca,'XTick',(1:numel(roiInd)));
set(gca,'XTickLabel',roiLabels);
set(gca, 'FontSize', 7);
xtickangle(xRotAngle);
xlim([0.5 numel(roiInd)+0.5]);
ylim([-7 0]);

subplot(1,4,4);
pval = nan(numel(roiInd),1);
for i = 1:numel(roiInd)
    preStroke = output1.local.betweenness(i,:);
    postStroke = output2.local.betweenness(i,:);
    [~,pval(i)] = ttest2(preStroke,postStroke);
end
pvalLog = log(pval)/log(10);
pthrLog = log(0.05)/log(10);
plot(pvalLog,'o-',...
                'Color',[0 158 169]/255,...
                'LineWidth',1,...
                'MarkerEdgeColor',[0 158 169]/255,...
                'MarkerFaceColor',[0 158 169]/255,...
                'MarkerSize',5);
hold on;
plot(repmat(pthrLog,size(pvalLog)),...
                'LineWidth',2,...
                'Color',[193 2 2]/255);
reject = holmBonf(pval);
for i = 1:numel(roiInd)
    if reject(i)
        text(i,-0.5,'*','FontSize',14);
    end
end
hold off;
set(gca,'XTick',(1:numel(roiInd)));
set(gca,'XTickLabel',roiLabels);
set(gca, 'FontSize', 7);
xtickangle(xRotAngle);
xlim([0.5 numel(roiInd)+0.5]);
ylim([-7 0]);

%%

load('D:\data\170126\170126-2541_baseline-LandmarksandMask.mat','xform_WL'); % get wl image
load('D:\data\atlas.mat','AtlasSeedsFilled'); % load mask

whiteLight = xform_WL;
mask = AtlasSeedsFilled>0;
blueRedMap = blueWhiteRed(100);

f1 = figure('Position',[100 700 1000 300]);
plotNodeBrain(subplot(1,3,1),whiteLight,mask,seedCenter(roiInd,:),nanmean(output1.local.pathLength,2),[2.5 7]);
plotNodeBrain(subplot(1,3,2),whiteLight,mask,seedCenter(roiInd,:),nanmean(output2.local.pathLength,2),[2.5 7]);
plotNodeBrain(subplot(1,3,3),whiteLight,mask,seedCenter(roiInd,:),...
    nanmean(output2.local.pathLength,2)-nanmean(output1.local.pathLength,2),[-3 3],blueRedMap);

f2 = figure('Position',[100 400 1000 300]);
plotNodeBrain(subplot(1,3,1),whiteLight,mask,seedCenter(roiInd,:),nanmean(output1.local.clusterCoefficient,2),[0.2 0.5]);
plotNodeBrain(subplot(1,3,2),whiteLight,mask,seedCenter(roiInd,:),nanmean(output2.local.clusterCoefficient,2),[0.2 0.5]);
plotNodeBrain(subplot(1,3,3),whiteLight,mask,seedCenter(roiInd,:),...
    nanmean(output2.local.clusterCoefficient,2)-nanmean(output1.local.clusterCoefficient,2),[-0.15 0.15],blueRedMap);

f3 = figure('Position',[100 100 1000 300]);
plotNodeBrain(subplot(1,3,1),whiteLight,mask,seedCenter(roiInd,:),nanmean(output1.local.strength,2),[2 10]);
plotNodeBrain(subplot(1,3,2),whiteLight,mask,seedCenter(roiInd,:),nanmean(output2.local.strength,2),[2 10]);
plotNodeBrain(subplot(1,3,3),whiteLight,mask,seedCenter(roiInd,:),...
    nanmean(output2.local.strength,2)-nanmean(output1.local.strength,2),[-3 3],blueRedMap);