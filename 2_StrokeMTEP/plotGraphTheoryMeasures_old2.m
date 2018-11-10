load('D:\data\StrokeMTEP\NodalConnectivity.mat');
xRotAngle = 60;

corrMapAll = [];
D_weiAll = [];
iterNum = 100;

% roiInd = [4:11 13:15 24:31 33:35]; % regions I am interested in showing
% roiInd = [2:20 22:40];
roiInd = [13:20 24:29 33:40];

% cond = 'Veh';
% cond = 'MTEP';

data1 = Veh_PT_Nodal_R_Graph;
data2 = MTEP_PT_Nodal_R_Graph;

% legendStr = {'Vehicle Sham','MTEP Sham'};
% legendStr = {'Vehicle Sham','Vehicle PT'};
% legendStr = {'MTEP Sham','MTEP PT'};
legendStr = {'Vehicle PT','MTEP PT'};
% saveFolder = 'C:\Repositories\GitHub\BauerLab\figures';
% if strcmp(cond,'Veh')
%     data1 = Veh_Sham_Nodal_R;
%     data2 = Veh_PT_Nodal_R;
%     saveFile = 'VehPrePostGraphPThrNodal';
% else
%     data1 = MTEP_Sham_Nodal_R;
%     data2 = MTEP_PT_Nodal_R;
%     saveFile = 'MTEPPrePostGraphPThrNodal';
% end

% limiting data to the roi
data1 = data1(roiInd,roiInd,:);
data2 = data2(roiInd,roiInd,:);

% making sure data are sensible
temp=eye(size(data1,1)); temp = logical(temp);
temp1 = repmat(temp,1,1,size(data1,3));
temp2 = repmat(temp,1,1,size(data2,3));
data1(temp1) = Inf;
data2(temp2) = Inf;

% initialize where the graph theory measures will be saved
pathLength = cell(2,numel(roiInd));
clusterCoeff = cell(2,numel(roiInd));
smallWorldness = cell(2,numel(roiInd));
distAll = cell(2,numel(roiInd));

for strokeStatus = 1:2
    
    if strokeStatus == 1 % pre-stroke
        data = data1;
    else % stroke
        data = data2;
    end
    
    mouseNum = size(data,3);
    nodeNum = size(data,1);
    
    threshold=0.01;
    
    % get correlation map
    if max(data(:))>1 %% convert to Pearson R following Fisher Z
        corrMap=tanh(data);
    end
    temp=eye(size(corrMap,1));
    temp = repmat(temp,1,1,size(data,3));
    idx=find(temp==1);
    corrMap(idx)=1;
    corrMap(corrMap<threshold)=0; % threshold
    
    corrMapAll = cat(3,corrMapAll,mean(corrMap,3));
    
    % get random correlation map
    corrMapRand = [];
    for mouse = 1:mouseNum
        corrMapMouse = squeeze(corrMap(:,:,mouse));
        corrMapRandMouse = [];
        for iter = 1:iterNum
            corrMapRand_iter = corrMapMouse(randperm(numel(corrMapMouse)));
            corrMapRand_iter = reshape(corrMapRand_iter,size(corrMapMouse));
            corrMapRandMouse = cat(3,corrMapRandMouse,corrMapRand_iter);
        end
        corrMapRand = cat(3,corrMapRand,mean(corrMapRandMouse,3));
    end
    
    % initialize graph theory values
    pathLen_g = nan(nodeNum,mouseNum);
    pathLen_rand = nan(nodeNum,mouseNum);
    C_g = nan(nodeNum,mouseNum);
    C_rand = nan(nodeNum,mouseNum);
    
    for mouse = 1:mouseNum
        %% Characteristic Path
        [pathLen_g(:,mouse), distance] = corr2pathLen(corrMap(:,:,mouse));
        pathLen_rand(:,mouse) = corr2pathLen(corrMapRand(:,:,mouse));
        
        %% Clustering coefficient
        C_g(:,mouse) = clustering_coef_wu(squeeze(corrMap(:,:,mouse)));
        C_rand(:,mouse) = clustering_coef_wu(squeeze(corrMapRand(:,:,mouse)));
    end
    
    %% Small worldness
    smallWorld = (C_g./C_rand)./(pathLen_g./pathLen_rand);
    
    %% save
    
    for i = 1:numel(roiInd)
        pathLength{strokeStatus,i} = pathLen_g(i,:);
        clusterCoeff{strokeStatus,i} = C_g(i,:);
        smallWorldness{strokeStatus,i} = smallWorld(i,:);
        distAll{strokeStatus,i} = distance(i,:);
    end
    
    
end

roiLabels = seednames(roiInd);

%% save
% save(['D:\data\StrokeMTEP\graphTheoryMeasures_' cond '.mat'],'roiLabels','pathLength','clusterCoeff','smallWorldness');

%% plot

f1 = figure('Position',[50 100 1800 400]);
subplot(1,3,1);
y1 = []; y2 = [];
for i = 1:numel(roiInd)
    y1 = [y1; pathLength{1,i}];
    y2 = [y2; pathLength{2,i}];
end
errorbar(1:numel(roiInd),mean(y1,2),1*std(y1,0,2),'.',...
    'MarkerSize',14);
hold on;
errorbar(1:numel(roiInd),mean(y2,2),1*std(y2,0,2),'.',...
    'MarkerSize',14);
hold off;
title('Pathlength');
set(gca,'XTick',(1:numel(roiInd)));
set(gca,'XTickLabel',roiLabels);
set(gca, 'FontSize', 8);
xtickangle(xRotAngle);
xlim([0.5 numel(roiInd)+0.5]);
ylim([3 18]);

subplot(1,3,2);
y1 = []; y2 = [];
for i = 1:numel(roiInd)
    y1 = [y1; clusterCoeff{1,i}];
    y2 = [y2; clusterCoeff{2,i}];
end
errorbar(1:numel(roiInd),mean(y1,2),1*std(y1,0,2),'.',...
    'MarkerSize',14);
hold on;
errorbar(1:numel(roiInd),mean(y2,2),1*std(y2,0,2),'.',...
    'MarkerSize',14);
hold off;
title('Clustering coefficient');
set(gca,'XTick',(1:numel(roiInd)));
set(gca,'XTickLabel',roiLabels);
set(gca, 'FontSize', 8);
xtickangle(xRotAngle);
xlim([0.5 numel(roiInd)+0.5]);
ylim([0 0.7]);

subplot(1,3,3);
y1 = []; y2 = [];
for i = 1:numel(roiInd)
    y1 = [y1; smallWorldness{1,i}];
    y2 = [y2; smallWorldness{2,i}];
end
errorbar(1:numel(roiInd),mean(y1,2),1*std(y1,0,2),'.',...
    'MarkerSize',14);
hold on;
errorbar(1:numel(roiInd),mean(y2,2),1*std(y2,0,2),'.',...
    'MarkerSize',14);
hold off;
title('Small-worldness');
set(gca,'XTick',(1:numel(roiInd)));
set(gca,'XTickLabel',roiLabels);
set(gca, 'FontSize', 8);
xtickangle(xRotAngle);
xlim([0.5 numel(roiInd)+0.5]);
ylim([0 7]);
legend(legendStr);

%%

figure('Position',[50 100 1800 200]);
subplot(1,3,1);
pval = nan(numel(roiInd),1);
for i = 1:numel(roiInd)
    preStroke = pathLength{1,i};
    postStroke = pathLength{2,i};
    [~,pval(i)] = ttest2(preStroke,postStroke);
end
plot(pval,'o-');
hold on;
plot(repmat(0.05,size(pval)));
reject = holmBonf(pval);
for i = 1:numel(roiInd)
    if reject(i)
        text(i,0.8,'*');
    end
end

hold off;
set(gca,'XTick',(1:numel(roiInd)));
set(gca,'XTickLabel',roiLabels);
set(gca, 'FontSize', 8);

xtickangle(xRotAngle);
xlim([0.5 numel(roiInd)+0.5]);
ylim([0 1]);

subplot(1,3,2);
pval = nan(numel(roiInd),1);
for i = 1:numel(roiInd)
    preStroke = clusterCoeff{1,i};
    postStroke = clusterCoeff{2,i};
    [~,pval(i)] = ttest2(preStroke,postStroke);
end
plot(pval,'o-');
hold on;
plot(repmat(0.05,size(pval)));
reject = holmBonf(pval);
for i = 1:numel(roiInd)
    if reject(i)
        text(i,0.8,'*');
    end
end
hold off;
set(gca,'XTick',(1:numel(roiInd)));
set(gca,'XTickLabel',roiLabels);
set(gca, 'FontSize', 8);
xtickangle(xRotAngle);
xlim([0.5 numel(roiInd)+0.5]);
ylim([0 1]);

subplot(1,3,3);
pval = nan(numel(roiInd),1);
for i = 1:numel(roiInd)
    preStroke = smallWorldness{1,i};
    postStroke = smallWorldness{2,i};
    [~,pval(i)] = ttest2(preStroke,postStroke);
end
plot(pval,'o-');
hold on;
plot(repmat(0.05,size(pval)));
reject = holmBonf(pval);
for i = 1:numel(roiInd)
    if reject(i)
        text(i,0.8,'*');
    end
end
hold off;
set(gca,'XTick',(1:numel(roiInd)));
set(gca,'XTickLabel',roiLabels);
set(gca, 'FontSize', 8);
xtickangle(xRotAngle);
xlim([0.5 numel(roiInd)+0.5]);
ylim([0 1]);
% temp=logical(eye(size(sigCon,1)));
% sigCon(temp) = false;

% customCMap = blueWhiteRed(100);

% figure;
% s4 = subplot(2,3,4);
% s4 = sigImagesc(s4,data1,data2,roiLabels,[-1 1]);
% title('Connectivity diff (post-pre)');
% 
% s5 = subplot(2,3,5);
% s5 = sigImagesc(s5,tanh(data1),tanh(data2),roiLabels,[-1 1]);
% title('Correlation diff (post-pre)');
% 
% s6 = subplot(2,3,6);
% s6 = sigImagesc(s6,distAll{1},distAll{2},roiLabels,[-3 3]);
% title('Weighted distance (post-pre)');

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
