close all

% loads lag analysis data and plots average over all mice
mainDir = 'D:\data\zachRosenthal\baseline_lag_dot_GSR_0p009to0p5_old\lag_dot_2528_baseline_GSR_0p009to0p5.mat';
load(mainDir);



for species = 1:numel(lagMat)
    lagMatMean{species} = nanmean(lagMat{species},3);
    ampMatMean{species} = nanmean(ampMat{species},3);
    maskMean{species} = nanmean(mask{species},3);
end

%% plot
for species = 1:numel(lagMat)
    figure('Position',[100 700-(species-1)*300 250 250]);
    
    if species == 1
        cMin = -1; cMax = 1;
    elseif species == 2
        cMin = -5; cMax = 5;
    else
        cMin = -2; cMax = 2;
    end
    
    plotData = lagMatMean{species};
    alphaData = maskMean{species};
    alphaData(alphaData < 0.6) = 0; % at least 50% of mice need to have data in that pix
    image1 = imagesc(plotData,[cMin cMax]);
    set(image1,'AlphaData',alphaData);
    set(gca,'Visible','off');
    colormap('jet');
    colorbar();
end


for species = 1:numel(lagMat)
    figure('Position',[400 700-(species-1)*300 250 250]);
    
    
    plotData = ampMatMean{species};
    alphaData = maskMean{species};
    alphaData(alphaData < 0.6) = 0; % at least 50% of mice need to have data in that pix
    image1 = imagesc(plotData,[0 1]);
    set(image1,'AlphaData',alphaData);
    set(gca,'Visible','off');
    colormap('jet');
    colorbar();
end