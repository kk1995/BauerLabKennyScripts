%% load data

disp('Loading');

saveFolder = '/Users/kenny/Documents/GitHub/BauerLab/data';
group1 = 'OV';
group2 = 'OD';
saveFile1 = ['HbO_Deborah_gs_' group1 '_n7'];
saveFile2 = ['HbO_Deborah_gs_' group2 '_n7'];

load(fullfile(saveFolder,saveFile1),'lagMat','mask');
lagMat1 = lagMat;
mask1 = mask;

load(fullfile(saveFolder,saveFile2),'lagMat','mask');
lagMat2 = lagMat;
mask2 = mask;

%% get threshold

disp('Getting threshold');

tThr = nan(size(lagMat1,1),size(lagMat1,2));
alpha = 0.05;

for y = 1:size(lagMat1,1)
    for x = 1:size(lagMat1,2)
        df = sum(mask2(y,x,:))+sum(mask1(y,x,:)) - 2;
        tThr(y,x) = tinv(1-(alpha/2),df);
    end
end

%% get test matrix

disp('Making test matrix');

testMatrix = zeros(size(lagMat1,1),size(lagMat1,1));
pMat = nan(size(testMatrix));
for y = 1:size(lagMat1,1)
    for x = 1:size(lagMat1,2)
        data1 = lagMat1(y,x,:); data1 = data1(logical(mask1(y,x,:)));
        data2 = lagMat2(y,x,:); data2 = data2(logical(mask2(y,x,:)));
        
        if numel(data1) > 1 && numel(data2) > 1
            [H,pMat(y,x),CI,STATS] = ttest2(data2,data1);
            testMatrix(y,x) = STATS.tstat;
        end
    end
end

%% get null matrix

disp('Making null matrix');

iterNum = 200;

poolData = cat(3,lagMat1,lagMat2);
poolMask = cat(3,mask1,mask2);
group1Size = size(lagMat1,3);
group2Size = size(lagMat2,3);
nullMatrix = nan(size(lagMat1,1),size(lagMat1,2),iterNum);

for iter = 1:iterNum
    disp(['  Iteration # ' num2str(iter) '/' num2str(iterNum)]);
    nullOrder = randperm(size(poolData,3));
    nullMat1 = poolData(:,:,nullOrder(1:group1Size));
    nullMat2 = poolData(:,:,nullOrder(group1Size+1:group1Size+group2Size));
    
    iterMask1 = poolMask(:,:,nullOrder(1:group1Size));
    iterMask2 = poolMask(:,:,nullOrder(group1Size+1:group1Size+group2Size));
    
    for y = 1:size(lagMat1,1)
        for x = 1:size(lagMat1,2)
            nullData1 = nullMat1(y,x,:); nullData1 = nullData1(logical(iterMask1(y,x,:)));
            nullData2 = nullMat2(y,x,:); nullData2 = nullData2(logical(iterMask2(y,x,:)));
            
            if numel(nullData1) > 1 && numel(nullData2) > 1
                [H,P,CI,STATS] = ttest2(nullData2,nullData1);
                nullMatrix(y,x,iter) = STATS.tstat;
            end
        end
    end
end


%% cluster stat

disp('Cluster stat');

[clusterLoc, clusterP, clusterT, tDist] = clusterTest(nullMatrix,testMatrix,tThr);

clusterLoc2D = nan(numel(clusterLoc),2);
for cluster = 1:numel(clusterLoc)
    [clusterRow,clusterCol] = ind2D(clusterLoc{cluster},size(testMatrix));
    clusterLoc2D(cluster,:) = [mean(clusterRow) mean(clusterCol)];
end

%% plot

sigMat = zeros(size(lagMat1,1),size(lagMat1,2));
for cluster = 1:numel(clusterLoc)
%     if clusterP(cluster) < alpha
        sigMat(clusterLoc{cluster}) = 1;
%     end
end

imageMask = double(mean(cat(3,mask1,mask2),3));
imageMask(testMatrix==0) = 0;

figure('Position',[100 100 550 500]);
image1 = imagesc(sigMat,[0 1]);
set(image1,'AlphaData',imageMask);
colormap('jet');

hold on;

for cluster = 1:numel(clusterLoc)
    text(clusterLoc2D(cluster,2),clusterLoc2D(cluster,1),['p= ' num2str(clusterP(cluster))]);
end

hold off;

%% plot
% 
% imageMask = double(mean(cat(3,mask1,mask2),3));
% imageMask(testMatrix==0) = 0;
% 
% disp('Plot');
% figure('Position',[100 100 600 500]);
% image1 = imagesc(testMatrix,[-3 3]);
% set(image1,'AlphaData',imageMask);
% colormap('jet');
% colorbar();
% 
% figure('Position',[100 100 550 500]);
% image2 = imagesc(pMat<0.05);
% set(image2,'AlphaData',imageMask);
% colormap('jet');
% 
% figure('Position',[100 100 550 500]);
% image3 = imagesc(sigMat);
% set(image3,'AlphaData',imageMask);
% colormap('jet');
% 
% figure('Position',[100 100 600 500]);
% image4 = imagesc(nanmean(lagMat2,3) - nanmean(lagMat1,3),[-1 1]);
% set(image4,'AlphaData',imageMask);
% colormap('jet');
% colorbar();
% 
% figure('Position',[100 100 600 500]);
% image5 = imagesc(sqrt(nanvar(lagMat2,0,3)./size(lagMat2,3) + nanvar(lagMat1,0,3)./size(lagMat1,3)),[0 0.5]);
% set(image5,'AlphaData',imageMask);
% colormap('jet');
% colorbar();