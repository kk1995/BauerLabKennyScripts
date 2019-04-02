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

dataFile = "L:\ProcessedData\3_NeurovascularCoupling\g6corrFC-fc-0p5-4-row-2-43.mat";
% dataFile = "L:\ProcessedData\3_NeurovascularCoupling\g6corrFC-fc-0p5-4-row-2-43.mat";
load(dataFile);

%%

figure('Position',[100 100 800 400]);
p = panel();
p.pack(2,4);
p.margin = 5;
for i = 1:numel(labels)
    map = fcAvg(atlas == i,:);
    map(isinf(map)) = nan;
    map = nanmean(map,1);
    map = reshape(map,128,128);
    
    p(ceil(i/4),mod(i-1,4)+1).select();
    set(gca,'Visible','off');
    set(gca,'YDir','reverse');
    imagesc(map,'AlphaData',nanmean(maskTotal,3),[-0.5 0.5]); colorbar; colormap('jet'); axis(gca,'square');
    yticks([]); xticks([]);
    ylim([0.5 127.5]); xlim([0.5 127.5]);
    t = title(labels{i}); set(t,'Visible','on');
end