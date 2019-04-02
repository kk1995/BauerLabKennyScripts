excelFile = "D:\data\deborahData.xlsx";
pcaData = "L:\ProcessedData\ov-yvPCs.mat";
pcaData2 = "L:\ProcessedData\od-ovPCs.mat";

wlData = load("L:\ProcessedData\deborahWL.mat");
hemisphereData = load("L:\ProcessedData\deborahHemisphereMask.mat");

for comparison = 1:2
    if comparison == 1
        pcaDataObj = matfile(pcaData);
    else
        pcaDataObj = matfile(pcaData2);
    end
    coeff = pcaDataObj.coeff(:,1:2);
    explained = pcaDataObj.explained;
    brain = pcaDataObj.brain;
    noVasculature = hemisphereData.leftMask | hemisphereData.rightMask;
    
    % get coefficients
    coeffs = zeros(128^2,2);
    for i = 1:2
        coeffs(brain,i) = coeff(:,i);
    end
    
    mask = reshape(brain,128,128) & noVasculature;
    
    f1 = figure('Position',[100 50 900 400]);
    p = panel();
    p.pack(1,2);
    for i = 1:2
        p(1,i).select();
        set(gca,'Color','k')
        x = reshape(coeffs(:,i),128,128);
        image(wlData.xform_wl,'AlphaData',wlData.xform_isbrain);
        hold on;
        imagesc(x,'AlphaData',mask); colorbar; colormap('jet');
        axis(gca,'square'); yticks([]); xticks([]);
        set(gca,'YDir','reverse'); ylim([0.5 128.5]); xlim([0.5 128.5]);
        title(['PC' num2str(i) ': ' num2str(explained(i),3) '%']);
    end
end