dataFile = "L:\ProcessedData\avgBilateral_gsr.mat";
iterNum = 2000;

load(dataFile);

brain1 = yvBrain;
brain2 = ovBrain;
brain3 = odBrain;

data1 = yvFC;
data2 = ovFC;
data3 = odFC;

totalMat = cat(1,permute(data1,[3 1 2]),permute(data2,[3 1 2]));
[~,~,~,z] = ttest2(permute(data1,[3 1 2]),permute(data2,[3 1 2]));
testMat = squeeze(z.tstat);
nullMat = zeros(128,128,iterNum);

for i = 1:iterNum
    if mod(i,100) == 0
        disp(num2str(i));
    end
    randOrder = randperm(14);
    [~,~,~,z] = ttest2(totalMat(randOrder(1:7),:,:),totalMat(randOrder(8:14),:,:));
    nullMat(:,:,i) = z.tstat;
end

tThr = tinv(0.975,squeeze(round(sum(cat(3,brain1,brain2),3)./2)));

[clusterLoc,clusterP,clusterT,tDist] = mouse.stat.clusterTestMaris(nullMat,testMat,tThr);

significantMask = zeros(128);
for i = 1:numel(clusterLoc)
    if clusterP(i) < 0.05
        significantMask(clusterLoc{i}) = 1;
    end
end

totalMat = cat(1,permute(data2,[3 1 2]),permute(data3,[3 1 2]));
[~,~,~,z] = ttest2(permute(data2,[3 1 2]),permute(data3,[3 1 2]));
testMat = squeeze(z.tstat);
nullMat = zeros(128,128,iterNum);

for i = 1:iterNum
    if mod(i,100) == 0
        disp(num2str(i));
    end
    randOrder = randperm(14);
    [~,~,~,z] = ttest2(totalMat(randOrder(1:7),:,:),totalMat(randOrder(8:14),:,:));
    nullMat(:,:,i) = z.tstat;
end

tThr = tinv(0.975,squeeze(round(sum(cat(3,brain1,brain2),3)./2)));

[clusterLoc,clusterP,clusterT,tDist] = mouse.stat.clusterTestMaris(nullMat,testMat,tThr);

significantMask2 = zeros(128);
for i = 1:numel(clusterLoc)
    if clusterP(i) < 0.05
        significantMask2(clusterLoc{i}) = 1;
    end
end

%%

cMax = 1.5;
wlData = load("L:\ProcessedData\deborahWL.mat");
hemisphereData = load("L:\ProcessedData\deborahHemisphereMask.mat");
topC = [1 0 0]; bottomC = [0 0 1];

cMap = jet(100);
cMap2 = jet(100);
noVasculature = hemisphereData.leftMask | hemisphereData.rightMask;

f1 = figure('Position',[100 100 1400 800]);
p = panel();
p.pack(2,3);
 
p(1,1).select();
set(gca,'Color','k')
mask = mean(brain1,3) >= 6/7 & fliplr(mean(brain1,3)) >= 6/7 &noVasculature;
image(wlData.xform_wl,'AlphaData',wlData.xform_isbrain);
hold on;
imagesc(nanmean(data1,3),'AlphaData',mask,[0 cMax]); colormap(gca,cMap); colorbar;
axis(gca,'square'); set(gca,'YDir','reverse'); ylim([1 size(brain1,1)]); xlim([1 size(brain1,1)]);
yticks([]); xticks([]);
title('YV');

p(1,2).select();
set(gca,'Color','k')
mask = mean(brain2,3) >= 6/7 & fliplr(mean(brain2,3)) >= 6/7 & noVasculature;
image(wlData.xform_wl,'AlphaData',wlData.xform_isbrain);
hold on;
imagesc(nanmean(data2,3),'AlphaData',mask,[0 cMax]); colormap(gca,cMap); colorbar;
axis(gca,'square'); set(gca,'YDir','reverse'); ylim([1 size(brain1,1)]); xlim([1 size(brain1,1)]);
yticks([]); xticks([]);
title('OV');

p(1,3).select();
set(gca,'Color','k')
mask = mean(brain3,3) >= 6/7 & fliplr(mean(brain3,3)) >= 6/7 & noVasculature;
image(wlData.xform_wl,'AlphaData',wlData.xform_isbrain);
hold on;
imagesc(nanmean(data3,3),'AlphaData',mask,[0 cMax]); colormap(gca,cMap); colorbar;
axis(gca,'square'); set(gca,'YDir','reverse'); ylim([1 size(brain1,1)]); xlim([1 size(brain1,1)]);
yticks([]); xticks([]);
title('OD');

p(2,1).select();
set(gca,'Color','k')
mask = mean(cat(3,brain2,brain1),3) >= 6/7 & fliplr(mean(cat(3,brain2,brain1),3)) >= 6/7 & noVasculature;
image(wlData.xform_wl,'AlphaData',wlData.xform_isbrain);
hold on;
imagesc(mean(data2,3)-mean(data1,3),'AlphaData',mask & significantMask,[-0.5*cMax 0.5*cMax]);
colormap(gca,cMap2); colorbar;
axis(gca,'square'); set(gca,'YDir','reverse'); ylim([1 size(brain1,1)]); xlim([1 size(brain1,1)]);
yticks([]); xticks([]);
title('OV - YV');

p(2,2).select();
set(gca,'Color','k')
mask = mean(cat(3,brain3,brain2),3) >= 6/7 & fliplr(mean(cat(3,brain3,brain2),3)) >= 6/7 & noVasculature;
image(wlData.xform_wl,'AlphaData',wlData.xform_isbrain);
hold on;
imagesc(mean(data3,3)-mean(data2,3),'AlphaData',mask & significantMask2,[-0.5*cMax 0.5*cMax]);
colormap(gca,cMap2); colorbar;
axis(gca,'square'); set(gca,'YDir','reverse'); ylim([1 size(brain1,1)]); xlim([1 size(brain1,1)]);
yticks([]); xticks([]);
title('OD - OV');

p(2,3).select();
mask = brain1 > 0;
for i = 1:size(mask,3)
    mask(:,:,i) = mask(:,:,i) & fliplr(mask(:,:,i));
end
yvAll = yvFC(mask);

mask = brain2 > 0;
for i = 1:size(mask,3)
    mask(:,:,i) = mask(:,:,i) & fliplr(mask(:,:,i));
end
ovAll = ovFC(mask);

mask = brain3 > 0;
for i = 1:size(mask,3)
    mask(:,:,i) = mask(:,:,i) & fliplr(mask(:,:,i));
end
odAll = odFC(mask);

histogram(yvAll,'BinWidth',0.1); hold on;
histogram(ovAll,'BinWidth',0.1);
histogram(odAll,'BinWidth',0.1);
xlabel('z(r)');
legend('YV','OV','OD','Location','northwest');

%%

% topC = [1 0 0]; bottomC = [0 0 1];
% 
% cMap = mouse.plot.whiteMiddle(topC,bottomC,100,[0 1]);
% cMap2 = mouse.plot.whiteMiddle(topC,bottomC,100);
% cMax = 6E-5;
% 
% f1 = figure('Position',[100 300 1700 600]);
% p = panel();
% p.pack(1,3);
% 
% p(1,1).select();
% set(gca,'Color','k')
% mask = mean(brain3,3) >= 6/7;
% imagesc(mean(spectra3,3),'AlphaData',mask,[0 cMax]); colormap(gca,cMap); colorbar;
% axis(gca,'square'); set(gca,'YDir','reverse'); ylim([1 size(brain1,1)]); xlim([1 size(brain1,1)]);
% yticks([]); xticks([]);
% title('OD spectra');
% 
% p(1,2).select();
% set(gca,'Color','k')
% mask = mean(brain2,3) >= 6/7;
% imagesc(mean(spectra2,3),'AlphaData',mask,[0 cMax]); colormap(gca,cMap); colorbar;
% axis(gca,'square'); set(gca,'YDir','reverse'); ylim([1 size(brain1,1)]); xlim([1 size(brain1,1)]);
% yticks([]); xticks([]);
% title('OV spectra');
% 
% p(1,3).select();
% set(gca,'Color','k')
% mask = mean(cat(3,brain3,brain2),3) >= 6/7;
% imagesc(mean(spectra3,3)-mean(spectra2,3),'AlphaData',mask & significantMask2,[-0.5*cMax 0.5*cMax]);
% colormap(gca,cMap2); colorbar;
% axis(gca,'square'); set(gca,'YDir','reverse'); ylim([1 size(brain1,1)]); xlim([1 size(brain1,1)]);
% yticks([]); xticks([]);
% title('OD - OV spectra');

%%

% f2 = figure('Position',[100 100 1000 600]);
% p = panel();
% p.pack(1,2);
% p(1,1).select();
% set(gca,'Color','k')
% mask = mean(cat(3,oldBrain,youngBrain),3) >= 0.9;
% imagesc(mean(oldSpectra,3)-mean(youngSpectra,3),'AlphaData',mask,[-0.5*cMax 0.5*cMax]); colormap(cMap); colorbar;
% axis(gca,'square'); set(gca,'YDir','reverse'); ylim([1 size(oldBrain,1)]); xlim([1 size(oldBrain,1)]);
% yticks([]); xticks([]);
% title('Old - young spectra');
% 
% p(1,2).select();
% set(gca,'Color','k')
% imagesc(significantMask,'AlphaData',mask); axis(gca,'square'); set(gca,'YDir','reverse');
% ylim([1 size(oldBrain,1)]); xlim([1 size(oldBrain,1)]); yticks([]); xticks([]); colorbar;
% title('cluster statistic - significant');