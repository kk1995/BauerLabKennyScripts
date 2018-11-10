%% load data

disp('Loading');

saveFolder = '/Users/kenny/Documents/GitHub/BauerLab/data';
saveFile1 = 'HbO_Deborah_gs_OV_n7.mat';
saveFile2 = 'HbO_John_gs_n6.mat';

load(fullfile(saveFolder,saveFile1),'lagMat','mask');
lagMat1 = lagMat;
mask1 = mask;

load(fullfile(saveFolder,saveFile2),'lagMat','mask');
lagMat2 = lagMat;
mask2 = mask;

% stretch the data2 to fit data1
[Xq,Yq] = meshgrid(1:128);
[X,Y] = meshgrid(linspace(1,128,100),linspace(1,128,106));
V = lagMat2(15:120,15:114,:);
% VTemp = nan(size(V,2),size(V,1),size(V,3));
% for i = 1:6
%     VTemp(:,:,i) = squeeze(V(:,:,i))';
% end
lagMat2Temp = nan(128,128,6);
for i = 1:6
    lagMat2Temp(:,:,i) = interp2(X,Y,squeeze(V(:,:,i)),Xq,Yq);
end
lagMat2 = lagMat2Temp;

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

figure('Position',[100 100 550 500]);
imagesc(testMatrix);
colormap('jet');

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

imageMask = double(mean(cat(3,mask1,mask2),3));
imageMask(testMatrix==0) = 0;

disp('Plot');
figure('Position',[100 100 600 500]);
image1 = imagesc(testMatrix,[-3 3]);
set(image1,'AlphaData',imageMask);
colormap('jet');
colorbar();

figure('Position',[100 100 550 500]);
image2 = imagesc(pMat<0.05);
set(image2,'AlphaData',imageMask);
colormap('jet');

plot3Mat = holmBonf(pMat,alpha);
figure('Position',[100 100 550 500]);
image3 = imagesc(plot3Mat);
set(image3,'AlphaData',imageMask);
colormap('jet');

figure('Position',[100 100 600 500]);
image4 = imagesc(nanmean(lagMat2,3) - nanmean(lagMat1,3),[-1 1]);
set(image4,'AlphaData',imageMask);
colormap('jet');
colorbar();

figure('Position',[100 100 600 500]);
image5 = imagesc(sqrt(nanvar(lagMat2,0,3)./size(lagMat2,3) + nanvar(lagMat1,0,3)./size(lagMat1,3)),[0 0.5]);
set(image5,'AlphaData',imageMask);
colormap('jet');
colorbar();