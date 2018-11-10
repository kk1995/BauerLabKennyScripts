function [lagMat, ampMat,covResult] = dotLagFile(data1,data2,sR,varargin)
% dotLagFile With certain input data, it finds the dot lag
%   Inputs:
%       data1 = (x coor) x (y coor) x (time) matrix = raw data
%       data2 = (x coor) x (y coor) x (time) matrix = raw data
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

if numel(varargin) < 1
    fRange = [];
else
    fRange = varargin{1};
end

if numel(varargin) < 2
    tBoundary = [];
else
    tBoundary = varargin{2};
end

if numel(varargin) < 3
    useGsr = false;
else
    useGsr = varargin{3};
end

if numel(varargin) < 4
    mask = true(size(data1,1),size(data1,2));
else
    mask = varargin{4};
    mask = logical(mask);
end

if numel(varargin) < 5
    corrThr = 0.3;
else
    corrThr = varargin{5};
end

%% filter

if isempty(fRange) % no filtering
    fNum = 1; % how many frequency ranges to consider?
    filteredData1 = data1;
    filteredData2 = data2;
else
    fNum = size(fRange,1);
    filteredData1 = nan([size(data1) fNum]);
    filteredData2 = nan([size(data2) fNum]);
    for freqInd = 1:fNum
        filteredData1(:,:,:,freqInd) = filterData(data1,fRange(freqInd,1),fRange(freqInd,2),sR);
        filteredData2(:,:,:,freqInd) = filterData(data2,fRange(freqInd,1),fRange(freqInd,2),sR);
    end
end

%% gsr

if useGsr
    filteredData1 = gsr(filteredData1,mask);
    filteredData2 = gsr(filteredData2,mask);
end

%% lag analysis
% initialize output matrix
dataSize = size(filteredData1);
lagMat = nan(dataSize(1),dataSize(2),fNum);
ampMat = nan(dataSize(1),dataSize(2),fNum);


if isempty(tBoundary)
    tZone = repmat(floor(size(data1,3)/2),fNum);
else
    tZone = round(tBoundary*sR);
end

covResult = cell(fNum,1);
for freqInd = 1:fNum
    covResult{freqInd} = nan(tZone(freqInd)*2+1,...
        size(filteredData1,1)*size(filteredData1,2)/2);
    lagData1 = squeeze(filteredData1(:,:,:,freqInd));
    lagData2 = squeeze(filteredData2(:,:,:,freqInd));
    
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
    
    [lagTime,lagAmp,covResultTemp] = mouseAnalysis.conn.dotLag(lagData1,lagData2,edgeLen,tZone(freqInd),corrThr);
    lagTime = lagTime./sR;
    covResult{freqInd} = covResultTemp';
    
    % make non-mask data nan
    lagTime(~mask) = nan;
    lagAmp(~mask) = nan;
    
    % add to total matrix
    lagMat(:,:,freqInd) = lagTime;
    ampMat(:,:,freqInd) = lagAmp;
end
end