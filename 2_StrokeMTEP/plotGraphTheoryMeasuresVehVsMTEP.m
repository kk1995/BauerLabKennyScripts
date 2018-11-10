load('D:\data\StrokeMTEP\MTEP_VehData.mat');
xRotAngle = 60;

corrMapAll = [];
D_weiAll = [];
iterNum = 100;
% roiInd = 1:40;
roiInd = [4:11 13:15 24:31 33:35]; % regions I am interested in showing

cond = 'Post';


%% save
load('D:\data\StrokeMTEP\graphTheoryMeasures_Veh.mat');
pathLenVeh = pathLength(2,roiInd);
clusterCoeffVeh = clusterCoeff(2,roiInd);
smallWorldnessVeh = smallWorldness(2,roiInd);

load('D:\data\StrokeMTEP\graphTheoryMeasures_MTEP.mat');
pathLenMTEP = pathLength(2,roiInd);
clusterCoeffMTEP = clusterCoeff(2,roiInd);
smallWorldnessMTEP = smallWorldness(2,roiInd);

%% plot

% f1 = figure('Position',[50 100 1800 400]);
figure('Position',[50 100 500 400]);
% subplot(1,3,1);
y1 = []; y2 = [];
for i = 1:numel(roiInd)
    y1 = [y1; pathLenVeh{i}];
    y2 = [y2; pathLenMTEP{i}];
end
errorbar(1:numel(roiInd),mean(y1,2),1*std(y1,0,2),'.',...
    'MarkerSize',14);
hold on;
errorbar(1:numel(roiInd),mean(y2,2),1*std(y2,0,2),'.',...
    'MarkerSize',14);
hold off;
title('Pathlength');
set(gca,'XTick',(1:numel(roiInd)));
set(gca,'XTickLabel',ROI40labels(roiInd));
set(gca, 'FontSize', 9);
xtickangle(xRotAngle);
xlim([0.5 numel(roiInd)+0.5]);
ylim([2 6]);

figure('Position',[50 100 500 400]);
% subplot(1,3,2);
y1 = []; y2 = [];
for i = 1:numel(roiInd)
    y1 = [y1; clusterCoeffVeh{i}];
    y2 = [y2; clusterCoeffMTEP{i}];
end
errorbar(1:numel(roiInd),mean(y1,2),1*std(y1,0,2),'.',...
    'MarkerSize',14);
hold on;
errorbar(1:numel(roiInd),mean(y2,2),1*std(y2,0,2),'.',...
    'MarkerSize',14);
hold off;
title('Clustering coefficient');
set(gca,'XTick',(1:numel(roiInd)));
set(gca,'XTickLabel',ROI40labels(roiInd));
set(gca, 'FontSize', 9);
xtickangle(xRotAngle);
xlim([0.5 numel(roiInd)+0.5]);
ylim([0.1 0.55]);

figure('Position',[50 100 500 400]);
% subplot(1,3,3);
y1 = []; y2 = [];
for i = 1:numel(roiInd)
    y1 = [y1; smallWorldnessVeh{i}];
    y2 = [y2; smallWorldnessMTEP{i}];
end
errorbar(1:numel(roiInd),mean(y1,2),1*std(y1,0,2),'.',...
    'MarkerSize',14);
hold on;
errorbar(1:numel(roiInd),mean(y2,2),1*std(y2,0,2),'.',...
    'MarkerSize',14);
hold off;
title('Small-worldness');
set(gca,'XTick',(1:numel(roiInd)));
set(gca,'XTickLabel',ROI40labels(roiInd));
set(gca, 'FontSize', 9);
xtickangle(xRotAngle);
xlim([0.5 numel(roiInd)+0.5]);
ylim([0.5 5]);

legend('Veh','MTEP');

%%

% figure('Position',[50 100 1800 200]);
figure('Position',[50 100 500 200]);
% subplot(1,3,1);
pval = nan(numel(roiInd),1);
for i = 1:numel(roiInd)
    preStroke = pathLenVeh{i};
    postStroke = pathLenMTEP{i};
    [~,pval(i)] = ttest2(preStroke,postStroke);
end
plot(pval,'o-');
hold on;
plot(repmat(0.05,size(pval)));
hold off;
set(gca,'XTick',(1:numel(roiInd)));
set(gca,'XTickLabel',ROI40labels(roiInd));
xtickangle(xRotAngle);
xlim([0.5 numel(roiInd)+0.5]);
ylim([0 1]);

figure('Position',[50 100 500 200]);
% subplot(1,3,2);
pval = nan(numel(roiInd),1);
for i = 1:numel(roiInd)
    preStroke = clusterCoeffVeh{i};
    postStroke = clusterCoeffMTEP{i};
    [~,pval(i)] = ttest2(preStroke,postStroke);
end
plot(pval,'o-');
hold on;
plot(repmat(0.05,size(pval)));
hold off;
set(gca,'XTick',(1:numel(roiInd)));
set(gca,'XTickLabel',ROI40labels(roiInd));
xtickangle(xRotAngle);
xlim([0.5 numel(roiInd)+0.5]);
ylim([0 1]);

figure('Position',[50 100 500 200]);
% subplot(1,3,3);
pval = nan(numel(roiInd),1);
for i = 1:numel(roiInd)
    preStroke = smallWorldnessVeh{i};
    postStroke = smallWorldnessMTEP{i};
    [~,pval(i)] = ttest2(preStroke,postStroke);
end
plot(pval,'o-');
hold on;
plot(repmat(0.05,size(pval)));
hold off;
set(gca,'XTick',(1:numel(roiInd)));
set(gca,'XTickLabel',ROI40labels(roiInd));
xtickangle(xRotAngle);
xlim([0.5 numel(roiInd)+0.5]);
ylim([0 1]);
% temp=logical(eye(size(sigCon,1)));
% sigCon(temp) = false;

% customCMap = blueWhiteRed(100);

% s4 = subplot(2,3,4);
% s4 = sigImagesc(s4,data1,data2,ROI40labels,[-1 1]);
% title('Connectivity diff (post-pre)');
%
% s5 = subplot(2,3,5);
% s5 = sigImagesc(s5,tanh(data1),tanh(data2),ROI40labels,[-1 1]);
% title('Correlation diff (post-pre)');
%
% s6 = subplot(2,3,6);
% s6 = sigImagesc(s6,distAll{1},distAll{2},ROI40labels,[-3 3]);
% title('Weighted distance (post-pre)');
%
% saveHighRes(f1,saveFolder,saveFile,{'fig','jpg'});

% s4 = subplot(2,3,4);
% connectivityDiff = nanmean(data2,3) - nanmean(data1,3);
% temp=logical(eye(size(connectivityDiff,1)));
% connectivityDiff(temp) = 0;
% connectivityDiff(~sigCon) = nan;
% imAlpha=ones(size(connectivityDiff));
% imAlpha(isnan(connectivityDiff))=0;
% imagesc(connectivityDiff,'AlphaData',imAlpha,[-1 1]);
% set(gca,'color',0.5*[1 1 1]);
% xtickangle(xRotAngle);
% colormap(customCMap);
% s4Pos = get(s4,'position');
% colorbar;
% set(s4,'Position',s4Pos);
% title('Connectivity diff (post-pre)');
% set(gca,'XTick',(0.5:39.5));
% set(gca,'YTick',(1:40));
% set(gca,'XTickLabel',ROI40labels)
% set(gca,'YTickLabel',ROI40labels)
% set(gca,'TickLength',[0 0])
% set(gca, 'FontSize', 7);
% xlim([0.5 40.5]);
% ylim([0.5 40.5]);

% s5 = subplot(2,3,5);
% imagesc(corrMapAll(:,:,2) - corrMapAll(:,:,1),[-1 1]);
% xtickangle(xRotAngle);
% colormap(customCMap);
% s5Pos = get(s5,'position');
% colorbar;
% set(s5,'Position',s5Pos);
% title('Correlation diff (post-pre)');
% set(gca,'XTick',(0.5:39.5));
% set(gca,'YTick',(1:40));
% set(gca,'XTickLabel',ROI40labels)
% set(gca,'YTickLabel',ROI40labels)
% set(gca,'TickLength',[0 0])
% set(gca, 'FontSize', 7);
% xlim([0.5 40.5]);
% ylim([0.5 40.5]);
%
% s6 = subplot(2,3,6);
% imagesc(mean(distAll{2},3) - mean(distAll{1},3),[-3 3]);
% xtickangle(xRotAngle);
% colormap(customCMap);
% s6Pos = get(s6,'position');
% colorbar;
% set(s6,'Position',s6Pos);
% title('Weighted distance (post-pre)');
% set(gca,'XTick',(0.5:39.5));
% set(gca,'YTick',(1:40));
% set(gca,'XTickLabel',ROI40labels)
% set(gca,'YTickLabel',ROI40labels)
% set(gca,'TickLength',[0 0])
% set(gca, 'FontSize', 7);
% xlim([0.5 40.5]);
% ylim([0.5 40.5]);
