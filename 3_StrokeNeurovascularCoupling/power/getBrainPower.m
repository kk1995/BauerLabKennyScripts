function [f,y] = getBrainPower(data,mask,sR)
%getBrainPower Gets average power of the whole brain
%   data = 3D matrix, last dim being time

data = reshape(data,[],size(data,3));
data = data(mask(:),:);

[y,f] = pwelch(data',sR);
y = nanmean(y,2);
y = squeeze(y);
end

