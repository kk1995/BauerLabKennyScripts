% loads lag analysis data and plots average over all mice
mainDir = 'D:\data\zachRosenthal\archive';

lagMat = cell(4,4);
ampMat = cell(4,4);
mask = cell(4,4);

fMin = 0.009;
fMax = 0.5;

useBaselineWeek = true; % means baseline is used

fMinStr = num2str(fMin);
fMinStr(strfind(fMinStr,'.')) = 'p';

fMaxStr = num2str(fMax);
fMaxStr(strfind(fMaxStr,'.')) = 'p';
figNameExt = [fMinStr 'to' fMaxStr];

fCenter = exp(log(fMax) + log(fMin) / 2);

if fCenter < 1
    cMin = -0.5;
    cMax = 0.5;
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
            lagMat{weekInd,i}(:,:,file) = nanmean(fileData.lagMat{i},3);
            ampMat{weekInd,i}(:,:,file) = nanmean(fileData.ampMat{i},3);
            mask{weekInd,i}(:,:,file) = nanmean(fileData.mask{i},3);
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
        alphaData(alphaData < 1) = 0; % at least 50% of mice need to have data in that pix
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

figure('Position',[100 50 1000 900]);
for week = 1:4
    for species = 1:4
        ind = week + (species-1)*4;
        ax = subplot(4,4,ind);
        
        plotData = ampMatMean{week,species};
        alphaData = maskMean{week,species};
        alphaData(alphaData < 1) = 0; % at least 50% of mice need to have data in that pix
        image1 = imagesc(plotData,[0 1]);
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