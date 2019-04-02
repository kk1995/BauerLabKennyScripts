dataFile2 = "L:\ProcessedData\intra16FC_gsr.mat";
atlasFile = "D:\data\atlas16.mat";
% sigTextY = 0.69;
% yRange = [-0.7 0.7];

sigTextY = 1.65;
yRange = [0 1.7];

%%

load(atlasFile);
load(dataFile2);

labels = seedNames;
for i = 1:numel(labels)/2
    labels{i} = [labels{i} '-L'];
end
for i = (numel(labels)/2 + 1):numel(labels)
    labels{i} = [labels{i} '-R'];
end

ovAvg = ovFC;
yvAvg = yvFC;

%% plot

f1 = figure('Position',[100 100 1000 400]);

availableLabels = 1:numel(labels);
bilatLabels = availableLabels;
bilatLabels = bilatLabels + numel(labels);
avgY = zeros(2,numel(labels));

for i = 1:numel(labels)
    y1 = yvAvg(i,:);
    avgY(1,i) = mean(y1);
    y2 = ovAvg(i,:);
    avgY(2,i) = mean(y2);
end

[B,I] = sort(mean(avgY,1),'descend');

yvAvg = yvAvg(I,:);
ovAvg = ovAvg(I,:);
avgY = avgY(:,I);
labels = labels(I);

p = [];
for i = 1:numel(labels)
    y1 = ovAvg(i,:);
    y2 = yvAvg(i,:);
    [~,p(i)] = ttest2(y1,y2);
end
significant = mouse.stat.holmBonf(p);

for i = 1:numel(labels)
    y1 = ovAvg(i,:);
    x = i*ones(size(y1)); x = x + (0.05*randn(size(y1)) + 0.1);
    p1 = scatter(x,y1,7,'b','filled');
    
    hold on;
    
    y2 = yvAvg(i,:);
    x = i*ones(size(y2)); x = x + (0.05*randn(size(y2)) - 0.1);
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
xlim([0.5 numel(labels)+0.5]);
ylabel('Average correlation z(r)');

% middleInd = find(contains(labels,'L'),1,'last');
middleInd = numel(labels);
plot(1:middleInd,avgY(1,:),'b','LineWidth',2);
plot(1:middleInd,avgY(2,:),'r','LineWidth',2);
ylim(yRange);
xtickangle(45);

legend([p1 p2],'Old','Young','Location','southwest');

% savefig(f1,'D:\figures\4_AgingFC\regionBilat.fig');
% saveas(f1,'D:\figures\4_AgingFC\regionBilat.tif','tiffn');
% print -r1500
% saveas(f1,'D:\figures\4_AgingFC\regionBilat.png','png');