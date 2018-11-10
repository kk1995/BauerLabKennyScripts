function [gs, rawL, rawR] = infarctData(data,mask,infarctInd)
%   data = (y) x (x) x (species) x (time)
%   mask = (y) x (x) logical
%   infarctInd = (y) x (x) logical showing where infarct is

originalSize = size(data);

data = reshape(data,prod(originalSize(1:2)),originalSize(3),originalSize(4));
% data = data(infarctInd(:).*mask(:),:,:);

% get mirror ind
infarctMirrorInd = fliplr(infarctInd);

% get gs
gs = squeeze(nanmean(data(mask(:),:,:)));
rawL = data(infarctInd(:) & mask(:),:,:);
rawR = data(infarctMirrorInd(:) & mask(:),:,:);


end