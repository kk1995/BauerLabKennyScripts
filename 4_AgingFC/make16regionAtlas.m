atlasFile = "D:\data\atlas.mat";
saveFile = "D:\data\atlas16.mat";

load(atlasFile);
newAtlasInd = {1,2,[4 5],6:11,12,13:15,16:18,19,21,22,[24 25],26:31,32,33:35,36:38,39};
notInd = true(40,1);
atlas2 = zeros(128);
for i = 1:numel(newAtlasInd)
    for j = 1:numel(newAtlasInd{i})
        notInd(newAtlasInd{i}) = false;
        atlas2(atlas == newAtlasInd{i}(j)) = i;
    end
end
atlas = atlas2;

% isbrain = atlas(:) > 0;
% isright = false(128^2,1); isright(128*64+1:end) = true;
% atlas(isright & isbrain) = atlas(isright & isbrain) + 8;

seedNames = {'O','F','M','SS','RS','P','V','Aud'};
seedNames = repmat(seedNames,1,2);

save(saveFile,'atlas','seedNames');