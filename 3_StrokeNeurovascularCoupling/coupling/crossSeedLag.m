function [lagData,ampData] = crossSeedLag(data1,data2,roiInd,varargin)
%crossSeedLag Gets the lag data from data1 and data2, with only data1 in
%seed considered.
%   Example: [lagData,ampData] = crossSeedLag(data1,data2,roiInd)
%   Inputs:
%       data1 = (some spatial dim) x time (fine as long as last dim is
%       time)
%       data2 = (some spatial dim) x time
%       roiInd = spatial indices of data1 to be considered
%       validInd (optional)
%   If positive, data1's roi data lags behind data2

quadFitUse = true;
positiveSignOnly = true;

if numel(varargin) < 1
    validInd = [];
else
    validInd = varargin{1};
end

dataSize = size(data1);

lagData = nan(dataSize(1:end-1));
ampData = nan(dataSize(1:end-1));

data1 = reshape(data1,[],dataSize(end));
data2 = reshape(data2,[],dataSize(end));

roiData = nanmean(data1(roiInd,:),1)';

for pix = 1:prod(dataSize(1:end-1))
    [lagData(pix), ampData(pix)] = mouse.conn.findLag(roiData,data2(pix,:),...
        quadFitUse,positiveSignOnly,validInd);
end

end

