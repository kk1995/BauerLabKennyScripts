% param
rawFile = 'D:\data\StrokeMTEP\PT_Groups_avg_reorganized.mat';
pcaFile = 'D:\data\StrokeMTEP\MTEP_PT-Veh_PT_PCA.mat';
atlasFile = 'D:\data\atlas.mat';
maskFile = 'D:\data\StrokeMTEP\mask.mat';

% load
load(rawFile);
load(pcaFile); % coeff, score, mu, diff
load(atlasFile); % atlas, seedNames
load(maskFile); % mask, mask2

%%
% make sure the mask has all 40 regions
for x = 65:128
    for y = 1:128
        if atlas(y,x) ~=0
            atlas(y,x) = atlas(y,x) + 20;
        end
    end
end

% remap spatial ind
SeedsUsed=CalcRasterSeedsUsed(mask2);
idx=find(mask2);
length=size(SeedsUsed,1);
map=[(1:2:length-1) (2:2:length)];
NewSeedsUsed(:,1)=SeedsUsed(map, 1);
NewSeedsUsed(:,2)=SeedsUsed(map, 2);
for n=1:size(NewSeedsUsed,1)
    idx_inv(n)=sub2ind([128,128], NewSeedsUsed(n,2), NewSeedsUsed(n,1)); % get the indices of the Seed coordinates used to organize the Pix-Pix matrix
    idx_inv=idx_inv';
end
[B,I] = sort(atlas(idx_inv),'ascend');
% regionEndInd = [find(diff(B)>0); numel(B)]; regionEndInd(1) = [];
% regionStartInd = find(diff(B)>0) + 1;

extraneous = B==0;
B(extraneous) = [];
I(extraneous) = [];

%% plot PCA result

load('D:\data\StrokeMTEP\NodalConnectivity.mat','seedCenter','seednames');
roiInd = [13:20 24:29 33:40];
seedVal = zeros(numel(seednames),1);
seedVal = seedVal(roiInd);
seedCenter = seedCenter(roiInd,:);

cMap = jet(100);
blueRedMap = mouse.plot.blueWhiteRed(100,[1 0],true);
gMap = gray(100);

load('D:\data\StrokeMTEP\AtlasandIsbrain.mat');
mask2 = symisbrainall;

% get infarct site
centerCoor = [59 37];
radius = [25 10];
coor = mouse.plot.ovalCoor(centerCoor,radius);
coorInd = coor(1,:) + (128*(coor(2,:)-1));
infarctROI = false(128); infarctROI(coorInd) = true;
color = [0.5 0.5 0.5];
alpha = 0.5;

pcaInd = 1;
% z = mean(score(:,n)*coeff(:,n)'+mu(n),2);
% z = score(:,n).*coeff(:,n);
z = -coeff(:,pcaInd);
% diff = coeff*score';
cLim = [-0.02 0.02];
f2 = figure('Position',[50 650 600 300]);
p = panel();
p.pack('h', {0.80 []});
p.margin = [0 0 0 0];
ax = p(1).select();
axis(ax,'square');
set(ax,'Visible','off');
addColorBar = true;
pcaVal = nan(128,128);
pcaVal(idx_inv) = z;
ax = mouse.plot.plotBrain(ax,pcaVal,mask2,cLim,cMap,addColorBar);
ax = mouse.plot.plotCluster(ax,infarctROI,color,alpha);
ax = mouse.plot.plotContour(ax,infarctROI,'k');

f3 = figure('Position',[50 650 600 300]);
p = panel();
p.pack('h', {0.80 []});
p.margin = [0 0 0 0];
ax = p(1).select();
axis(ax,'square');
set(ax,'Visible','off');
actualVal = nan(128,128);
actualVal(idx_inv) = nanmean(diffMTEP_PT_minus_Veh_PT);
ax = mouse.plot.plotBrain(ax,actualVal,mask2,[-0.02 0.02],cMap,addColorBar);
title('MTEP PT - Veh PT');

%%
% f4 = figure('Position',[50 650 1700 300]);
f4 = figure('Position',[50 650 1200 300]);
p = panel();
p.pack('h', {0.32 0.32 0.32 []});
p.margin = [15 0 0 0];

% get infarct site
centerCoor = [59 37];
radius = [25 10];
coor = mouse.plot.ovalCoor(centerCoor,radius);
coorInd = coor(1,:) + (128*(coor(2,:)-1));
infarctROI = false(128); infarctROI(coorInd) = true;
color = [0.5 0.5 0.5];
alpha = 0.5;
for n = 1:3
    ax = p(n).select();
    title(ax,num2str(100*latent(n)/sum(latent)));
    axis(ax,'square');
    set(ax,'Visible','off');
    addColorBar = false;
    if n == 3
        addColorBar = true;
    end
    pcaVal = nan(128,128);
    z = score(:,n)*coeff(:,n)';
    pcaVal(idx_inv) = mean(z,2);
    ax = mouse.plot.plotBrain(ax,pcaVal,mask2 & mask,[-0.02 0.02],cMap,addColorBar,0.01);
    % s = plotNodes(s,seedCenter,seedVal,[0 1],blueRedMap,160,false);
    %     s = plotScatter(s,seedCenter,seedVal,[0 1],gMap,160,2);
    ax = mouse.plot.plotCluster(ax,infarctROI,color,alpha);
    ax = mouse.plot.plotContour(ax,infarctROI,'k');
    title(ax(end),num2str(100*latent(n)/sum(latent)));
end