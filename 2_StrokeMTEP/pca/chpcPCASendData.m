function [coeffMat,scoreMat,latentMat,explainedMat, iterationsDone] = chpcPCASendData(diffMat,iterList,numComponents)
iterationsDone = [];
coeffMat = [];
scoreMat = [];
latentMat = [];
explainedMat = [];

for iter = 1:size(diffMat,3)
    [coeff,score,latent,~,explained] = pca(squeeze(diffMat(:,:,iter)));
    coeffMat = cat(3,coeffMat,coeff(:,1:numComponents));
    scoreMat = cat(3,scoreMat,score(:,1:numComponents));
    latentMat(:,iter) = latent(1:numComponents);
    explainedMat(:,iter) = explained(1:numComponents);
    iterationsDone = [iterationsDone iterList(iter)];
end
end