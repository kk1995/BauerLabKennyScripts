dataFile = "L:\ProcessedData\region16FC_gsr.mat";
atlasFile = "D:\data\atlas16.mat";

load(dataFile);
load(atlasFile);

labels = seedNames;
for i = 1:numel(labels)/2
    labels{i} = [labels{i} '-L'];
end
for i = (numel(labels)/2 + 1):numel(labels)
    labels{i} = [labels{i} '-R'];
end

groupFC = [];
nanInd = [];
for i = 1:2
    if i == 1
        fc = oldFC;
    else
        fc = youngFC;
    end
    fc = mean(fc,3);    
    groupFC = cat(3,groupFC,fc);
end

p = nan(size(youngFC,1));
for i = 1:size(youngFC,1)
    for j = 1:size(youngFC,1)
        [~,p(i,j)] = ttest2(atanh(oldFC(i,j,:)),atanh(youngFC(i,j,:)));
    end
end

labelTickStart = 0.5:(size(youngFC,1)-0.5);
labelTickEnd = labelTickStart + 1;

labelTickMiddle = round((labelTickStart + labelTickEnd)/2);

groupFC(groupFC > 1) = 1;
diffFC = tanh(diff(atanh(groupFC),1,3));
diffFC(1:size(diffFC,1)+1:end) = 0;

%% plot

f1 = figure('Position',[100 100 1700 600]);
pl = panel();
pl.pack(1,3);

cMap = mouse.plot.blueWhiteRed(100);

pl(1,1).select();
imagesc(groupFC(:,:,1),[-1 1]); colormap(cMap); colorbar;
hold on;
for i = 1:numel(labelTickStart)
    plot([labelTickStart(i) labelTickStart(i)],[0.5 size(fc,1) + 0.5],'k');
    plot([0.5 size(fc,1)+0.5],[labelTickStart(i) labelTickStart(i)],'k');
end
hold off;
set(gca,'YDir','reverse'); ylim([0.5 size(groupFC,1)+0.5]); xlim([0.5 size(groupFC,1)+0.5]);
axis(gca,'square'); yticks(labelTickMiddle); xticks(labelTickMiddle);
yticklabels(labels); xticklabels(labels); xtickangle(90);
ax = gca;
yrule = ax.YAxis;
yrule.FontSize = 8;
xrule = ax.XAxis;
xrule.FontSize = 8;

pl(1,2).select(); imagesc(groupFC(:,:,2),[-1 1]); colormap(cMap); colorbar;
hold on;
for i = 1:numel(labelTickStart)
    plot([labelTickStart(i) labelTickStart(i)],[0.5 size(fc,1) + 0.5],'k');
    plot([0.5 size(fc,1)+0.5],[labelTickStart(i) labelTickStart(i)],'k');
end
hold off;
set(gca,'YDir','reverse'); ylim([0.5 size(groupFC,1)+0.5]); xlim([0.5 size(groupFC,1)+0.5]);
axis(gca,'square'); yticks(labelTickMiddle); xticks(labelTickMiddle);
yticklabels(labels); xticklabels(labels); xtickangle(90);
ax = gca;
yrule = ax.YAxis;
yrule.FontSize = 8;
xrule = ax.XAxis;
xrule.FontSize = 8;

pl(1,3).select(); imagesc(diffFC,[-0.305 0.305]); colormap(cMap); colorbar;
hold on;
for i = 1:numel(labelTickStart)
    plot([labelTickStart(i) labelTickStart(i)],[0.5 size(fc,1) + 0.5],'k');
    plot([0.5 size(fc,1)+0.5],[labelTickStart(i) labelTickStart(i)],'k');
end
hold off;
set(gca,'YDir','reverse'); ylim([0.5 size(groupFC,1)+0.5]); xlim([0.5 size(groupFC,1)+0.5]);
axis(gca,'square'); yticks(labelTickMiddle); xticks(labelTickMiddle);
yticklabels(labels); xticklabels(labels); xtickangle(90);
ax = gca;
yrule = ax.YAxis;
yrule.FontSize = 8;
xrule = ax.XAxis;
xrule.FontSize = 8;

% saveas(f1,'D:\figures\4_AgingFC\groupFC.tif','tiffn');
% print -r1500
% saveas(f1,'D:\figures\4_AgingFC\groupFC.png','png');

%%
f2 = figure('Position',[100 100 1400 600]);
pl = panel();
pl.pack(1,2);

cmap = jet(256);
cmap(1,:) = zeros(1,3);

pl(1,1).select(); set(gca,'YDir','reverse'); ylim([0.5 size(groupFC,1)+0.5]); xlim([0.5 size(groupFC,1)+0.5]);
title('p value (log 10)');
imagesc(-log10(p),[1.3 3]); colormap(cmap); colorbar;
axis(gca,'square');
yticks(labelTickMiddle); xticks(labelTickMiddle);
yticklabels(labels); xticklabels(labels); xtickangle(90);

lower = mouse.conn.getTriangleInd(size(p,1));
significant = false(size(p,1));
significant(lower) = mouse.stat.holmBonf(p(lower));
pl(1,2).select(); set(gca,'YDir','reverse'); ylim([0.5 size(groupFC,1)+0.5]); xlim([0.5 size(groupFC,1)+0.5]);
title('significant (multiple comparisons)');
imagesc(significant); colormap(cmap); colorbar;
axis(gca,'square');
yticks(labelTickMiddle); xticks(labelTickMiddle);
yticklabels(labels); xticklabels(labels); xtickangle(90);