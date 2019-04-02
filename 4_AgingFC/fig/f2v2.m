dataFile = "L:\ProcessedData\deborah\avgSpectra_gsr.mat";
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

%% make everything bigger

wlData = load("L:\ProcessedData\deborah\deborahWL.mat");
hemisphereData = load("L:\ProcessedData\deborah\deborahHemisphereMask.mat");
atlasData = load("D:\data\atlas12.mat");

noVasculature = hemisphereData.leftMask | hemisphereData.rightMask;
noVasculature = imresize(noVasculature,2);
noVasculature = imgaussfilt(double(noVasculature),2) >= 0.5;

atlasData.atlasUnfilled = imresize(atlasData.atlasUnfilled,2,'nearest');
newWL = nan(256,256,3);
for i = 1:3
    newWL(:,:,i) = imresize(wlData.xform_wl(:,:,i),2);
end
wlData.xform_wl = newWL;
wlData.xform_isbrain = imgaussfilt(double(imresize(wlData.xform_isbrain,2,'nearest')),2) >= 0.5;

yLim = [6 123]*2;
xLim = [6 123]*2;

newBrain = nan(256,256,size(brain1,3));
newSpectra = nan(256,256,size(spectra1,3));
for i = 1:size(spectra1,3)
    newSpectra(:,:,i) = imresize(spectra1(:,:,i),2);
    newBrain(:,:,i) = imresize(brain1(:,:,i),2) >= 0.5;
end
brain1 = newBrain;
spectra1 = newSpectra;

newBrain = nan(256,256,size(brain2,3));
newSpectra = nan(256,256,size(spectra2,3));
for i = 1:size(spectra2,3)
    newSpectra(:,:,i) = imresize(spectra2(:,:,i),2);
    newBrain(:,:,i) = imresize(brain2(:,:,i),2) >= 0.5;
end
brain2 = newBrain;
spectra2 = newSpectra;

newBrain = nan(256,256,size(brain3,3));
newSpectra = nan(256,256,size(spectra3,3));
for i = 1:size(spectra3,3)
    newSpectra(:,:,i) = imresize(spectra3(:,:,i),2);
    newBrain(:,:,i) = imresize(brain3(:,:,i),2) >= 0.5;
end
brain3 = newBrain;
spectra3 = newSpectra;

significantMask = imresize(significantMask,2,'nearest');
significantMask2 = imresize(significantMask2,2,'nearest');

%% plot

cMax = 9;

topC = [1 0 0]; bottomC = [0 0 1];

cMap = mouse.plot.whiteMiddle(topC,bottomC,100,[0 1]);
cMap2 = mouse.plot.whiteMiddle(topC,bottomC,100);

f1 = figure('Position',[100 100 1270 800]);
p = panel();
p.pack(2,3);
p.de.margin = 5;
p.margintop = 10;
p.de.margintop = 15;
p.marginright = 25;
p.marginleft = 25;

p(1,1).select();
h1 = gca;
set(gca,'Color',[1,1,1,0]);
set(gca,'Visible','off');
set(gca,'FontSize',16);
mask = mean(brain1,3) >= 6/7 & noVasculature;
image(wlData.xform_wl,'AlphaData',wlData.xform_isbrain);
hold on;
imagesc(mean(spectra1*1E11,3),'AlphaData',mask,[0 cMax]); colormap(gca,cMap);
axis(gca,'square'); set(gca,'YDir','reverse'); ylim(yLim); xlim(xLim);
yticks([]); xticks([]);
for i = 1:numel(unique(atlasData.atlasUnfilled(:)))-1
    inRegion = atlasData.atlasUnfilled == i;
    inView = false(size(brain1,1)); inView(yLim(1):yLim(2),xLim(1):xLim(2)) = true;
    inRegion = inRegion & inView & mask;
    boundaryLoc = bwboundaries(inRegion);
    lh = plot(boundaryLoc{1}(:,2),boundaryLoc{1}(:,1),'LineWidth',3);
    lh.Color=[0,0,0,0.5];
end
t = title('Young Vehicle'); set(t,'Visible','on');
originalSize = get(gca, 'Position');
ch = colorbar('Location','westoutside'); ylabel(ch,'Power (10^-^1^1\muM^2/Hz)');
set(h1, 'Position', originalSize);

p(1,2).select();
set(gca,'Color',[1,1,1,0]);
set(gca,'Visible','off');
set(gca,'FontSize',16);
mask = mean(brain2,3) >= 6/7 & noVasculature;
image(wlData.xform_wl,'AlphaData',wlData.xform_isbrain);
hold on;
imagesc(mean(spectra2*1E11,3),'AlphaData',mask,[0 cMax]); colormap(gca,cMap);
axis(gca,'square'); set(gca,'YDir','reverse'); ylim(yLim); xlim(xLim);
yticks([]); xticks([]);
for i = 1:numel(unique(atlasData.atlasUnfilled(:)))-1
    inRegion = atlasData.atlasUnfilled == i;
    inView = false(size(brain1,1)); inView(yLim(1):yLim(2),xLim(1):xLim(2)) = true;
    inRegion = inRegion & inView & mask;
    boundaryLoc = bwboundaries(inRegion);
    lh = plot(boundaryLoc{1}(:,2),boundaryLoc{1}(:,1),'LineWidth',3);
    lh.Color=[0,0,0,0.5];
end
t = title('Old Vehicle'); set(t,'Visible','on');

p(1,3).select();
set(gca,'Color',[1,1,1,0]);
set(gca,'Visible','off');
set(gca,'FontSize',16);
mask = mean(brain3,3) >= 6/7 & noVasculature;
image(wlData.xform_wl,'AlphaData',wlData.xform_isbrain);
hold on;
im = imagesc(mean(spectra3*1E11,3),'AlphaData',mask,[0 cMax]); colormap(gca,cMap);
axis(gca,'square'); set(gca,'YDir','reverse'); ylim(yLim); xlim(xLim);
yticks([]); xticks([]);
for i = 1:numel(unique(atlasData.atlasUnfilled(:)))-1
    inRegion = atlasData.atlasUnfilled == i;
    inView = false(size(brain1,1)); inView(yLim(1):yLim(2),xLim(1):xLim(2)) = true;
    inRegion = inRegion & inView & mask;
    boundaryLoc = bwboundaries(inRegion);
    lh = plot(boundaryLoc{1}(:,2),boundaryLoc{1}(:,1),'LineWidth',3);
    lh.Color=[0,0,0,0.5];
end
t = title('Old Drug'); set(t,'Visible','on');

p(2,1).select();
h1 = gca;
set(gca,'Color',[1,1,1,0]);
set(gca,'Visible','off');
set(gca,'FontSize',16);
mask = mean(cat(3,brain2,brain1),3) >= 6/7 & noVasculature;
image(wlData.xform_wl,'AlphaData',wlData.xform_isbrain);
hold on;
imagesc(mean(spectra2*1E11,3)-mean(spectra1*1E11,3),'AlphaData',mask & significantMask,[-0.5*cMax 0.5*cMax]);
colormap(gca,cMap2);
axis(gca,'square'); set(gca,'YDir','reverse'); ylim(yLim); xlim(xLim);
yticks([]); xticks([]);
for i = 1:numel(unique(atlasData.atlasUnfilled(:)))-1
    inRegion = atlasData.atlasUnfilled == i;
    inView = false(size(brain1,1)); inView(yLim(1):yLim(2),xLim(1):xLim(2)) = true;
    inRegion = inRegion & inView & mask;
    boundaryLoc = bwboundaries(inRegion);
    lh = plot(boundaryLoc{1}(:,2),boundaryLoc{1}(:,1),'LineWidth',3);
    lh.Color=[0,0,0,0.5];
end
originalSize = get(gca, 'Position');
ch = colorbar('Location','westoutside'); ylabel(ch,'\Delta Power (10^-^1^1\muM^2/Hz)');
t = title('Old Vehicle - Young Vehicle'); set(t,'Visible','on');
set(h1, 'Position', originalSize);

p(2,2).select();
set(gca,'Color',[1,1,1,0]);
set(gca,'Visible','off');
set(gca,'FontSize',16);
mask = mean(cat(3,brain3,brain2),3) >= 6/7 & noVasculature;
image(wlData.xform_wl,'AlphaData',wlData.xform_isbrain);
hold on;
imagesc(mean(spectra3*1E11,3)-mean(spectra2*1E11,3),'AlphaData',mask & significantMask2,[-0.5*cMax 0.5*cMax]);
colormap(gca,cMap2);
axis(gca,'square'); set(gca,'YDir','reverse'); ylim(yLim); xlim(xLim);
yticks([]); xticks([]);
for i = 1:numel(unique(atlasData.atlasUnfilled(:)))-1
    inRegion = atlasData.atlasUnfilled == i;
    inView = false(size(brain1,1)); inView(yLim(1):yLim(2),xLim(1):xLim(2)) = true;
    inRegion = inRegion & inView & mask;
    boundaryLoc = bwboundaries(inRegion);
    lh = plot(boundaryLoc{1}(:,2),boundaryLoc{1}(:,1),'LineWidth',3);
    lh.Color=[0,0,0,0.5];
end
t = title('Old Drug - Old Vehicle'); set(t,'Visible','on');

p(2,3).select();
set(gca,'FontSize',12);
set(gca,'YAxisLocation', 'right');
inRange = freq <= 0.08 & freq >= 0.009;
plot(freq(inRange),log10(gspectra1(inRange)),'b','LineWidth',3); hold on;
plot(freq(inRange),log10(gspectra2(inRange)),'r','LineWidth',3);
plot(freq(inRange),log10(gspectra3(inRange)),'m','LineWidth',3);
legend('YV','OV','OD');
title('Power Spectra','FontSize',16);
ylabel('Power (\muM^2/Hz) [log10]','FontSize',16);
xlabel('Frequency (Hz)','FontSize',16);
grid on;
xlim([0.01 0.08]);
xticks(0.01:0.01:0.08);

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