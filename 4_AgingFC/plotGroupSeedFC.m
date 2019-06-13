dataFile = "L:\ProcessedData\deborah\avgSeedFC_HbO_gsr.mat";
atlasFile = "D:\data\atlas12.mat";

load(dataFile);
load(atlasFile);
for i = 1:6
    seedNames{i} = [seedNames{i} '-L'];
end
for i = 7:12
    seedNames{i} = [seedNames{i} '-R'];
end
titleNames = {'Young Vehicle','Old Vehicle','Old Drug'};

%% get seed fc matrix

yvSeedFC = atanh(yvSeedFC);
ovSeedFC = atanh(ovSeedFC);
odSeedFC = atanh(odSeedFC);

yvSeedFC = nanmean(yvSeedFC,3);
ovSeedFC = nanmean(ovSeedFC,3);
odSeedFC = nanmean(odSeedFC,3);

yvSeedFC = tanh(yvSeedFC);
ovSeedFC = tanh(ovSeedFC);
odSeedFC = tanh(odSeedFC);

seedFC = cat(3,yvSeedFC,ovSeedFC,odSeedFC);

%% plot seed fc matrix

figure('Position',[100 100 900 400]);
for groupInd = 1:3
    s = subplot('Position',[((groupInd-1)/3.4)+0.05 0.1 0.28 0.8]);
    imagesc(seedFC(:,:,groupInd),[-1 1]); colormap('jet'); axis(gca,'square');
    xticks(1:12); yticks([]); xticklabels(seedNames); xtickangle(90);
    title(titleNames{groupInd});
    if groupInd == 1
        yticks(1:12); yticklabels(seedNames); 
    end
    if groupInd == 3
        pos = get(s,'Position');
        c = colorbar();
        c.FontSize = 12;
        c.Label.String = 'r';
        c.Label.FontSize = 16;
        p = c.Label.Position;
        p(1) = p(1)*0.6;
        c.Label.Position = p;
        set(s,'Position',pos);
    end
end

%% get seed map

yvSeedMap = atanh(yvSeedMap);
ovSeedMap = atanh(ovSeedMap);
odSeedMap = atanh(odSeedMap);

yvSeedMap = nanmean(yvSeedMap,4);
ovSeedMap = nanmean(ovSeedMap,4);
odSeedMap = nanmean(odSeedMap,4);

diffMap = ovSeedMap - yvSeedMap;

yvSeedMap = tanh(yvSeedMap);
ovSeedMap = tanh(ovSeedMap);
odSeedMap = tanh(odSeedMap);
diffMap = tanh(diffMap);


% seedMap = cat(4,yvSeedMap,ovSeedMap,odSeedMap);
seedMap = cat(4,yvSeedMap,ovSeedMap,diffMap);

%% plot seed map
wlData = load("L:\ProcessedData\deborah\deborahWL.mat");
hemisphereData = load("L:\ProcessedData\deborah\deborahHemisphereMask.mat");
alpha = hemisphereData.leftMask | hemisphereData.rightMask;

cLim = [-0.3 0.3];
cTicks = linspace(cLim(1),cLim(2),5);

for groupInd = 1:3
%     figure('Position',[100 100 600 700]);
    figure('Position',[100 100 1300 250]);
    for seedInd = 1:12
%         xLen = 0.28; yLen = 0.21;
%         xStart = (mod(seedInd-1,3)/3.3)+0.02;
%         yStart = (4 - ceil(seedInd/3))./4.1 + 0.02;
        
        xLen = 0.07; yLen = 0.8;
        xStart = (seedInd-1)./13 + 0.02;
        yStart = 0.1;
        
        s = subplot('Position',[xStart yStart xLen yLen]);
        
        image(wlData.xform_wl,'AlphaData',wlData.xform_isbrain);
        hold on;
        imagesc(squeeze(seedMap(:,:,seedInd,groupInd)),'AlphaData',alpha,...
            cLim); colormap('jet'); axis(gca,'square');
        xticks([]); yticks([]);
        set(gca,'Visible','off');
        
        if seedInd == 12
            pos = get(s,'Position');
            c = colorbar();
            c.FontSize = 9;
            c.Label.String = 'r';
            c.Label.FontSize = 16;
            c.Ticks = cTicks;
            p = c.Label.Position;
            p(1) = p(1)*0.4;
            c.Label.Position = p;
            set(s,'Position',pos);
        end
        image(seeds(:,:,seedInd),'AlphaData',seeds(:,:,seedInd));
%         t = title(seedNames{seedInd});
%         set(t,'Visible','on');
    end
end