% loads lag analysis data and plots average over all mice
mainDir = 'D:\data\zachRosenthal\';

lagMat = cell(1,4);
ampMat = cell(1,4);
mask = cell(1,4);

fMin = 0.02;
fMax = 2;

useBaselineWeek = true; % means baseline is used

useVisualCheck = false;

fMinStr = num2str(fMin);
fMinStr(strfind(fMinStr,'.')) = 'p';

fMaxStr = num2str(fMax);
fMaxStr(strfind(fMaxStr,'.')) = 'p';
figNameExt = [fMinStr 'to' fMaxStr];

fCenter = exp(log(fMax) + log(fMin) / 2);

if fCenter < 1
    cMin = -5;
    cMax = 5;
else
    cMin = -0.5;
    cMax = 0.5;
end

for weekInd = 1:4
    if weekInd == 1
        week = 'baseline';
    elseif weekInd == 2
        week = 'week1';
    elseif weekInd == 3
        week = 'week4';
    else
        week = 'week8';
    end
    subFolder = [week '_lag_dot_' figNameExt '_HbT_GCaMP'];
    dataDir = fullfile(mainDir,subFolder);
    D = dir(dataDir); D(1:2) = [];
    for file = 1:numel(D)
        fileData = load(fullfile(dataDir,D(file).name));
        
        % get mouse avg
        lagMat{weekInd}(:,:,file) = fileData.lagMouse;
        ampMat{weekInd}(:,:,file) = fileData.ampMouse;
        mask{weekInd}(:,:,file) = nanmean(fileData.maskMouse,3);
        
    end
end

% visually checking for control
goodMice = cell(1,4);
if useVisualCheck
    for species = 1:size(lagMat,2)
        if species == 1
            cMin = -0.5; cMax = 0.5;
        elseif species == 2
            cMin = -5; cMax = 5;
        else
            cMin = -2; cMax = 2;
        end
        for week = 1:4
            f1 = figure('Position',[100 50 800 600]);
            for i = 1:size(lagMat{week,species},3); subplot(3,5,i); imagesc(lagMat{week,species}(:,:,i),2*[cMin cMax]); colormap('jet'); title(num2str(i)); end
            prompt = 'Which mice are bad runs (''separate by comma'')?';
            badMice = inputdlg(prompt);
            close(f1);
            badMice = strsplit(badMice{:},',');
            for i = 1:numel(badMice)
                if isempty(badMice{i})
                    badMice{i} = [];
                else
                    badMice{i} = str2double(badMice{i});
                end
            end
            badMice = cell2mat(badMice);
            goodMice{week,species} = true(1,size(lagMat{week,species},3));
            goodMice{week,species}(badMice) = false;
        end
    end
else
    for i = 1:numel(goodMice)
        goodMice{i} = true(1,size(lagMat{i},3));
        goodMice{i}(6) = false;
    end
end

for week = 1:4
    lagMatMean{week} = nanmean(lagMat{week}(:,:,goodMice{week}),3);
    ampMatMean{week} = nanmean(ampMat{week}(:,:,goodMice{week}),3);
    maskMean{week} = nanmean(mask{week}(:,:,goodMice{week}),3);
end


%% plot
species = 1;

figure('Position',[100 700-(species-1)*250 550 250]);
p = panel();
p.pack('h',{0.23 0.23 0.23 0.23});
p.margin = [0 3 3 0];
for n = 1:4
    p(n).pack(2);
end

if species == 1
    cMin = -0.8; cMax = 0.8;
elseif species == 2
    cMin = -5; cMax = 5;
else
    cMin = -2; cMax = 2;
end

cMap = jet(100);

for week = 1:4
    ind = week;
    ax = p(week,1).select();
    set(ax,'Color','k');
    set(gca,'xtick',[])
    set(gca,'xticklabel',[])
    set(gca,'ytick',[])
    set(gca,'yticklabel',[])
    axis(ax,'square');

    plotData = lagMatMean{week};
    alphaData = maskMean{week};
    alphaData(alphaData < 0.6) = 0; % at least 50% of mice need to have data in that pix
    
    if week == 4
        plotBrain(ax,plotData,alphaData,[cMin cMax],cMap,true);
    else
        plotBrain(ax,plotData,alphaData,[cMin cMax],cMap);
    end
    
    ax = p(week,2).select();
    set(ax,'Color','k');
    set(gca,'xtick',[])
    set(gca,'xticklabel',[])
    set(gca,'ytick',[])
    set(gca,'yticklabel',[])
    axis(ax,'square');

    plotData = ampMatMean{week};
    alphaData = maskMean{week};
    alphaData(alphaData < 0.6) = 0; % at least 50% of mice need to have data in that pix
    if week == 4
        plotBrain(ax,plotData,alphaData,[0 1],cMap,true);
    else
        plotBrain(ax,plotData,alphaData,[0 1],cMap);
    end
end

% species = 1;
% figure('Position',[700 700-(species-1)*250 1000 250]);
% 
% for week = 1:4
%     ind = week;
%     ax = subplot(1,4,ind);
%     
%     plotData = ampMatMean{week,species};
%     alphaData = maskMean{week,species};
%     alphaData(alphaData < 0.6) = 0; % at least 50% of mice need to have data in that pix
%     image1 = imagesc(plotData,[0 1]);
%     set(image1,'AlphaData',alphaData);
%     set(gca,'Visible','off');
%     colormap('jet');
%     if ind == 4
%         
%         s4Pos = get(ax,'position');
%         colorbar();
%         
%         set(ax,'Position',s4Pos);
%     end
% end
% 
