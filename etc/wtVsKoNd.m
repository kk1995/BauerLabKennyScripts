load('K:\BmalKOvsWTNodeDegree_180205.mat');
%%
iterNum = 400;
condition = 1;
saveFolder = 'K:\';
if condition == 1
    saveFile = fullfile(saveFolder,'booleanNDClusters_NewAnalysis.mat');
elseif condition == 2
    saveFile = fullfile(saveFolder,'weightedNDClusters_NewAnalysis.mat');
else
end

%% get null matrix

disp('Making null matrix');

lagMat1 = squeeze(KO_ND(:,:,condition,:));
lagMat2 = squeeze(WT_ND(:,:,condition,:));

tThr = nan(size(lagMat1,1),size(lagMat1,2));
alpha = 0.05;

for y = 1:size(lagMat1,1)
    for x = 1:size(lagMat1,2)
        df = size(lagMat1,3)+size(lagMat2,3)-2;
        tThr(y,x) = tinv(1-(alpha/2),df);
    end
end

poolData = cat(3,lagMat1,lagMat2);
group1Size = size(lagMat1,3);
group2Size = size(lagMat2,3);
nullGroup1 = nchoosek(1:group1Size+group2Size,group1Size);
nullMatrix = nan(size(lagMat1,1),size(lagMat1,2),size(nullGroup1,1));

for iter = 1:size(nullGroup1,1)
    disp(['  Iteration # ' num2str(iter) '/' num2str(size(nullGroup1,1))]);
    nullMat1 = poolData(:,:,nullGroup1(iter,:));
    nullGroup2 = 1:group1Size+group2Size;
    nullGroup2(nullGroup1(iter,:)) = [];
    nullMat2 = poolData(:,:,nullGroup2);
    
    for y = 1:size(lagMat1,1)
        for x = 1:size(lagMat1,2)
            
            nullData1 = nullMat1(y,x,:);
            nullData2 = nullMat2(y,x,:);
            
            if numel(nullData1) > 1 && numel(nullData2) > 1
                [H,P,CI,STATS] = ttest2(nullData2,nullData1);
                nullMatrix(y,x,iter) = STATS.tstat;
            end
        end
    end
end

testMatrix = nan(size(lagMat1,1),size(lagMat1,2));
for y = 1:size(lagMat1,1)
    for x = 1:size(lagMat1,2)
        
        if numel(nullData1) > 1 && numel(nullData2) > 1
            [H,P,CI,STATS] = ttest2(lagMat2(y,x,:),lagMat1(y,x,:));
            testMatrix(y,x) = STATS.tstat;
        end
    end
end


[clusterLoc, clusterP, clusterT, tDist] = clusterTest(nullMatrix,testMatrix,tThr);

%% save

save(saveFile,'nullMatrix','testMatrix','clusterLoc','clusterP','clusterT','tDist');


%% plot
% imageMask = xform_isbrain;
imageMask = symisbrainall;
imageMask(testMatrix==0) = 0;

% plot
matrixSize = size(testMatrix);
fig1 = figure('Position',[100 100 600 500]);
cMap = blueWhiteRed(100);
colormap(cMap);
imagesc(testMatrix,'AlphaData',imageMask,[-4 4]);
curentAxes = fig1.CurrentAxes;
plotCluster(curentAxes,matrixSize,clusterLoc(clusterP < 0.05),clusterP(clusterP < 0.05));
colorbar;

% 
% figure('Position',[100 100 600 500]);
% imagesc(testMatrix,'AlphaData',imageMask,[0 4]);
% colormap('jet');
% colorbar;
% 
% sigMat = zeros(size(lagMat1,1),size(lagMat1,2));
% for cluster = 1:numel(clusterLoc)
%     if clusterP(cluster) < alpha
%         sigMat(clusterLoc{cluster}) = 1;
%     end
% end
% 
% 
% 
% figure('Position',[100 100 550 500]);
% image1 = imagesc(sigMat,[0 1]);
% set(image1,'AlphaData',imageMask);
% colormap('jet');
% 
% hold on;
% 
% clusterLoc2D = nan(numel(clusterLoc),2);
% for cluster = 1:numel(clusterLoc)
%     [clusterRow,clusterCol] = ind2D(clusterLoc{cluster},size(testMatrix));
%     clusterLoc2D(cluster,:) = [mean(clusterRow) mean(clusterCol)];
% end
% 
% for cluster = 1:numel(clusterLoc)
%     if clusterP(cluster) < alpha
%         text(clusterLoc2D(cluster,2),clusterLoc2D(cluster,1),['p= ' num2str(clusterP(cluster))]);
%     end
% end
% 
% hold off;