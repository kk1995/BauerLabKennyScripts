% param
rawFile = 'D:\data\StrokeMTEP\MTEP_PTminusVeh_PCA.mat';
pcaFile = 'D:\data\StrokeMTEP\PT_Groups_PCA.mat';
maskFile = 'D:\data\atlas.mat';

% load
load(rawFile,'diffMTEP_PT_minus_Veh_PT');
load(pcaFile); % coeff, score
load(maskFile,'mask','mask2','AtlasSeedsFilled','seednames'); % mask

%%
% make sure the mask has all 40 regions
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
% regionEndInd = [find(diff(B)>0); numel(B)]; regionEndInd(1) = [];
% regionStartInd = find(diff(B)>0) + 1;

extraneous = B==0;
B(extraneous) = [];
I(extraneous) = [];

regionEnd = [find(diff(B)~=0); numel(B)];
regionStart = [1; find(diff(B)~=0)+1];
tickLabels = seednames;
for i = 1:20
    tickLabels{i} = [tickLabels{i} '-L'];
end
for i = 21:40
    tickLabels{i} = [tickLabels{i} '-R'];
end

newRegionEnd = nan(1,40);
newRegionStart = nan(1,40);
newTickLabels = cell(1,40);

% left
newRegionStart(1) = regionStart(2);
newRegionEnd(1) = regionEnd(2);
newRegionStart(2) = regionStart(4);
newRegionEnd(2) = regionEnd(5);
newRegionStart(3) = regionStart(6);
newRegionEnd(3) = regionEnd(11);
newRegionStart(4) = regionStart(13);
newRegionEnd(4) = regionEnd(15);
newRegionStart(5) = regionStart(16);
newRegionEnd(5) = regionEnd(18);
% right
newRegionStart(6) = regionStart(22);
newRegionEnd(6) = regionEnd(22);
newRegionStart(7) = regionStart(24); 
newRegionEnd(7) = regionEnd(25);
newRegionStart(8) = regionStart(26);
newRegionEnd(8) = regionEnd(31);
newRegionStart(9) = regionStart(33);
newRegionEnd(9) = regionEnd(35);
newRegionStart(10) = regionStart(36);
newRegionEnd(10) = regionEnd(38);

% left
newTickLabels{1} = 'Frontal-L';
newTickLabels{2} = 'Motor-L';
newTickLabels{3} = 'SS-L';
newTickLabels{4} = 'Parietal-L';
newTickLabels{5} = 'Visual-R';

% right
newTickLabels{6} = 'Frontal-R';
newTickLabels{7} = 'Motor-R';
newTickLabels{8} = 'SS-R';
newTickLabels{9} = 'Parietal-R';
newTickLabels{10} = 'Visual-R';

tickInd = (regionStart + regionEnd)./2;
tickInd = round(tickInd);

% ss
regionEnd(6) = regionEnd(11);
regionEnd(26) = regionEnd(31);
tickInd(6) = mean(tickInd(6:11));
tickInd(26) = mean(tickInd(26:31));
tickLabels{6} = 'SS-L'; tickLabels{26} = 'SS-R';

% parietal
regionEnd(13) = regionEnd(15);
regionEnd(33) = regionEnd(35);
tickInd(13) = mean(tickInd(13:15));
tickInd(33) = mean(tickInd(33:35));
tickLabels{13} = 'P-L'; tickLabels{33} = 'P-R';

tickInd([7:11 14:15 20 27:31 34:35 40]) = [];
tickLabels([7:11 14:15 20 27:31 34:35 40]) = [];
regionStart([7:11 14:15 20 27:31 34:35 40]) = [];
regionEnd([7:11 14:15 20 27:31 34:35 40]) = [];

newtickInd = (newRegionStart + newRegionEnd)./2;
newtickInd = round(newtickInd);
badTicks = isnan(newtickInd);
newtickInd(badTicks) = [];
newTickLabels(badTicks) = [];

% % use simplified ticks
% tickInd = newtickInd;
% tickLabels = newTickLabels;

% plot matrix
f1 = figure('Position',[50 50 500 500]);
p = subplot(1,1,1);
imagesc(diffMTEP_PT_minus_Veh_PT(I,I),[-0.3 0.3]);
yticks(tickInd);
yticklabels(tickLabels);
xticks([]);
xticklabels([]);
colormap('jet');
colorbar;
axis(p,'square');
yl = get(gca,'YAxis');
set(yl,'FontSize',7);
set(gca,'TickLength',[0 0]);
hold on;
for region = 1:numel(tickLabels)
    xHorz = [1 size(diffMTEP_PT_minus_Veh_PT,1)];
    yHorz = [regionStart regionStart];
    plot(xHorz,yHorz,'k');
    
    xVert = [regionStart regionStart];
    yVert = [1 size(diffMTEP_PT_minus_Veh_PT,1)];
    plot(xVert,yVert,'k');
end

%% plot PCA result

load('D:\data\StrokeMTEP\NodalConnectivity.mat','seedCenter','seednames');
roiInd = [13:20 24:29 33:40];
seedVal = zeros(numel(seednames),1);
seedVal = seedVal(roiInd);
seedCenter = seedCenter(roiInd,:);

cMap = jet(100);
blueRedMap = mouseAnalysis.plot.blueWhiteRed(100,[1 0],true);
gMap = gray(100);

f2 = figure('Position',[50 650 600 300]);
p = panel();
p.pack('h', {0.80 []});
p.margin = [0 0 0 0];
ax = p(1).select();
axis(ax,'square');
set(ax,'Visible','off');
n = 1;
addColorBar = true;
pcaVal = nan(128,128);
z = scoreWithMean(:,n)*coeff(:,n)';
pcaVal(idx_inv) = mean(z,2);
ax = mouseAnalysis.plot.plotBrain(ax,pcaVal,mask2 & mask,[-0.01 0.01],cMap,addColorBar);
title(num2str(var(n)));

f3 = figure('Position',[50 650 600 300]);
p = panel();
p.pack('h', {0.80 []});
p.margin = [0 0 0 0];
ax = p(1).select();
axis(ax,'square');
set(ax,'Visible','off');
actualVal = nan(128,128);
actualVal(idx_inv) = nanmean(diffMTEP_PT_minus_Veh_PT);
ax = mouseAnalysis.plot.plotBrain(ax,actualVal,mask2 & mask,[-0.02 0.02],cMap,addColorBar);
title('MTEP PT - Veh PT');

f4 = figure('Position',[50 650 1700 300]);
p = panel();
p.pack('h', {0.19 0.19 0.19 0.19 0.19 []});
p.margin = [0 0 0 0];
for n = 1:5
    ax = p(n).select();
    axis(ax,'square');
    set(ax,'Visible','off');
    addColorBar = false;
    if n == 5
        addColorBar = true;
    end
    pcaVal = nan(128,128);
    z = scoreWithMean(:,n)*coeff(:,n)';
    pcaVal(idx_inv) = mean(z,2);
    ax = mouseAnalysis.plot.plotBrain(ax,pcaVal,mask2 & mask,[-0.01 0.01],cMap,addColorBar);
    % s = plotNodes(s,seedCenter,seedVal,[0 1],blueRedMap,160,false);
    %     s = plotScatter(s,seedCenter,seedVal,[0 1],gMap,160,2);
end
title(num2str(var(n)));