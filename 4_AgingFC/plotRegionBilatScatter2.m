dataFile2 = "L:\ProcessedData\region16FC_gsr.mat";
atlasFile = "D:\data\atlas16.mat";
% sigTextY = 0.69;
% yRange = [-0.7 0.7];

sigTextY = 1.05;
yRange = [0 1.1];

%%

load(atlasFile);

labels = seedNames;
for i = 1:numel(labels)/2
    labels{i} = [labels{i} '-L'];
end
for i = (numel(labels)/2 + 1):numel(labels)
    labels{i} = [labels{i} '-R'];
end


%% plot

f1 = figure('Position',[100 100 200*ceil(numel(labels)/4) 800]);
pl = panel();
pl.pack(4,ceil(numel(labels)/4));
availableLabels = 1:numel(labels);
left = contains(labels,'L');
bilatLabels = availableLabels;
bilatLabels(left) = bilatLabels(left) + find(left,1,'last');
bilatLabels(~left) = bilatLabels(~left) - find(left,1,'last');
avgY = zeros(2,numel(labels));

regionData = load(dataFile2);
p = [];
for i = 1:numel(labels)
    y1 = regionData.oldFC(availableLabels(i),bilatLabels(i),:); y1 = y1(:);
    y2 = regionData.youngFC(availableLabels(i),bilatLabels(i),:); y2 = y2(:);
    [~,p(i)] = ttest2(atanh(y1),atanh(y2));
end
significant = mouse.stat.holmBonf(p);

for i = 1:numel(labels)
    row = ceil(i/ceil(numel(labels)/4));
    col = mod(i - 1,ceil(numel(labels)/4)) + 1;
    pl(row,col).select();
    
    y1 = regionData.oldFC(availableLabels(i),bilatLabels(i),:); y1 = y1(:);
    y2 = regionData.youngFC(availableLabels(i),bilatLabels(i),:); y2 = y2(:);
    p1 = scatter(y1,y2,7,'b','filled');
    xlabel('old'); ylabel('young');
    title(labels{i});
    
    hold on;
end

% savefig(f1,'D:\figures\4_AgingFC\regionBilat.fig');
% saveas(f1,'D:\figures\4_AgingFC\regionBilat.tif','tiffn');
% print -r1500
% saveas(f1,'D:\figures\4_AgingFC\regionBilat.png','png');