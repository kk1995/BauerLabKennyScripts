atlasFile = "D:\data\atlas.mat";
saveFile = "D:\data\atlas8.mat";

load(atlasFile);
newAtlasInd = {[4 5],6:11,12,16:18,[24 25],26:31,32,36:38};
notInd = true(40,1);
atlas2 = zeros(128);
for i = 1:numel(newAtlasInd)
    for j = 1:numel(newAtlasInd{i})
        notInd(newAtlasInd{i}) = false;
        atlas2(atlas == newAtlasInd{i}(j)) = i;
    end
end
atlas = atlas2;

atlasFile = "L:\ProcessedData\AtlasandIsbrain.mat";

atlasData = load(atlasFile);
atlasSource = atlasData.AtlasSeeds;
newAtlasInd = {[4 5],6:11,12,16:18,[24 25],26:31,32,36:38};
atlas2 = zeros(128);

gaussian = zeros(5);
for i = 1:5
    for j = 1:5
        gaussian(i,j) = exp(-((i-3)^2+(j-3)^2));
    end
end
gaussian = gaussian./sum(gaussian(:));
for i = 1:numel(newAtlasInd)
    z = false(128);
    for j = 1:numel(newAtlasInd{i})
        z(atlasSource == newAtlasInd{i}(j)) = true;
    end
    [y,x] = mouse.math.ind2D(find(z),[128 128]);
    k = boundary(x,y,0.7);
    [yq,xq] = mouse.math.ind2D(1:128^2,[128,128]); in = inpolygon(xq,yq,x(k),y(k));
    in = reshape(in,128,128);
    atlas2(conv2(in,gaussian,'same') > 0.9) = i;
end
atlasUnfilled = atlas2;

% isbrain = atlas(:) > 0;
% isright = false(128^2,1); isright(128*64+1:end) = true;
% atlas(isright & isbrain) = atlas(isright & isbrain) + 8;

seedNames = {'M','SS','RS','V'};
seedNames = repmat(seedNames,1,2);

save(saveFile,'atlas','seedNames','atlasUnfilled');