% dataFile = "L:\ProcessedData\deborah\avgSeedFC_HbO_gsr.mat";
% dataFile = "L:\ProcessedData\deborah\avg40SeedFC_HbO_gsr.mat";
dataFile = "L:\ProcessedData\deborah\avgRefSeedFC_HbO_gsr.mat";
% atlasFile = "D:\data\atlas12.mat";
atlasFile = "C:\Repositories\GitHub\BauerLab\MATLAB\parameters\+bauerParams\seeds16.mat";

load(dataFile);
load(atlasFile);
seedCenter = round((seedCenter + 5)./10*128);
% numSeeds = numel(seedNames);
numSeeds = 16;
% for i = 1:6
%     seedNames{i} = [seedNames{i} '-L'];
% end
% for i = 7:12
%     seedNames{i} = [seedNames{i} '-R'];
% end
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

close all

figure('Position',[100 100 900 400]);
for groupInd = 1:3
    s = subplot('Position',[((groupInd-1)/3.4)+0.05 0.1 0.28 0.8]);
    imagesc(seedFC(:,:,groupInd),[-1 1]); colormap('jet'); axis(gca,'square');
    xticks(1:numSeeds); yticks([]); xticklabels(seedNames); xtickangle(90);
    title(titleNames{groupInd});
    if groupInd == 1
        yticks(1:numSeeds); yticklabels(seedNames);
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

% yvSeedMap = tanh(yvSeedMap);
% ovSeedMap = tanh(ovSeedMap);
% odSeedMap = tanh(odSeedMap);
% diffMap = tanh(diffMap);


% seedMap = cat(4,yvSeedMap,ovSeedMap,odSeedMap);
seedMap = cat(4,yvSeedMap,ovSeedMap,diffMap);

%% only valid seeds

validSeeds = [3:7 11:15];
seedNames = seedNames(validSeeds);
seedMap = seedMap(:,:,validSeeds,:);
seeds = seeds(:,:,validSeeds);
numSeeds = numel(validSeeds);

%% plot seed map

wlData = load("L:\ProcessedData\deborah\deborahWL.mat");
hemisphereData = load("L:\ProcessedData\deborah\deborahHemisphereMask.mat");
alpha = hemisphereData.leftMask | hemisphereData.rightMask;

cLim = [-1.2 1.2];
cTicks = linspace(cLim(1),cLim(2),5);

for groupInd = 1:2
    %     figure('Position',[100 100 600 700]);
    figure('Position',[100 100 1300 ceil(numSeeds/12)*150]);
    rowMax = ceil(numSeeds/12);
    for seedInd = 1:numSeeds
        %         xLen = 0.28; yLen = 0.21;
        %         xStart = (mod(seedInd-1,3)/3.3)+0.02;
        %         yStart = (4 - ceil(seedInd/3))./4.1 + 0.02;
        
        xLen = 0.07; yLen = (1/(rowMax+0.3));
        rowNum = ceil(seedInd/12);
        colNum = mod(seedInd-1,12)+1;
        xStart = (colNum-1)./(12+1) + 0.02;
        yStart = 0.02+(rowMax-rowNum)*(1/(rowMax+0.3));
        
        s = subplot('Position',[xStart yStart xLen yLen]);
        
        image(wlData.xform_wl,'AlphaData',wlData.xform_isbrain);
        hold on;
        imagesc(squeeze(seedMap(:,:,seedInd,groupInd)),'AlphaData',alpha,...
            cLim); colormap('jet'); axis(gca,'square');
        xticks([]); yticks([]);
        set(gca,'Visible','off');
        
        if seedInd == numSeeds
            pos = get(s,'Position');
            c = colorbar();
            c.FontSize = 9;
            c.Label.String = 'Z(r)';
            c.Label.FontSize = 16;
            c.Ticks = cTicks;
            p = c.Label.Position;
            p(1) = p(1)*0.4;
            c.Label.Position = p;
            set(s,'Position',pos);
        end
        B = bwboundaries(seeds(:,:,seedInd));
        visboundaries(B,'Color','k');
        %                 image(repmat(seeds(:,:,seedInd),[1 1 3]),'AlphaData',seeds(:,:,seedInd));
%         t = title(seedNames{seedInd});
%         set(t,'Visible','on');
    end
end