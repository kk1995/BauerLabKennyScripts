dataFile = "L:\ProcessedData\deborah\avgNodeDegree_gsr.mat";
iterNum = 2000;

load(dataFile);

brain1 = yvBrain;
brain2 = ovBrain;
brain3 = odBrain;

% normalFactor1 = reshape(repmat(sum(reshape(brain1,[],size(brain1,3)),1),128^2,1),128,128,[]);
% normalFactor2 = reshape(repmat(sum(reshape(brain2,[],size(brain2,3)),1),128^2,1),128,128,[]);
% normalFactor3 = reshape(repmat(sum(reshape(brain3,[],size(brain3,3)),1),128^2,1),128,128,[]);

data1 = yvND*100;
data2 = ovND*100;
data3 = odND*100;

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
atlasFile = "D:\data\atlas12.mat";
load(atlasFile);

labels = seedNames;
labels = labels(1:numel(labels)/2);

scatterLabels = {'Frontal','Motor','SS','RS','Parietal','Visual'};

yvAvg = nan(numel(labels),size(data1,3));
ovAvg = yvAvg; odAvg = yvAvg;

d1 = reshape(data1,128^2,[]);
d2 = reshape(data2,128^2,[]);
d3 = reshape(data3,128^2,[]);

for i = 1:numel(labels)
    yvAvg(i,:) = nanmean(d1(atlas == i,:),1);
    ovAvg(i,:) = nanmean(d2(atlas == i,:),1);
    odAvg(i,:) = nanmean(d3(atlas == i,:),1);   
end

avgY = zeros(3,numel(labels));

for i = 1:numel(labels)
    y1 = yvAvg(i,:);
    avgY(1,i) = mean(y1);
    y2 = ovAvg(i,:);
    avgY(2,i) = mean(y2);
    y3 = odAvg(i,:);
    avgY(3,i) = mean(y3);
end

[B,I] = sort(mean(avgY,1),'descend');

yvAvg = yvAvg(I,:);
ovAvg = ovAvg(I,:);
odAvg = odAvg(I,:);
avgY = avgY(:,I);
scatterLabels = scatterLabels(I);

%%

cMax = 35;
wlData = load("L:\ProcessedData\deborah\deborahWL.mat");
hemisphereData = load("L:\ProcessedData\deborah\deborahHemisphereMask.mat");
topC = [1 0 0]; bottomC = [0 0 1];

cMap = jet(100);
cMap2 = jet(100);
noVasculature = hemisphereData.leftMask | hemisphereData.rightMask;

f1 = figure('Position',[100 50 900 900]);
p = panel();
p.pack(3,1);
p(1,1).pack(1,3);
p(2,1).pack(1,3);
p.margintop = 10;
p.marginbottom = 20;
p.de.margin = 5;
p.marginright = 30;
p.marginleft = 25;
p.de.margintop = 13;

p(1,1,1,1).select();
set(gca,'Color',[1,1,1,0]);
set(gca,'Visible','off');
set(gca,'FontSize',12);
mask = mean(brain1,3) >= 6/7 & fliplr(mean(brain1,3)) >= 6/7 &noVasculature;
image(wlData.xform_wl,'AlphaData',wlData.xform_isbrain);
hold on;
imagesc(nanmean(data1,3),'AlphaData',mask,[0 cMax]); colormap(gca,cMap);
axis(gca,'square'); set(gca,'YDir','reverse'); ylim([1 size(brain1,1)]); xlim([1 size(brain1,1)]);
yticks([]); xticks([]);
t = title('Young Vehicle'); set(t,'Visible','on');

p(1,1,1,2).select();
set(gca,'Color',[1,1,1,0]);
set(gca,'Visible','off');
set(gca,'FontSize',12);
mask = mean(brain2,3) >= 6/7 & fliplr(mean(brain2,3)) >= 6/7 & noVasculature;
image(wlData.xform_wl,'AlphaData',wlData.xform_isbrain);
hold on;
imagesc(nanmean(data2,3),'AlphaData',mask,[0 cMax]); colormap(gca,cMap);
axis(gca,'square'); set(gca,'YDir','reverse'); ylim([1 size(brain1,1)]); xlim([1 size(brain1,1)]);
yticks([]); xticks([]);
t = title('Old Vehicle'); set(t,'Visible','on');

p(1,1,1,3).select();
h1 = gca;
set(gca,'Color',[1,1,1,0]);
set(gca,'Visible','off');
set(gca,'FontSize',12);
mask = mean(brain3,3) >= 6/7 & fliplr(mean(brain3,3)) >= 6/7 & noVasculature;
image(wlData.xform_wl,'AlphaData',wlData.xform_isbrain);
hold on;
imagesc(nanmean(data3,3),'AlphaData',mask,[0 cMax]); colormap(gca,cMap);
axis(gca,'square'); set(gca,'YDir','reverse'); ylim([1 size(brain1,1)]); xlim([1 size(brain1,1)]);
yticks([]); xticks([]);
originalSize = get(gca, 'Position');
ch = colorbar; ylabh = ylabel(ch,'node degree (%)');
set(ylabh,'FontSize',14);
set(ylabh,'Units','normalized');
set(ylabh,'position',get(ylabh,'position') - [0.4 0 0]);
t = title('Old Drug'); set(t,'Visible','on');
set(h1, 'Position', originalSize);

p(2,1,1,2).select();
set(gca,'Color',[1,1,1,0]);
set(gca,'Visible','off');
set(gca,'FontSize',12);
mask = mean(cat(3,brain2,brain1),3) >= 6/7 & fliplr(mean(cat(3,brain2,brain1),3)) >= 6/7 & noVasculature;
image(wlData.xform_wl,'AlphaData',wlData.xform_isbrain);
hold on;
imagesc(mean(data2,3)-mean(data1,3),'AlphaData',mask & significantMask,[-0.5*cMax 0.5*cMax]);
colormap(gca,cMap2);
axis(gca,'square'); set(gca,'YDir','reverse'); ylim([1 size(brain1,1)]); xlim([1 size(brain1,1)]);
yticks([]); xticks([]);
t = title('Old Vehicle - Young Vehicle'); set(t,'Visible','on');

p(2,1,1,3).select();
h1 = gca;
set(gca,'Color',[1,1,1,0]);
set(gca,'Visible','off');
set(gca,'FontSize',12);
mask = mean(cat(3,brain3,brain2),3) >= 6/7 & fliplr(mean(cat(3,brain3,brain2),3)) >= 6/7 & noVasculature;
image(wlData.xform_wl,'AlphaData',wlData.xform_isbrain);
hold on;
imagesc(mean(data3,3)-mean(data2,3),'AlphaData',mask & significantMask2,[-0.5*cMax 0.5*cMax]);
colormap(gca,cMap2);
axis(gca,'square'); set(gca,'YDir','reverse'); ylim([1 size(brain1,1)]); xlim([1 size(brain1,1)]);
yticks([]); xticks([]);
originalSize = get(gca, 'Position');
ch = colorbar; ylabh = ylabel(ch,'node degree (%)');
set(ylabh,'FontSize',14);
set(ylabh,'Units','normalized');
set(ylabh,'position',get(ylabh,'position') - [0.7 0 0]);
t = title('Old Drug - Old Vehicle'); set(t,'Visible','on');
set(h1, 'Position', originalSize);

p(2,1,1,1).select();
set(gca,'Color',[1,1,1,0]);
set(gca,'FontSize',10);
axis(gca,'square');
mask = brain1 > 0;
for i = 1:size(mask,3)
    mask(:,:,i) = mask(:,:,i) & fliplr(mask(:,:,i));
end
yvAll = data1(mask);

mask = brain2 > 0;
for i = 1:size(mask,3)
    mask(:,:,i) = mask(:,:,i) & fliplr(mask(:,:,i));
end
ovAll = data2(mask);

mask = brain3 > 0;
for i = 1:size(mask,3)
    mask(:,:,i) = mask(:,:,i) & fliplr(mask(:,:,i));
end
odAll = data3(mask);

histogram(yvAll,'BinWidth',2,'EdgeColor','auto','FaceAlpha',0.33,'Normalization','probability'); hold on;
histogram(ovAll,'BinWidth',2,'EdgeColor','auto','FaceAlpha',0.33,'Normalization','probability');
histogram(odAll,'BinWidth',2,'EdgeColor','auto','FaceAlpha',0.33,'Normalization','probability');
xlabel('node degree');
ylabel('Probability');
legend('YV','OV','OD');
t = title({'Distribution of','homotopic connectivity'},'FontSize',12); set(t,'Visible','on');
xlim([0 45]);

p(3,1).select();

sigTextY = 36.3;
yRange = [0 38];

pVal = [];
for i = 1:numel(scatterLabels)
    y = [yvAvg(i,:) ovAvg(i,:) odAvg(i,:)]';
    g1 = [ones(7,1); 2*ones(14,1)];
    g2 = [ones(14,1); 2*ones(7,1)];
    pVal(i,:) = anovan(y,{g1,g2},'display','off');
end
significant = [mouse.stat.holmBonf(pVal(:,1)) mouse.stat.holmBonf(pVal(:,2))];

for i = 1:numel(labels)
    
    xCenter = i + 1;
    
    y1 = yvAvg(i,:);
    x = xCenter*ones(size(y1)); x = x + (0.05*randn(size(y1)) - 0.2);
    p1 = scatter(x,y1,7,'b','filled');
    
    hold on;
    
    y2 = ovAvg(i,:);
    x = xCenter*ones(size(y2)); x = x + (0.05*randn(size(y2)));
    p2 = scatter(x,y2,7,'r','filled');
    
    y3 = odAvg(i,:);
    x = xCenter*ones(size(y3)); x = x + (0.05*randn(size(y3)) + 0.2);
    p3 = scatter(x,y3,7,'m','filled');
    
    for j = 1:2
        if pVal(i,j) < 0.001
            pStr = '***';
        elseif pVal(i,j) < 0.01
            pStr = '**';
        elseif pVal(i,j) < 0.05
            pStr = '*';
        else
            pStr = 'n.s.';
        end
        
        if j == 1
            offset = -2.5;
        else
            offset = 0;
        end
        
        if contains(pStr,'n.s.')
            offset = offset + 0.5;
        end
        
        if significant(i,j)
            text(xCenter,sigTextY+offset,pStr,'FontSize',12,'Color','r','HorizontalAlignment','center');
        else
            text(xCenter,sigTextY+offset,pStr,'FontSize',12,'HorizontalAlignment','center');
        end
    end
end

text(1.5,sigTextY + 0.4,'Drug Effect:','FontSize',10,'Color','k','HorizontalAlignment','right');
text(1.5,sigTextY + 0.4 - 2.5,'Age Effect:','FontSize',10,'Color','k','HorizontalAlignment','right');

xticks(2:numel(scatterLabels)+1);
xticklabels(scatterLabels);
xlim([0.5 numel(scatterLabels)+1.5]);
ylabel('Average node degree');

% middleInd = find(contains(labels,'L'),1,'last');
lineX = 2:numel(scatterLabels)+1;
plot(lineX,avgY(1,:),'b','LineWidth',2);
plot(lineX,avgY(2,:),'r','LineWidth',2);
plot(lineX,avgY(3,:),'m','LineWidth',2);
ylim(yRange);
% xtickangle(45);

legend([p1 p2 p3],'Young Vehicle','Old Vehicle','Old Drug','Location','southwest');
title('Regional node degree','FontSize',12);