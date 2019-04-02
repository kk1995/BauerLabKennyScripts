% loads lag analysis data and plots average over all mice
mainDir = 'D:\data\zachRosenthal\analysis';

lagMat = cell(4,4);
ampMat = cell(4,4);
mask = cell(4,4);

fMin = 0.009;
fMax = 0.5;

useBaselineWeek = false; % means baseline is used

fMinStr = num2str(fMin);
fMinStr(strfind(fMinStr,'.')) = 'p';

fMaxStr = num2str(fMax);
fMaxStr(strfind(fMaxStr,'.')) = 'p';
figNameExt = [fMinStr 'to' fMaxStr];

fCenter = exp(log(fMax) + log(fMin) / 2);

if fCenter < 1
    cMin = -0.3;
    cMax = 0.3;
else
    cMin = -0.02;
    cMax = 0.02;
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
    subFolder = [week '_lag_gs_' figNameExt];
    dataDir = fullfile(mainDir,subFolder);
    D = dir(dataDir); D(1:2) = [];
    for file = 1:numel(D)
        fileData = load(fullfile(dataDir,D(file).name));
        
        % get mouse avg
        for i = 1:4
            lagMat{weekInd,i}(:,:,file) = nanmean(fileData.lagMouse,3);
            ampMat{weekInd,i}(:,:,file) = nanmean(fileData.ampMouse,3);
            mask{weekInd,i}(:,:,file) = nanmean(fileData.maskMouse,3);
        end
        
    end
end

% visually checking for control
goodMice = cell(4,4);
for species = 1:4
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

% significance
lagP = cell(4,3);
for species = 1:4
    for week = 2:4
        baseWeek = baseline(week,useBaselineWeek);
        data1 = permute(lagMat{baseWeek,species}(:,:,goodMice{baseWeek,species}),[3 1 2]);
        data2 = permute(lagMat{week,species}(:,:,goodMice{week,species}),[3 1 2]);
        [~,p] = ttest2(data1,data2);
        lagP{week-1,species} = squeeze(p);
    end
end

for species = 1:4
    for week = 1:4
        lagMatMean{week,species} = nanmean(lagMat{week,species}(:,:,goodMice{week,species}),3);
        ampMatMean{week,species} = nanmean(ampMat{week,species}(:,:,goodMice{week,species}),3);
        maskMean{week,species} = nanmean(mask{week,species}(:,:,goodMice{week,species}),3);
    end
end

%% plot
figure('Position',[100 50 1000 900]);
for week = 1:4
    for species = 1:4
        ind = week + (species-1)*4;
        ax = subplot(4,4,ind);
        
        plotData = lagMatMean{week,species};
        alphaData = maskMean{week,species};
        alphaData(alphaData < 0.6) = 0; % at least 50% of mice need to have data in that pix
        image1 = imagesc(plotData,[cMin cMax]);
        set(image1,'AlphaData',alphaData);
        set(gca,'Visible','off');
        colormap('jet');
        if ind == 16
            
            s4Pos = get(ax,'position');
            colorbar();
            
            set(ax,'Position',s4Pos);
        end
    end
end

cMap = mouse.plot.blueWhiteRed(100,[0 1],1);
figure('Position',[100 50 750 900]);
for week = 2:4
    for species = 1:4
        i = (week-1) + (species-1)*3;
        ax = subplot(4,3,i);
        
        plotData = lagP{week-1,species};
        plotData = log(plotData)/log(10);
        alphaData = maskMean{1};
        alphaData(alphaData < 0.6) = 0; % at least 50% of mice need to have data in that pix
        image1 = imagesc(plotData,[-8 0]);
        set(gca,'XTick',[]);
        set(gca,'YTick',[]);
        set(image1,'AlphaData',alphaData);
%         set(gca,'Visible','off');
        colormap(cMap);
        if i == 12
            
            s4Pos = get(ax,'position');
            colorbar();
            
            set(ax,'Position',s4Pos);
        end
    end
end

figure('Position',[100 50 750 900]);
for week = 2:4
    for species = 1:4
        baseWeek = baseline(week,useBaselineWeek);
        ind = (species-1)*3+week-1;
        ax = subplot(4,3,ind);
        set(gca,'color',0.5*[1 1 1]);
        plotData = lagMatMean{week,species} - lagMatMean{baseWeek,species};
        %     plotData = lagMatMean{i+4} - lagMatMean{i};
        alphaData = maskMean{1};
        alphaData(lagP{week-1,species} > 0.05) = 0;
        alphaData(alphaData < 0.6) = 0; % at least 50% of mice need to have data in that pix
        image1 = imagesc(plotData,[cMin cMax]);
        set(image1,'AlphaData',alphaData);
        colormap('jet');
        if ind == 12
            
            s4Pos = get(ax,'position');
            colorbar();
            
            set(ax,'Position',s4Pos);
        end
        set(gca,'color',0.5*[1 1 1]);
    end
end

figure('Position',[100 50 750 900]);
for week = 2:4
    for species = 1:4
        baseWeek = baseline(week,useBaselineWeek);
        ind = (species-1)*3+week-1;
        ax = subplot(4,3,ind);
        set(gca,'color',0.5*[1 1 1]);
        plotData = lagMatMean{week,species} - lagMatMean{baseWeek,species};
        reject = holmBonf(lagP{week-1,species});
        %     plotData = lagMatMean{i+4} - lagMatMean{i};
        alphaData = maskMean{1};
        alphaData(~reject) = 0;
        alphaData(lagP{week-1,species} > 0.05) = 0;
        alphaData(alphaData < 0.6) = 0; % at least 50% of mice need to have data in that pix
        image1 = imagesc(plotData,[cMin cMax]);
        set(image1,'AlphaData',alphaData);
        colormap('jet');
        if ind == 12
            
            s4Pos = get(ax,'position');
            colorbar();
            
            set(ax,'Position',s4Pos);
        end
        set(gca,'color',0.5*[1 1 1]);
    end
end


%%