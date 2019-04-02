atlasFile = "D:\data\atlas8.mat";

load(atlasFile);

labels = seedNames;
for i = 1:numel(labels)/2
    labels{i} = [labels{i} '-L'];
end
for i = (numel(labels)/2 + 1):numel(labels)
    labels{i} = [labels{i} '-R'];
end


%%

% dataFile = "L:\ProcessedData\3_NeurovascularCoupling\hbtFC-fc-0p5-4-row-2-43.mat";
dataFile = "L:\ProcessedData\3_NeurovascularCoupling\g6corrFC-fc-0p009-0p5-row-2-43.mat";
load(dataFile);

nanInd = sum(maskTotal,3) == 0;
notAtlas = atlas == 0;
goodInd = ~nanInd & ~notAtlas; goodInd = goodInd(:);

fcAvg = fcAvg(goodInd,goodInd);
[B,I] = sort(atlas(goodInd));

fcAvg = fcAvg(I,I);

labelInd = B;
labelTickStart = [1; find(diff(labelInd) > 0) + 1];
labelTickEnd = [find(diff(labelInd) > 0); numel(labelInd)];

tooSmallInd = find((labelTickEnd - labelTickStart + 1) < round(size(fcAvg,1)*0));
tooSmall = false(numel(labelInd),1);
for i = 1:numel(tooSmallInd)
    tooSmall(tooSmallInd(i) == labelInd) = true;
end

labelInd = labelInd(~tooSmall);

labelTickStart = [1; find(diff(labelInd) > 0) + 1];
labelTickEnd = [find(diff(labelInd) > 0); numel(labelInd)];
labelTickMiddle = round((labelTickStart + labelTickEnd)/2);
labels = labels(unique(labelInd));
fcAvg = fcAvg(:,~tooSmall,:);
fcAvg = fcAvg(~tooSmall,:,:);

%% plot

cMap = jet(100);

f1 = figure('Position',[100 50 920 880]);

imagesc(fcAvg,[-1 1]); colormap(cMap); colorbar;
hold on;
for i = 1:numel(labelTickStart)
    plot([labelTickStart(i) labelTickStart(i)],[1 size(fcAvg,1)],'k');
    plot([1 size(fcAvg,1)],[labelTickStart(i) labelTickStart(i)],'k');
end
hold off;
set(gca,'YDir','reverse'); ylim([0.5 size(fcAvg,1)+0.5]); xlim([0.5 size(fcAvg,1)+0.5]);
axis(gca,'square'); yticks(labelTickMiddle); xticks(labelTickMiddle);
yticklabels(labels); xticklabels(labels); xtickangle(90);
ax = gca;
yrule = ax.YAxis;
yrule.FontSize = 10;
xrule = ax.XAxis;
xrule.FontSize = 10;
