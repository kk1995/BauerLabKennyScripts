% Here we try to recreate what PCA does by doing SVD and other steps
% ourselves.

load('sampleData.mat'); % data
% data = n samples x n variables

%% normal PCA
[coeff1, score1, latent1] = pca(data);

%% let's try PCA ourselves using SVD

% get number of samples and variables
sampleNum = size(data,1);
varNum = size(data,2);

% subtract column mean
dataMeanSubtract = bsxfun(@minus,data,nanmean(data,1));

% singular value decomposition
[U,S,V] = svd(dataMeanSubtract);

% eigenvalue decomposition
[V2, D2] = eig(dataMeanSubtract'*dataMeanSubtract);