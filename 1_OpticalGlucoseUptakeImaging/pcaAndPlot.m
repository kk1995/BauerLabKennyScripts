function [coeff, coeffDist, score, latent, tsquared, explained, mu] = pcaAndPlot(totalData,mask,pcaFile)
%pcaAndPlot Summary of this function goes here
%   Detailed explanation goes here

% pca
pcaInput = reshape(totalData,size(mask,2)*size(mask,1),[]);
pcaInput = pcaInput(mask,:);
pcaInput = pcaInput';
[coeff, score, latent, tsquared, explained, mu] = pca(pcaInput);

coeffDist = nan(size(mask,2)*size(mask,1),10);
for pcInd = 1:10
    coeffDist(mask,pcInd) = coeff(:,pcInd);
end

% save pca result
save(pcaFile,'coeff','coeffDist','score','latent','tsquared','explained','mu','mask','-v7.3');



end

