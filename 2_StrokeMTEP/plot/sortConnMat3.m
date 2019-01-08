% here I show how functional connectivity matrix (full 16384 x 16384) can
% be sorted by atlas designation.

%%
% param
rawFile = 'D:\data\sampleFC.mat';
maskFile = 'D:\data\atlasBigROI.mat';

% load
load(rawFile); % data = 16384 x 16384, mask
load(maskFile,'atlas','seedNames'); % atlas data

%% take out any non-mask data

data = data(mask == 1,mask == 1);
atlas = atlas(mask == 1);

%%
[B,I] = sort(atlas,'ascend');

badInd = atlas == 0;
I(badInd) = []; % getting rid of pixels that are not in any regions per atlas.

data = data(I,I); % resorting pixels by atlas

%% plot

imagesc(data,[-1 1]); colormap('jet'); colorbar;
axis(gca,'square');