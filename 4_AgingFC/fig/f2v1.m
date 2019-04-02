dataFile = "L:\ProcessedData\avgSpectra_gsr.mat";
iterNum = 2000;
fRange = [0.01 0.08];

load(dataFile);

inRange = freq >= fRange(1) & freq <= fRange(2);
spectra1 = squeeze(sum(yvSpectra(:,:,inRange,:),3));
spectra2 = squeeze(sum(ovSpectra(:,:,inRange,:),3));
spectra3 = squeeze(sum(odSpectra(:,:,inRange,:),3));

brain1 = yvBrain;
brain2 = ovBrain;
brain3 = odBrain;

gspectra1 = zeros(1,size(yvSpectra,3));
for i = 1:size(yvSpectra,4)
    mouseSpectra = reshape(yvSpectra(:,:,:,i),128*128,[]);
    mouseSpectra = mouseSpectra(logical(brain1(:,:,i)),:);
    mouseSpectra = mean(mouseSpectra,1);
    gspectra1 = gspectra1 + mouseSpectra;
end
gspectra1 = gspectra1./size(yvSpectra,3);

gspectra2 = zeros(1,size(ovSpectra,3));
for i = 1:size(ovSpectra,4)
    mouseSpectra = reshape(ovSpectra(:,:,:,i),128*128,[]);
    mouseSpectra = mouseSpectra(logical(brain2(:,:,i)),:);
    mouseSpectra = mean(mouseSpectra,1);
    gspectra2 = gspectra2 + mouseSpectra;
end
gspectra2 = gspectra2./size(yvSpectra,3);

gspectra3 = zeros(1,size(odSpectra,3));
for i = 1:size(odSpectra,4)
    mouseSpectra = reshape(odSpectra(:,:,:,i),128*128,[]);
    mouseSpectra = mouseSpectra(logical(brain3(:,:,i)),:);
    mouseSpectra = mean(mouseSpectra,1);
    gspectra3 = gspectra3 + mouseSpectra;
end
gspectra3 = gspectra3./size(yvSpectra,3);

spectra1 = permute(spectra1,[3 1 2]);
spectra2 = permute(spectra2,[3 1 2]);
spectra3 = permute(spectra3,[3 1 2]);

totalMat = cat(1,spectra1,spectra2);
[~,~,~,z] = ttest2(spectra1,spectra2);
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

totalMat = cat(1,spectra2,spectra3);
[~,~,~,z] = ttest2(spectra2,spectra3);
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

spectra1 = permute(spectra1,[2 3 1]);
spectra2 = permute(spectra2,[2 3 1]);
spectra3 = permute(spectra3,[2 3 1]);

%%

yLim = [6 123];
xLim = [6 123];

cMax = 10E-11;
wlData = load("L:\ProcessedData\deborahWL.mat");
hemisphereData = load("L:\ProcessedData\deborahHemisphereMask.mat");
atlasData = load("D:\data\atlas12.mat");

topC = [1 0 0]; bottomC = [0 0 1];

cMap = mouse.plot.whiteMiddle(topC,bottomC,100,[0 1]);
cMap2 = mouse.plot.whiteMiddle(topC,bottomC,100);
noVasculature = hemisphereData.leftMask | hemisphereData.rightMask;

f1 = figure('Position',[100 100 1400 800]);
p = panel();
p.pack(2,3);
 
p(1,1).select();
set(gca,'Color','k');
set(gca,'FontSize',12);
mask = mean(brain1,3) >= 6/7 & noVasculature;
image(wlData.xform_wl,'AlphaData',wlData.xform_isbrain);
hold on;
imagesc(mean(spectra1,3),'AlphaData',mask,[0 cMax]); colormap(gca,cMap); colorbar;
axis(gca,'square'); set(gca,'YDir','reverse'); ylim(yLim); xlim(xLim);
yticks([]); xticks([]);
title('Young Vehicle');
for i = 1:numel(unique(atlasData.atlas(:)))-1
    boundaryLoc = bwboundaries(atlasData.atlas == i);
    lh = plot(boundaryLoc{1}(:,2),boundaryLoc{1}(:,1),'LineWidth',3);
    lh.Color=[0,0,0,0.3];
end

p(1,2).select();
set(gca,'Color','k');
set(gca,'FontSize',12);
mask = mean(brain2,3) >= 6/7 & noVasculature;
image(wlData.xform_wl,'AlphaData',wlData.xform_isbrain);
hold on;
imagesc(mean(spectra2,3),'AlphaData',mask,[0 cMax]); colormap(gca,cMap); colorbar;
axis(gca,'square'); set(gca,'YDir','reverse'); ylim(yLim); xlim(xLim);
yticks([]); xticks([]);
title('Old Vehicle');
for i = 1:numel(unique(atlasData.atlas(:)))-1
    boundaryLoc = bwboundaries(atlasData.atlas == i);
    lh = plot(boundaryLoc{1}(:,2),boundaryLoc{1}(:,1),'LineWidth',3);
    lh.Color=[0,0,0,0.3];
end

p(1,3).select();
set(gca,'Color','k');
set(gca,'FontSize',12);
mask = mean(brain3,3) >= 6/7 & noVasculature;
image(wlData.xform_wl,'AlphaData',wlData.xform_isbrain);
hold on;
imagesc(mean(spectra3,3),'AlphaData',mask,[0 cMax]); colormap(gca,cMap); colorbar;
axis(gca,'square'); set(gca,'YDir','reverse'); ylim(yLim); xlim(xLim);
yticks([]); xticks([]);
title('Old Drugged');
for i = 1:numel(unique(atlasData.atlas(:)))-1
    boundaryLoc = bwboundaries(atlasData.atlas == i);
    lh = plot(boundaryLoc{1}(:,2),boundaryLoc{1}(:,1),'LineWidth',3);
    lh.Color=[0,0,0,0.3];
end

p(2,1).select();
set(gca,'Color','k');
set(gca,'FontSize',12);
mask = mean(cat(3,brain2,brain1),3) >= 6/7 & noVasculature;
image(wlData.xform_wl,'AlphaData',wlData.xform_isbrain);
hold on;
imagesc(mean(spectra2,3)-mean(spectra1,3),'AlphaData',mask & significantMask,[-0.5*cMax 0.5*cMax]);
colormap(gca,cMap2); colorbar;
axis(gca,'square'); set(gca,'YDir','reverse'); ylim(yLim); xlim(xLim);
yticks([]); xticks([]);
title('Old Vehicle - Young Vehicle');
for i = 1:numel(unique(atlasData.atlas(:)))-1
    boundaryLoc = bwboundaries(atlasData.atlas == i);
    lh = plot(boundaryLoc{1}(:,2),boundaryLoc{1}(:,1),'LineWidth',3);
    lh.Color=[0,0,0,0.3];
end

p(2,2).select();
set(gca,'Color','k');
set(gca,'FontSize',12);
mask = mean(cat(3,brain3,brain2),3) >= 6/7 & noVasculature;
image(wlData.xform_wl,'AlphaData',wlData.xform_isbrain);
hold on;
imagesc(mean(spectra3,3)-mean(spectra2,3),'AlphaData',mask & significantMask2,[-0.5*cMax 0.5*cMax]);
colormap(gca,cMap2); colorbar;
axis(gca,'square'); set(gca,'YDir','reverse'); ylim(yLim); xlim(xLim);
yticks([]); xticks([]);
title('Old Drugged - Old Vehicle');
for i = 1:numel(unique(atlasData.atlas(:)))-1
    boundaryLoc = bwboundaries(atlasData.atlas == i);
    lh = plot(boundaryLoc{1}(:,2),boundaryLoc{1}(:,1),'LineWidth',3);
    lh.Color=[0,0,0,0.3];
end

p(2,3).select();
set(gca,'FontSize',12);
inRange = freq <= 0.08 & freq >= 0.009;
plot(freq(inRange),log10(gspectra1(inRange)),'LineWidth',3); hold on;
plot(freq(inRange),log10(gspectra2(inRange)),'LineWidth',3);
plot(freq(inRange),log10(gspectra3(inRange)),'LineWidth',3);
legend('Young Vehicle','Old Vehicle','Old Drugged');
title('Power Spectra');
ylabel('power (log 10)');