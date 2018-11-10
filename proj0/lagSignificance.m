group1Name = 'OV';
group2Name = 'OD';

load(['D:\data\Deborah\HbO_Deborah_gs_' group1Name '_n7.mat']);
data1 = lagMat;

load(['D:\data\Deborah\HbO_Deborah_gs_' group2Name '_n7.mat']);
data2 = lagMat;

% get the test statistic

[~,~,~,STATS] = ttest2(data1,data2,'dim',3);
tStat = STATS.tstat;

% find shuffle order

group1Num = size(data1,3);
group2Num = size(data2,3);

% make datapool

dataPool = cat(3,data1,data2);

shuffleOrder1Ind = nchoosek(1:group1Num+group2Num,group1Num);
shuffleNum = size(shuffleOrder1Ind,1);
shuffleOrder1 = false(shuffleNum,group1Num+group2Num);
for i = 1:shuffleNum
    shuffleOrder1(i,shuffleOrder1Ind(i,:)) = true;
end

% get test statistic for each shuffle
disp('shuffle');
shuffledTStat = nan(size(data1,1),size(data1,2),shuffleNum);
for shuffle = 1:shuffleNum
    shuffledData1 = (dataPool(:,:,shuffleOrder1(shuffle,:)));
    shuffledData2 = (dataPool(:,:,~shuffleOrder1(shuffle,:)));
    [~,~,~,STATS] = ttest2(shuffledData1,shuffledData2,'dim',3);
    shuffledTStat(:,:,shuffle) = STATS.tstat;
end

% get the cluster stat
disp('cluster stat');
t_thr = 1.96;
[clusterLoc, clusterP, cluster_t, tDist] = clusterTest(shuffledTStat,tStat,repmat(t_thr,size(data1,1),size(data1,2)));

% plot
fig1 = figure;
matrixSize = [size(data1,1) size(data1,2)];
cMap = blueWhiteRed(100);
imagesc(nanmean(data2,3)-nanmean(data1,3),[-0.5 0.5]);
colormap(cMap);
title([group2Name ' - ' group1Name]); 
curentAxes = fig1.CurrentAxes;
plotCluster(curentAxes,matrixSize,clusterLoc(clusterP < 0.05),clusterP(clusterP < 0.05));