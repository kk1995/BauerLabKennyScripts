dataFile = "L:\ProcessedData\avgFC_gsr.mat";
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

groupFC = cat(3,yvFC,ovFC,odFC);

clear yvFC
clear ovFC
clear odFC

groupNum = size(groupFC,3);
[B,I] = sort(atlas(:));

groupFC2 = [];
nanInd = [];
for i = 1:groupNum
    fc = groupFC(:,:,i);
    fc = fc(I,I);
    fc(B == 0,:) = [];
    fc(:,B == 0) = [];
    labelInd = B(B > 0);
    
    groupFC2(:,:,i) = fc;
    nanInd(i,:) = isnan(fc(1:(size(fc,1)+1):end));
end
groupFC = groupFC2;
clear groupFC2

groupFC(sum(nanInd,1) > 0,:,:) = [];
groupFC(:,sum(nanInd,1) > 0,:) = [];
labelInd(sum(nanInd,1) > 0) = [];

labelTickStart = [1; find(diff(labelInd) > 0) + 1];
labelTickEnd = [find(diff(labelInd) > 0); numel(labelInd)];

tooSmallInd = find((labelTickEnd - labelTickStart + 1) < round(size(fc,1)*0));
tooSmall = false(numel(labelInd),1);
for i = 1:numel(tooSmallInd)
    tooSmall(tooSmallInd(i) == labelInd) = true;
end

labelInd = labelInd(~tooSmall);

labelTickStart = [1; find(diff(labelInd) > 0) + 1];
labelTickEnd = [find(diff(labelInd) > 0); numel(labelInd)];
labelTickMiddle = round((labelTickStart + labelTickEnd)/2);
labels = labels(unique(labelInd));
groupFC = groupFC(:,~tooSmall,:);
groupFC = groupFC(~tooSmall,:,:);

groupFC(groupFC > 1) = 1;
%% plot

cMap = jet(100);

f1 = figure('Position',[100 50 1500 920]);
p = panel();
p.pack(2,groupNum);

titleStr = ["YV","OV","OD"];
for group = 1:groupNum
    p(1,group).select();
    imagesc(groupFC(:,:,group),[-1 1]); colormap(cMap); colorbar;
    hold on;
    for i = 1:numel(labelTickStart)
        plot([labelTickStart(i) labelTickStart(i)],[1 size(fc,1)],'k');
        plot([1 size(fc,1)],[labelTickStart(i) labelTickStart(i)],'k');
    end
    hold off;
    set(gca,'YDir','reverse'); ylim([0.5 size(groupFC,1)+0.5]); xlim([0.5 size(groupFC,1)+0.5]);
    axis(gca,'square'); yticks(labelTickMiddle); xticks(labelTickMiddle);
    yticklabels(labels); xticklabels(labels); xtickangle(90);
    ax = gca;
    yrule = ax.YAxis;
    yrule.FontSize = 7;
    xrule = ax.XAxis;
    xrule.FontSize = 7;
    title(titleStr(group));
end

p(2,1).select();
diffFC = diff(groupFC(:,:,[2 1]),1,3);
imagesc(diffFC,[-0.31 0.31]); colormap(cMap); colorbar;
hold on;
for i = 1:numel(labelTickStart)
    plot([labelTickStart(i) labelTickStart(i)],[1 size(fc,1)],'k');
    plot([1 size(fc,1)],[labelTickStart(i) labelTickStart(i)],'k');
end
hold off;
set(gca,'YDir','reverse'); ylim([0.5 size(groupFC,1)+0.5]); xlim([0.5 size(groupFC,1)+0.5]);
axis(gca,'square'); yticks(labelTickMiddle); xticks(labelTickMiddle);
yticklabels(labels); xticklabels(labels); xtickangle(90);
ax = gca;
yrule = ax.YAxis;
yrule.FontSize = 7;
xrule = ax.XAxis;
xrule.FontSize = 7;
title('OV - YV');

p(2,2).select();
diffFC = diff(groupFC(:,:,[3 2]),1,3);
imagesc(diffFC,[-0.31 0.31]); colormap(cMap); colorbar;
hold on;
for i = 1:numel(labelTickStart)
    plot([labelTickStart(i) labelTickStart(i)],[1 size(fc,1)],'k');
    plot([1 size(fc,1)],[labelTickStart(i) labelTickStart(i)],'k');
end
hold off;
set(gca,'YDir','reverse'); ylim([0.5 size(groupFC,1)+0.5]); xlim([0.5 size(groupFC,1)+0.5]);
axis(gca,'square'); yticks(labelTickMiddle); xticks(labelTickMiddle);
yticklabels(labels); xticklabels(labels); xtickangle(90);
ax = gca;
yrule = ax.YAxis;
yrule.FontSize = 7;
xrule = ax.XAxis;
xrule.FontSize = 7;
title('OD - OV');

% saveas(f1,'D:\figures\4_AgingFC\groupFC.tif','tiffn');
% print -r1500
% saveas(f1,'D:\figures\4_AgingFC\groupFC.png','png');