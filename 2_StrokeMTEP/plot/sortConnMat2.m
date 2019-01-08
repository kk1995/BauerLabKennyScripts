% here I show how functional connectivity matrix (full 16384 x 16384) can
% be sorted by atlas designation.

%%
% param
rawFile = 'D:\data\sampleFC.mat';
maskFile = 'D:\data\atlas.mat';

% load
load(rawFile); % data = 16384 x 16384, mask
load(maskFile,'AtlasSeedsFilled','seednames'); % atlas data

%%
% creating a 128 x 128 matrix where each pixel has value pertaining to the
% region it is part of (1-40). 0 means the pixel is not in any brain
% region.
for x = 65:128
    for y = 1:128
        if AtlasSeedsFilled(y,x) ~=0
            AtlasSeedsFilled(y,x) = AtlasSeedsFilled(y,x) + 20;
        end
    end
end
AtlasSeedsFilled = AtlasSeedsFilled(:);

[B,I] = sort(AtlasSeedsFilled,'ascend');

badInd = B == 0;
badInd(mask == 0) = true;

I(badInd) = []; % getting rid of pixels that are not in any regions per atlas.

data = data(I,I); % resorting pixels by atlas

%% plot

imagesc(data,[-1 1]); colormap('jet'); colorbar;
axis(gca,'square');