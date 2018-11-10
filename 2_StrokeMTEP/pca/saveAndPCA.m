function [coeffMat,scoreMat,latentMat,explainedMat, iterationsDone] = saveAndPCA(iterations,numComponents)

% dataFile = 'D:\data\StrokeMTEP\PT_Groups_Tad_single.mat';
% metaFile = 'D:\data\StrokeMTEP\shuffleDiffMeta.mat';

dataFile = '/scratch/kk1995/data/strokeMTEP/PT_Groups_Tad_single.mat';
metaFile = '/scratch/kk1995/data/strokeMTEP/shuffleDiffMeta.mat';

% load data and meta

% try loading (might be accessed by another job) until it happens
metaLoaded = false;
dataLoaded = false;
while ~metaLoaded
    try
        load(metaFile); % orderMat, iterInd
        metaLoaded = true;
    catch
        pause(20);
    end
end

while ~dataLoaded
    try
        load(dataFile); % MTEP_PT, Veh_PT
        dataLoaded = true;
    catch
        pause(120);
    end
end

data1 = Veh_PT; clear Veh_PT;
data2 = MTEP_PT; clear MTEP_PT;

disp('data loaded');

itep = logical(diag(ones(size(data1,1),1)));
itep1 = repmat(itep,[1 1 size(data1,3)]);
itep2 = repmat(itep,[1 1 size(data2,3)]);
data1(logical(itep1)) = 0;
data2(logical(itep2)) = 0;
clear itep1; clear itep2;

disp('data preprocessed');

% pool data
dataPool = cat(3,data1,data2);
sampleSize1 = size(data1,3);
sampleSize2 = size(data2,3);
clear data1
clear data2

disp('data pooled');

% delete data pool
% clear dataPool

disp('cleared dataPool');

% do PCA

iterationsDone = [];
coeffMat = [];
scoreMat = [];
latentMat = [];
explainedMat = [];

for iter = 1:numel(iterations)
    disp(['PCA # ' num2str(iter)]);
    order = orderMat(:,iterations(iter));
    diffData = mean(dataPool(:,:,order(sampleSize1+1:sampleSize1+sampleSize2)),3)...
        - mean(dataPool(:,:,order(1:sampleSize1)),3);
    [coeff,score,latent,~,explained] = pca(diffData);
    coeffMat = cat(3,coeffMat,coeff(:,1:numComponents));
    scoreMat = cat(3,scoreMat,score(:,1:numComponents));
    latentMat = [latentMat latent(1:numComponents)];
    explainedMat = [explainedMat explained(1:numComponents)];
    iterationsDone = [iterationsDone iter];
end
end