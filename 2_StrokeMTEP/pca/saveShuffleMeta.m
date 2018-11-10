iterInd = 1:10000;
saveMeta = 'D:\data\StrokeMTEP\shuffleDiffMeta.mat';
sampleSize1 = 10;
sampleSize2 = 10;

% create shuffle matrix
orderMat = nan(sampleSize1+sampleSize2,numel(iterInd));
for iter = iterInd
    order = randperm(sampleSize1+sampleSize2);
    orderMat(:,iter==iterInd) = order;
end

% save shuffle matrix
save(saveMeta,'iterInd','orderMat');