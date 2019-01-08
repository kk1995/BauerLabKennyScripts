% param
rawFile = 'D:\data\StrokeMTEP\Diff_MTEP_PT_minus_Veh_PT.mat';
maskFile = 'D:\data\atlas.mat';

% load
load(rawFile); data = diffMTEP_PT_minus_Veh_PT; % 11188 x 11188
load(maskFile,'mask','AtlasSeedsFilled','seednames'); % mask

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

% remap spatial ind
SeedsUsed=CalcRasterSeedsUsed(mask);
idx=find(mask==1);
length=size(SeedsUsed,1);
map=[(1:2:length-1) (2:2:length)];
NewSeedsUsed(:,1)=SeedsUsed(map, 1);
NewSeedsUsed(:,2)=SeedsUsed(map, 2);
for n=1:size(NewSeedsUsed,1)
    idx_inv(n)=sub2ind([128,128], NewSeedsUsed(n,2), NewSeedsUsed(n,1)); % get the indices of the Seed coordinates used to organize the Pix-Pix matrix
    idx_inv=idx_inv';
end

[B,I] = sort(AtlasSeedsFilled(idx_inv),'ascend');

I(B == 0) = []; % getting rid of pixels that are not in any regions per atlas.

data = data(I,I); % resorting pixels by atlas

%% plot

imagesc(data,[-0.3 0.3]); colormap('jet'); colorbar;
axis(gca,'square');