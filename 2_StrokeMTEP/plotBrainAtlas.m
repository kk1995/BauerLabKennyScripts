load('D:\data\StrokeMTEP\AtlasandIsbrain.mat');

seednames{4} = 'M2'; % M2 and M1 flipped in loaded data
seednames{5} = 'M1';
seednames = repmat(seednames,1,2); % for both left and right

%% find focal center for each seed

seedCenter = nan(max(AtlasSeeds(:)),2);
for seed = 1:max(AtlasSeeds(:))
    ind = find(AtlasSeeds == seed);
    [row, col] = mouse.plot.ind2D(ind,size(AtlasSeeds));
    seedCenter(seed,1) = mean(col);
    seedCenter(seed,2) = mean(row);
end

imAlpha=AtlasSeeds>0;
imagesc(AtlasSeeds,'AlphaData',imAlpha);
set(gca,'Visible','off');
hold on;

for seed = 1:size(seedCenter,1)
    text(seedCenter(seed,1),seedCenter(seed,2),seednames{seed},'HorizontalAlignment','center');
end

hold off;