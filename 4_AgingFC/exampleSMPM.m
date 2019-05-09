dataFile = "L:\ProcessedData\avgSpectra0p01to0p08_gsr.mat";
iterNum = 2000; %the number of permutatioms u want to do
fRange = [0.01 0.08];

load(dataFile);

spectra1 = yvSpectra; %data in 128x128x numsubjects gouup 1
spectra2 = ovSpectra;

brain1 = yvBrain; %bain mask
brain2 = ovBrain;

spectra1 = permute(spectra1,[3 1 2]); %put the mouse inthe first dim
spectra2 = permute(spectra2,[3 1 2]);

totalMat = cat(1,spectra1,spectra2);  %put them together
[~,~,~,z] = ttest2(spectra1,spectra2); %run the actual Ttest
testMat = squeeze(z.tstat); %creating the matrix rmo the Z struct
nullMat = zeros(128,128,iterNum); %initialize

for i = 1:iterNum
    if mod(i,100) == 0
        disp(num2str(i));
    end
    randOrder = randperm(14); %14 is the 7 + 7 number of subjects,  
    [~,~,~,z] = ttest2(totalMat(randOrder(1:7),:,:),totalMat(randOrder(8:14),:,:)); %shuffles the groups and run the ttest to get a matrix of t-values
    nullMat(:,:,i) = z.tstat; %put them into null matrix
end

group1N = sum(brain1,3);
group2N = sum(brain2,3);
tThr = tinv(0.975,round((group1N + group2N)./2)); %get t threshold only in the isbrain

[clusterLoc,clusterP,clusterT,tDist] = clusterTestMaris(nullMat,testMat,tThr);

significantMask = zeros(128);
for i = 1:numel(clusterLoc)
    if clusterP(i) < 0.05
        significantMask(clusterLoc{i}) = 1;
    end
end


%% plotting

yLim = [6 123];
xLim = [6 123];

cMax = 10E-11;
wlData = load("L:\ProcessedData\deborah\deborahWL.mat");
hemisphereData = load("L:\ProcessedData\deborah\deborahHemisphereMask.mat");
atlasData = load("D:\data\atlas12.mat");

topC = [1 0 0]; bottomC = [0 0 1];

cMap = mouse.plot.whiteMiddle(topC,bottomC,100,[0 1]);
cMap2 = mouse.plot.whiteMiddle(topC,bottomC,100);
noVasculature = hemisphereData.leftMask | hemisphereData.rightMask;

f1 = figure('Position',[100 100 1400 800]);
p = panel();
p.pack(2,3);
 
p(1,1).select();
set(gca,'Color',[1,1,1,0]);
set(gca,'Visible','off');
set(gca,'FontSize',12);
mask = mean(brain1,3) >= 6/7 & noVasculature;
image(wlData.xform_wl,'AlphaData',wlData.xform_isbrain);
hold on;
imagesc(mean(spectra1,3),'AlphaData',mask,[0 cMax]); colormap(gca,cMap); colorbar;
axis(gca,'square'); set(gca,'YDir','reverse'); ylim(yLim); xlim(xLim);
yticks([]); xticks([]);
title('Young Vehicle');
for i = 1:numel(unique(atlasData.atlasUnfilled(:)))-1
    boundaryLoc = bwboundaries(atlasData.atlasUnfilled == i);
    lh = plot(boundaryLoc{1}(:,2),boundaryLoc{1}(:,1),'LineWidth',3);
    lh.Color=[0,0,0,0.5];
end

p(1,2).select();
set(gca,'Color',[1,1,1,0]);
set(gca,'Visible','off');
set(gca,'FontSize',12);
mask = mean(brain2,3) >= 6/7 & noVasculature;
image(wlData.xform_wl,'AlphaData',wlData.xform_isbrain);
hold on;
imagesc(mean(spectra2,3),'AlphaData',mask,[0 cMax]); colormap(gca,cMap); colorbar;
axis(gca,'square'); set(gca,'YDir','reverse'); ylim(yLim); xlim(xLim);
yticks([]); xticks([]);
title('Old Vehicle');
for i = 1:numel(unique(atlasData.atlasUnfilled(:)))-1
    boundaryLoc = bwboundaries(atlasData.atlasUnfilled == i);
    lh = plot(boundaryLoc{1}(:,2),boundaryLoc{1}(:,1),'LineWidth',3);
    lh.Color=[0,0,0,0.5];
end

p(1,3).select();
set(gca,'Color',[1,1,1,0]);
set(gca,'Visible','off');
set(gca,'FontSize',12);
mask = mean(brain3,3) >= 6/7 & noVasculature;
image(wlData.xform_wl,'AlphaData',wlData.xform_isbrain);
hold on;
imagesc(mean(spectra3,3),'AlphaData',mask,[0 cMax]); colormap(gca,cMap); colorbar;
axis(gca,'square'); set(gca,'YDir','reverse'); ylim(yLim); xlim(xLim);
yticks([]); xticks([]);
title('Old Drugged');
for i = 1:numel(unique(atlasData.atlasUnfilled(:)))-1
    boundaryLoc = bwboundaries(atlasData.atlasUnfilled == i);
    lh = plot(boundaryLoc{1}(:,2),boundaryLoc{1}(:,1),'LineWidth',3);
    lh.Color=[0,0,0,0.5];
end

p(2,1).select(); %ploting difference between groups, thresholded for sig clusters
set(gca,'Color',[1,1,1,0]);
set(gca,'Visible','off');
set(gca,'FontSize',12);
mask = mean(cat(3,brain2,brain1),3) >= 6/7 & noVasculature;
image(wlData.xform_wl,'AlphaData',wlData.xform_isbrain);
hold on;
imagesc(mean(spectra2,3)-mean(spectra1,3),'AlphaData',mask & significantMask,[-0.5*cMax 0.5*cMax]);
colormap(gca,cMap2); colorbar;
axis(gca,'square'); set(gca,'YDir','reverse'); ylim(yLim); xlim(xLim);
yticks([]); xticks([]);
title('OV - YV power');
for i = 1:numel(unique(atlasData.atlasUnfilled(:)))-1
    boundaryLoc = bwboundaries(atlasData.atlasUnfilled == i);
    lh = plot(boundaryLoc{1}(:,2),boundaryLoc{1}(:,1),'LineWidth',3);
    lh.Color=[0,0,0,0.5];
end

p(2,2).select();
set(gca,'Color',[1,1,1,0]);
set(gca,'Visible','off');
set(gca,'FontSize',12);
mask = mean(cat(3,brain3,brain2),3) >= 6/7 & noVasculature;
image(wlData.xform_wl,'AlphaData',wlData.xform_isbrain);
hold on;
imagesc(mean(spectra3,3)-mean(spectra2,3),'AlphaData',mask & significantMask2,[-0.5*cMax 0.5*cMax]);
colormap(gca,cMap2); colorbar;
axis(gca,'square'); set(gca,'YDir','reverse'); ylim(yLim); xlim(xLim);
yticks([]); xticks([]);
title('OD - OV power');
for i = 1:numel(unique(atlasData.atlasUnfilled(:)))-1
    boundaryLoc = bwboundaries(atlasData.atlasUnfilled == i);
    lh = plot(boundaryLoc{1}(:,2),boundaryLoc{1}(:,1),'LineWidth',3);
    lh.Color=[0,0,0,0.5];
end

p(2,3).select();
set(gca,'FontSize',12);
inRange = freq <= 0.08 & freq >= 0.009;
plot(freq(inRange),log10(gspectra1(inRange)),'LineWidth',3); hold on;
plot(freq(inRange),log10(gspectra2(inRange)),'LineWidth',3);
plot(freq(inRange),log10(gspectra3(inRange)),'LineWidth',3);
legend('YV','OV','OD');
title('Power Spectra (log10 scale)');

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