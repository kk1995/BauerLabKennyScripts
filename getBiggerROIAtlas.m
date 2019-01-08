% here I show how functional connectivity matrix (full 16384 x 16384) can
% be sorted by atlas designation.

%%
% param
maskFile = 'D:\data\atlas.mat';
saveFile = 'D:\data\atlasBigROI.mat';

% load
load(maskFile,'atlas','seedNames'); % atlas data

%% create new atlas

clear newSeedNames;

newAtlas = zeros(size(atlas));

% first three regions before motor
for i = 1:3
    newAtlas(atlas == i) = i;
    newSeedNames{i} = seedNames{i};
end

% put together motor regions into one region
motorInd = 4:5;
for i = 1:numel(motorInd)
    newAtlas(atlas == motorInd(i)) = 4;
    newSeedNames{4} = seedNames{4};
end

% put together somatosensory regions into one region
sSInd = 6:11;
for i = 1:numel(sSInd)
    newAtlas(atlas == sSInd(i)) = 5;
    newSeedNames{5} = seedNames{5};
end

% other regions
for i = 12:20
    newAtlas(atlas == i) = i-6;
    newSeedNames{i-6} = seedNames{i-6};
end

%% separate left and right regions
% creating a 128 x 128 matrix where each pixel has value pertaining to the
% region it is part of (1-40). 0 means the pixel is not in any brain
% region.

% replicate seed names for left and right
seedNameNum = numel(newSeedNames);
for i = 1:seedNameNum
    newSeedNames{seedNameNum+i} = newSeedNames{i};
end

for x = 65:128
    for y = 1:128
        if newAtlas(y,x) ~=0
            newAtlas(y,x) = newAtlas(y,x)*2; % right
        end
    end
end
for x = 1:64
    for y = 1:128
        if newAtlas(y,x) ~=0
            newAtlas(y,x) = newAtlas(y,129-x)-1; % left
        end
    end
end

%% save

atlas = newAtlas;
seedNames = newSeedNames;

save(saveFile,'atlas','seedNames','-v7.3');