function [coeffMat,scoreMat,latentMat,explainedMat, iterationsDone] = chpcPCA(dataDir,iterList,numComponents,deleteRaw)
iterationsDone = [];
coeffMat = [];
scoreMat = [];
latentMat = [];
explainedMat = [];

for iter = 1:numel(dataDir)
    if exist(dataDir{iter}, 'file') == 2
        load(dataDir{iter}); % loads diffData of that iteration
        [coeff,score,latent,~,explained] = pca(diffData);
        coeffMat = cat(3,coeffMat,coeff(:,1:numComponents));
        scoreMat = cat(3,scoreMat,score(:,1:numComponents));
        latentMat(:,iter) = latent(1:numComponents);
        explainedMat(:,iter) = explained(1:numComponents);
        iterationsDone = [iterationsDone iter];
        if deleteRaw
            system(['rm ' dataDir{iter}]);
        end
    end
end
latentMat = latentMat(:,iterationsDone);
explainedMat = explainedMat(:,iterationsDone);
iterationsDone = iterList(iterationsDone);
end