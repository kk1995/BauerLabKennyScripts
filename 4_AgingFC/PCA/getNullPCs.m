% here, we are going to create 128^4 x 14 matrix. By doing this, variance
% between groups will be better understood.

saveFile = "L:\ProcessedData\yvNullPC_latents.mat";

[lowerInd, upperInd] = mouse.conn.getTriangleInd(128^2);
input = [];
for i = 1:7
    disp(['Mouse # ' num2str(i)]);
    
    load(strcat("L:\ProcessedData\deborah\FC-YV",num2str(i),".mat"));
    fcMap = single(fcMap(lowerInd));
    input = cat(1,input,fcMap);
    
    clear fcMap;
end

badInd = sum(isnan(input),1) > 0;
goodMatrixInd = lowerInd(~badInd);
goodMatrixIndUpper = upperInd(~badInd);

input = input(:,~badInd);

%% combinations

combinations = nchoosek(1:7,4);

latentComb = zeros(size(combinations,1),3);

for i = 1:size(combinations,1)
    disp(['PCA # ' num2str(i)]);
    combInput = input(combinations(i,:),:);
    [coeff, score, latent, tsquared, explained] = pca(combInput);
    latentComb(i,:) = latent;
end

save(saveFile,'latentComb','-v7.3');

%% compare with experimental
% we choose random 4 mice from ov + yv group 21 times and find the latent

saveFile = "L:\ProcessedData\ov-yvPC_latents.mat";

[lowerInd, upperInd] = mouse.conn.getTriangleInd(128^2);
input = [];
for i = 1:7
    disp(['Mouse # ' num2str(i)]);
    
    load(strcat("L:\ProcessedData\deborah\FC-YV",num2str(i),".mat"));
    fcMap = single(fcMap(lowerInd));
    input = cat(1,input,fcMap);
    
    clear fcMap;
    
    load(strcat("L:\ProcessedData\deborah\FC-OV",num2str(i),".mat"));
    fcMap = single(fcMap(lowerInd));
    input = cat(1,input,fcMap);
    
    clear fcMap;
end

badInd = sum(isnan(input),1) > 0;
goodMatrixInd = lowerInd(~badInd);
goodMatrixIndUpper = upperInd(~badInd);

input = input(:,~badInd);

combinations1 = nchoosek(1:2:13,2);
combinations1 = combinations1(randperm(size(combinations1,1)),:);
combinations2 = nchoosek(2:2:14,2);
combinations2 = combinations2(randperm(size(combinations2,1)),:);

combinations = [combinations1 combinations2];

latentComb = zeros(size(combinations,1),3);

for i = 1:size(combinations,1)
    disp(['PCA # ' num2str(i)]);
    combInput = input(combinations(i,:),:);
    [coeff, score, latent, tsquared, explained] = pca(combInput);
    latentComb(i,:) = latent;
end

save(saveFile,'latentComb','-v7.3');

%% compare with experimental 2
% we choose random 4 mice from ov + od group 21 times and find the latent

saveFile = "L:\ProcessedData\od-ovPC_latents.mat";

[lowerInd, upperInd] = mouse.conn.getTriangleInd(128^2);
input = [];
for i = 1:7
    disp(['Mouse # ' num2str(i)]);
    
    load(strcat("L:\ProcessedData\deborah\FC-OV",num2str(i),".mat"));
    fcMap = single(fcMap(lowerInd));
    input = cat(1,input,fcMap);
    
    clear fcMap;
    
    load(strcat("L:\ProcessedData\deborah\FC-OD",num2str(i),".mat"));
    fcMap = single(fcMap(lowerInd));
    input = cat(1,input,fcMap);
    
    clear fcMap;
end

badInd = sum(isnan(input),1) > 0;
goodMatrixInd = lowerInd(~badInd);
goodMatrixIndUpper = upperInd(~badInd);

input = input(:,~badInd);

combinations1 = nchoosek(1:2:13,2);
combinations1 = combinations1(randperm(size(combinations1,1)),:);
combinations2 = nchoosek(2:2:14,2);
combinations2 = combinations2(randperm(size(combinations2,1)),:);

combinations = [combinations1 combinations2];

latentComb = zeros(size(combinations,1),3);

for i = 1:size(combinations,1)
    disp(['PCA # ' num2str(i)]);
    combInput = input(combinations(i,:),:);
    [coeff, score, latent, tsquared, explained] = pca(combInput);
    latentComb(i,:) = latent;
end

save(saveFile,'latentComb','-v7.3');

%% compare with experimental 2
% we choose random 4 mice from ov + od group 21 times and find the latent

saveFile = "L:\ProcessedData\od-yvPC_latents.mat";

[lowerInd, upperInd] = mouse.conn.getTriangleInd(128^2);
input = [];
for i = 1:7
    disp(['Mouse # ' num2str(i)]);
    
    load(strcat("L:\ProcessedData\deborah\FC-YV",num2str(i),".mat"));
    fcMap = single(fcMap(lowerInd));
    input = cat(1,input,fcMap);
    
    clear fcMap;
    
    load(strcat("L:\ProcessedData\deborah\FC-OD",num2str(i),".mat"));
    fcMap = single(fcMap(lowerInd));
    input = cat(1,input,fcMap);
    
    clear fcMap;
end

badInd = sum(isnan(input),1) > 0;
goodMatrixInd = lowerInd(~badInd);
goodMatrixIndUpper = upperInd(~badInd);

input = input(:,~badInd);

combinations1 = nchoosek(1:2:13,2);
combinations1 = combinations1(randperm(size(combinations1,1)),:);
combinations2 = nchoosek(2:2:14,2);
combinations2 = combinations2(randperm(size(combinations2,1)),:);

combinations = [combinations1 combinations2];

latentComb = zeros(size(combinations,1),3);

for i = 1:size(combinations,1)
    disp(['PCA # ' num2str(i)]);
    combInput = input(combinations(i,:),:);
    [coeff, score, latent, tsquared, explained] = pca(combInput);
    latentComb(i,:) = latent;
end

save(saveFile,'latentComb','-v7.3');