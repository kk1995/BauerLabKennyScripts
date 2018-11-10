% loads regional FC data and plots average over all mice

mainDir = 'D:\data\zachRosenthal\';

fcMat = cell(4,4);
mask = cell(4,4);
for speciesInd = 1:4
    if speciesInd == 1
        species = 'HbO';
    elseif speciesInd == 2
        species = 'HbR';
    elseif speciesInd == 3
        species = 'HbT';
    else
        species = 'GCaMP';
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
        subFolder = [week '_' species '_fc_L_canonical_0p5to5-GSR'];
        dataDir = fullfile(mainDir,subFolder);
        D = dir(dataDir); D(1:2) = [];
        
        fcMat{weekInd,speciesInd} = nan(128,128,numel(D));
        mask{weekInd,speciesInd} = fcMat{weekInd,speciesInd};
        
        for file = 1:numel(D)
            fileData = load(fullfile(dataDir,D(file).name));
            
            % get mouse avg
            if strcmp(species,'HbO')
                fcMat{weekInd,speciesInd}(:,:,file) = nanmean(fileData.fcDataHbO,3);
            elseif strcmp(species,'HbR')
                fcMat{weekInd,speciesInd}(:,:,file) = nanmean(fileData.fcDataHbR,3);
            elseif strcmp(species,'HbT')
                fcMat{weekInd,speciesInd}(:,:,file) = nanmean(fileData.fcDataHbT,3);
            else
                fcMat{weekInd,speciesInd}(:,:,file) = nanmean(fileData.fcDataGCaMP,3);
            end
            mask{weekInd,speciesInd}(:,:,file) = nanmean(fileData.xform_mask,3);
        end
        
        fcMat{weekInd,speciesInd} = nanmean(fcMat{weekInd,speciesInd},3);
        mask{weekInd,speciesInd} = nanmean(mask{weekInd,speciesInd},3);
        
    end
end

%% plot

% figure('Position',[100 100 600 500]);

figure('Position',[100 100 1000 900]);
for i = 1:16
    ax = subplot(4,4,i);
    
    plotData = fcMat{i};
    alphaData = mask{i};
    alphaData(alphaData < 0.5) = 0; % at least 50% of mice need to have data in that pix
    image1 = imagesc(plotData,[-1 1]);
    set(image1,'AlphaData',alphaData);
    set(gca,'Visible','off');
    colormap('jet');
    if i == 16
        
        s4Pos = get(ax,'position');
        colorbar();
        
        set(ax,'Position',s4Pos);
    end
end