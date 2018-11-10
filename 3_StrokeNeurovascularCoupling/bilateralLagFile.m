function [lagMat, ampMat,covResult] = bilateralLagFile(data,sR,varargin)
% bilateralLagFile With certain input data, it finds the bilateral lag
%   Inputs:
%       data = (x coor) x (y coor) x (species) x (time) matrix = raw data
%       sR = number = sampling rate
%       fRange (optional) = (freq num) x 2 vector = frequency range for bandpass filtering. If empty, default
%       value is used. (default = no filtering)
%       tBoundary (optional) = (freq num) x 1 vector = the boundary (in
%       seconds) at which the lag time is non-sensical (default = no
%       boundary)
%       useGsr (optional) = whether to use global signal regression (default =
%       false).
%       mask (optional) = (x coor) x (y coor) logical/double matrix = mask of
%       the region of interest for global signal regression. (default = all
%       pixels)
%       corrThr = threshold at which correlation is considered significant
%       for lag time (default = 0.3)
%   Outputs:
%       lagMat = (x coor) x (y coor) x (species) x (freq num)
%       ampMat = (x coor) x (y coor) x (species) x (freq num)
%       covResult = cell array (freq num). each cell is (species x time x
%       pixels)
%   
%   Example:
%   [lagMat, ampMat] = bilateralLagFile(data,sR,[0.009 0.5],true,mask)
%       this example does bandpass filtering at 0.009-0.5 Hz and does
%       global signal regression. mask is whatever the input is.
%
% (c) 2018 Washington University in St. Louis
% All Right Reserved
%
% Licensed under the Apache License, Version 2.0 (the "License");
% You may not use this file except in compliance with the License.
% A copy of the License is available is with the distribution and can also
% be found at:
%
% http://www.apache.org/licenses/LICENSE-2.0
%
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
% IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
% THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
% PURPOSE, OR THAT THE USE OF THE SOFTWARD WILL NOT INFRINGE ANY PATENT
% COPYRIGHT, TRADEMARK, OR OTHER PROPRIETARY RIGHTS ARE DISCLAIMED. IN NO
% EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY
% DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
% DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
% OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
% HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
% STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
% ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
% POSSIBILITY OF SUCH DAMAGE.

if nargin < 3
    fRange = [];
else
    fRange = varargin{1};
end

if nargin < 4
    tBoundary = [];
else
    tBoundary = varargin{2};
end

if nargin < 5
    useGsr = false;
else
    useGsr = varargin{3};
end

if nargin < 6
    mask = true(size(data,1),size(data,2));
else
    mask = varargin{4};
    mask = logical(mask);
end

if nargin < 7
    corrThr = 0.3;
else
    corrThr = varargin{5};
end

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

%% gsr

if useGsr
    filteredData = gsr(filteredData,mask);
end

%% lag analysis
% initialize output matrix
dataSize = size(filteredData);
lagMat = nan(dataSize(1),dataSize(2),dataSize(3),fNum);
ampMat = nan(dataSize(1),dataSize(2),dataSize(3),fNum);


if isempty(tBoundary)
    tZone = repmat(floor(size(data,4)/2),fNum);
else
    tZone = round(tBoundary*sR);
end

covResult = cell(fNum,1);
for freqInd = 1:fNum
    covResult{freqInd} = nan(size(filteredData,3),tZone(freqInd)*2+1,...
        size(filteredData,1)*size(filteredData,2)/2);
    for specInd = 1:size(filteredData,3)
        lagData = squeeze(filteredData(:,:,specInd,:,freqInd));
        
        % lag parameters
%         fMin = fRange(freqInd,1); fMax = fRange(freqInd,2);
%         fCenter = exp(0.5*(log(fMin)+log(fMax)));
%         period = 1/fCenter;
        edgeLen = 3;
%         edgeLen = round(period*sR/12); % 1/12 the period (middle 60 degrees)
        % the justification for the middle 60 degrees is that if the data is
        % sinusoidal, then the middle 60 degrees should show the curve that looks
        % like a parabola. 60 degrees is also small enough that noise effect should
        % be small.
        
        [lagTime,lagAmp,covResultTemp] = bilateralLag(lagData,edgeLen,tZone(freqInd),corrThr);
        covResult{freqInd}(specInd,:,:) = covResultTemp';
        % adjust lag time to frame rate
        lagTime = lagTime./sR;
        
        % make non-mask data nan
        lagTime(~mask) = nan;
        lagAmp(~mask) = nan;
        
        % add to total matrix
        lagMat(:,:,specInd,freqInd) = lagTime;
        ampMat(:,:,specInd,freqInd) = lagAmp;
    end
end
end