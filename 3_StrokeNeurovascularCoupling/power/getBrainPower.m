function [f,y] = getBrainPower(data,mask,sR)
%getBrainPower Gets average power of the whole brain
%   data = 3D matrix, last dim being time

data = reshape(data,[],size(data,3));
data = data(mask(:),:);

y = fft(data,[],2);
y = abs(y);
y = nanmean(y,1);
y = squeeze(y);

f = linspace(0,sR,numel(y));
end

