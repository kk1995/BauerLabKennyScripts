dataFile = "L:\ProcessedData\deborah\avgFC_gsr.mat";
atlasFile = "D:\data\atlas12.mat";

load(dataFile);
load(atlasFile);

% labels = seedNames;
labels = {'Frontal','Motor','SS','RS','Parietal','Visual'};
labels = repmat(labels,1,2);
% for i = 1:numel(labels)/2
%     labels{i} = [labels{i} '-L'];
% end
% for i = (numel(labels)/2 + 1):numel(labels)
%     labels{i} = [labels{i} '-R'];
% end

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
groupFC = real(groupFC);
clear groupFC2

groupFC(sum(nanInd,1) > 0,:,:) = [];
groupFC(:,sum(nanInd,1) > 0,:) = [];
labelInd(sum(nanInd,1) > 0) = [];

labelTickStart = [1; find(diff(labelInd) > 0) + 1];
labelTickEnd = [find(diff(labelInd) > 0); numel(labelInd)];

labelTickStart = [1; find(diff(labelInd) > 0) + 1];
labelTickEnd = [find(diff(labelInd) > 0); numel(labelInd)];
labelTickMiddle = round((labelTickStart + labelTickEnd)/2);
labels = labels(unique(labelInd));

%% intraregional
dataFile2 = "L:\ProcessedData\deborah\intra12FC_gsr.mat";
atlasFile = "D:\data\atlas12.mat";

load(atlasFile);
load(dataFile2);

% labels = seedNames;
% for i = 1:numel(labels)/2
%     labels{i} = [labels{i} '-L'];
% end
% for i = (numel(labels)/2 + 1):numel(labels)
%     labels{i} = [labels{i} '-R'];
% end

%%

ovAvg = ovFC;
yvAvg = yvFC;
odAvg = odFC;

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

scatterLabels = labels;
for i = 1:numel(scatterLabels)/2
    scatterLabels{i} = [scatterLabels{i} '-L'];
end
for i = (numel(scatterLabels)/2 + 1):numel(scatterLabels)
    scatterLabels{i} = [scatterLabels{i} '-R'];
end
scatterLabels = scatterLabels(I);

%% plot

sigTextY = 1.73;
yRange = [0 1.8];

cMap = jet(100);

f1 = figure('Position',[100 50 1080 920]);
p = panel();
p.margin = 20;
p.marginright = 20;
p.pack(2,2);

titleStr = ["Young Vehicle","Old Vehicle","Old Drug"];
for group = 1:groupNum
    p(ceil(group/2),mod(group-1,2) + 1).select();
    set(gca,'FontSize',12);
    imagesc(groupFC(:,:,group),[-1.2 1.2]); colormap(cMap);
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
    yrule.FontSize = 9;
    xrule = ax.XAxis;
    xrule.FontSize = 9;
    pause(0.1);
    title(titleStr(group));
    ch = colorbar; ylabh = ylabel(ch,'correlation coefficient, z(r)');
    set(ylabh,'Units','normalized');
    set(ylabh,'position',get(ylabh,'position') - [0.3 0 0]);
end

p(2,2).select();
set(gca,'YAxisLocation', 'right');

availableLabels = 1:numel(labels);
bilatLabels = availableLabels;
bilatLabels = bilatLabels + numel(labels);

pVal = [];
for i = 1:numel(scatterLabels)
    y = [yvAvg(i,:) ovAvg(i,:) odAvg(i,:)]';
    g1 = [ones(7,1); 2*ones(14,1)];
    g2 = [ones(14,1); 2*ones(7,1)];
    pVal(i,:) = anovan(y,{g1,g2},'display','off');
end
significant = mouse.stat.holmBonf(pVal(:,1));

for i = 1:numel(scatterLabels)
    
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
            offset = -0.1;
        else
            offset = 0;
        end
        
        if contains(pStr,'n.s.')
            offset = offset + 0.035;
        end
        
        if j == 1
            if significant(i)
                text(xCenter,sigTextY+offset,pStr,'FontSize',12,'Color','r','HorizontalAlignment','center');
            else
                text(xCenter,sigTextY+offset,pStr,'FontSize',12,'HorizontalAlignment','center');
            end
        else
            text(xCenter,sigTextY+offset,pStr,'FontSize',12,'HorizontalAlignment','center');
        end
    end
end

text(1.5,sigTextY + 0.03,'Drug Effect:','FontSize',10,'Color','k','HorizontalAlignment','right');
text(1.5,sigTextY + 0.03 - 0.1,'Age Effect:','FontSize',10,'Color','k','HorizontalAlignment','right');

xticks(2:numel(scatterLabels)+1);
xticklabels(scatterLabels);
xlim([0.5 numel(scatterLabels)+1.5]);
ylabel('Average correlation z(r)');

middleInd = numel(scatterLabels);
plot(2:middleInd+1,avgY(1,:),'b','LineWidth',2);
plot(2:middleInd+1,avgY(2,:),'r','LineWidth',2);
plot(2:middleInd+1,avgY(3,:),'m','LineWidth',2);
ylim(yRange);
xtickangle(45);

legend([p1 p2 p3],'Young Vehicle','Old Vehicle','Old Drug','Location','southwest');
