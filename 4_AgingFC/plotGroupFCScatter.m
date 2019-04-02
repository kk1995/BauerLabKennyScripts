dataFile2 = "L:\ProcessedData\region16FC_gsr.mat";
atlasFile = "D:\data\atlas16.mat";
sigTextY = 0.27;
yRange = [-0.3 0.3];

% sigTextY = 0.97;
% yRange = [0.1 1];

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

f1 = figure('Position',[100 100 1600 600]);

avgY = zeros(2,numel(labels));

regionData = load(dataFile2);
p = [];
for i = 1:numel(labels)
    y1 = regionData.oldFC(i,:,:); y1 = mean(y1,2); y1 = y1(:);
    y2 = regionData.youngFC(i,:,:); y2 = mean(y2,2); y2 = y2(:);
    [~,p(i)] = ttest2(atanh(y1),atanh(y2));
end
significant = mouse.stat.holmBonf(p);

for i = 1:numel(labels)
    y1 = regionData.oldFC(i,:,:); y1 = mean(y1,2); y1 = y1(:);
    avgY(1,i) = mean(y1);
    x = i*ones(size(y1)); x = x + (0.1*randn(size(y1)) - 0.25);
    p1 = scatter(x,y1,7,'b','filled');
    
    hold on;
    
    y2 = regionData.youngFC(i,:,:); y2 = mean(y2,2); y2 = y2(:);
    avgY(2,i) = mean(y2);
    x = i*ones(size(y2)); x = x + (0.1*randn(size(y2)) - 0.15);
    p2 = scatter(x,y2,7,'r','filled');
    
    if p(i) < 0.001
        pStr = '***';
    elseif p(i) < 0.01
        pStr = '**';
    elseif p(i) < 0.05
        pStr = '*';
    else
        pStr = 'n.s.';
    end
    
    if significant(i)
        text(i,sigTextY,pStr,'FontSize',12,'Color','r','HorizontalAlignment','center');
    else
        text(i,sigTextY,pStr,'FontSize',12,'HorizontalAlignment','center');
    end
end

xticks(1:numel(labels));
xticklabels(labels);
xlim([0 numel(labels)+1]);
ylabel('Average correlation (Pearson R)');

middleInd = find(contains(labels,'L'),1,'last');
plot(1:middleInd,avgY(1,1:middleInd),'b','LineWidth',2);
plot(middleInd+1:numel(labels),avgY(1,middleInd+1:numel(labels)),'b','LineWidth',2);
plot(1:middleInd,avgY(2,1:middleInd),'r','LineWidth',2);
plot(middleInd+1:numel(labels),avgY(2,middleInd+1:numel(labels)),'r','LineWidth',2);
ylim(yRange);
xtickangle(45);

legend([p1 p2],'Old','Young','Location','southeast');

% savefig(f1,'D:\figures\4_AgingFC\regionFC.fig');
% saveas(f1,'D:\figures\4_AgingFC\regionFC.tif','tiffn');
% print -r1500
% saveas(f1,'D:\figures\4_AgingFC\regionFC.png','png');