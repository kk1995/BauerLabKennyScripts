function [lagMat, ampMat,covResult] = gsLagFile(data,sR,mask,varargin)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

% lag parameters
if nargin < 4
    fRange = [];
else
    fRange = varargin{1};
end

if nargin < 5
    tBoundary = [];
else
    tBoundary = varargin{2};
end

if nargin < 6
    corrThr = 0.3;
else
    corrThr = varargin{3};
end

edgeLen = 3;

%% filter

if isempty(fRange) % no filtering
    fNum = 1; % how many frequency ranges to consider?
    filteredData = data;
else
    fNum = size(fRange,1);
    filteredData = nan([size(data) fNum]);
    for freqInd = 1:fNum
        filteredData(:,:,:,:,freqInd) = filterData(data,fRange(freqInd,1),fRange(freqInd,2),sR);
    end
end

%% lag analysis
fDataSz = size(filteredData);

lagMat = nan(fDataSz(1),fDataSz(2),fDataSz(3),fNum);
ampMat = nan(fDataSz(1),fDataSz(2),fDataSz(3),fNum);

if isempty(tBoundary)
    tZone = repmat(floor(size(data,4)/2),fNum);
else
    tZone = round(tBoundary*sR);
end

covResult = cell(fNum,1);
for freqInd = 1:fNum
    covResult{freqInd} = nan(size(filteredData,3),tZone(freqInd)*2+1,...
        sum(mask(:)));
    
    for specInd = 1:size(filteredData,3)
        lagData = squeeze(filteredData(:,:,specInd,:,freqInd));
        lagData = reshape(lagData,size(lagData,1)*size(lagData,2),[]);
        lagData = lagData(mask(:),:);
        
        % input = pix x time
        [lagTime,lagAmp,covResultTemp] = gsLag(lagData,edgeLen,tZone(freqInd),corrThr);
        lagTime = lagTime./sR;
        
        lagTime2D = nan(fDataSz(1:2));
        lagTime2D(mask(:)) = lagTime;
        
        lagAmp2D = nan(fDataSz(1:2));
        lagAmp2D(mask(:)) = lagAmp;
        
        lagMat(:,:,specInd,freqInd) = lagTime2D;
        ampMat(:,:,specInd,freqInd) = lagAmp2D;
        
        covResult{freqInd}(specInd,:,:) = covResultTemp';
    end
end
end

