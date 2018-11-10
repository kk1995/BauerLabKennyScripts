% loads lag analysis data and plots average over all mice
mainDir = 'D:\data\zachRosenthal\';

lagMat = cell(4,4);
ampMat = cell(4,4);
mask = cell(4,4);

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
    subFolder = [week '_lag_bilateral_0p5to5'];
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
for week = 1:numel(lagMat)
    f1 = figure('Position',[100 50 800 600]);
    for i = 1:size(lagMat{week},3); subplot(3,5,i); imagesc(lagMat{week}(:,:,i),[-0.5 0.5]); colormap('jet'); title(num2str(i)); end
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
    
    goodMice{week} = true(1,size(lagMat{week},3));
    goodMice{week}(badMice) = false;
end

for i = 1:numel(lagMat)
    lagMat{i} = nanmean(lagMat{i}(:,:,goodMice{i}),3);
    ampMat{i} = nanmean(ampMat{i}(:,:,goodMice{i}),3);
    mask{i} = nanmean(mask{i}(:,:,goodMice{i}),3);
end

%% plot

figure('Position',[100 50 1000 900]);
for week = 1:4
    for species = 1:4
        i = week + (species-1)*4;
        ax = subplot(4,4,i);
        plotData = nan(128,128);
        plotData(:,1:64) = lagMat{i}(:,1:64);
        alphaData = mask{i};
        alphaData(alphaData < 0.5) = 0; % at least 50% of mice need to have data in that pix
        alphaData(isnan(plotData)) = 0;
        %     image1 = imagesc(plotData,[-0.25 0.25]);
        image1 = imagesc(plotData,[-0.1 0.1]);
        set(image1,'AlphaData',alphaData);
        set(gca,'Visible','off');
        colormap('jet');
        if i == 16
            
            s4Pos = get(ax,'position');
            colorbar();
            
            set(ax,'Position',s4Pos);
        end
    end
end

% figure('Position',[100 50 1000 900]);
% % for i = 1:16
% for i = 1:4:16
%     ax = subplot(4,4,i);
%     
%     plotData = ampMat{i};
%     alphaData = mask{i};
%     alphaData(alphaData < 0.5) = 0; % at least 50% of mice need to have data in that pix
%     image1 = imagesc(plotData,[0 1]);
%     set(image1,'AlphaData',alphaData);
%     set(gca,'Visible','off');
%     colormap('jet');
%     if i == 16
%         
%         s4Pos = get(ax,'position');
%         colorbar();
%         
%         set(ax,'Position',s4Pos);
%     end
% end