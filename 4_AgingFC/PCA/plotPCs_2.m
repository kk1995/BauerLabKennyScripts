excelFile = "D:\data\deborahData.xlsx";
pcaData = "L:\ProcessedData\ov-yvPCs_v2.mat";
pcaData2 = "L:\ProcessedData\od-ovPCs_v2.mat";

wlData = load("L:\ProcessedData\deborah\deborahWL.mat");
hemisphereData = load("L:\ProcessedData\deborah\deborahHemisphereMask.mat");

for comparison = 1:2
    if comparison == 1
        pcaDataObj = matfile(pcaData);
    else
        pcaDataObj = matfile(pcaData2);
    end
    coeff = pcaDataObj.coeff(:,1:2);
    explained = pcaDataObj.explained;
    noVasculature = hemisphereData.leftMask | hemisphereData.rightMask;
    
    % get coefficients
    scores = zeros(128^2,2);
    for i = 1:2
        newMat = nan(128^2);
        newMat(pcaDataObj.goodMatrixInd) = coeff(:,i);
        newMat(pcaDataObj.goodMatrixIndUpper) = coeff(:,i);
        x = nansum(newMat,1);
        scores(:,i) = x;
    end
    
    mask = noVasculature;
    
    f1 = figure('Position',[100 50 900 400]);
    p = panel();
    p.pack(1,2);
    for i = 1:2
        p(1,i).select();
        set(gca,'Color','k')
        x = reshape(scores(:,i),128,128);
        image(wlData.xform_wl,'AlphaData',wlData.xform_isbrain);
        hold on;
        imagesc(x,'AlphaData',mask); colorbar; colormap('jet');
        axis(gca,'square'); yticks([]); xticks([]);
        set(gca,'YDir','reverse'); ylim([0.5 128.5]); xlim([0.5 128.5]);
        title(['PC' num2str(i) ': ' num2str(explained(i),3) '%']);
    end
end