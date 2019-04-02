% hbFiles = ["D:\ProcessedData\190223\190223-1111M1-stim-Pre-datahb.mat",...
%     "D:\ProcessedData\190223\190223-1111M1-stim-Post-datahb.mat",...
%     "D:\ProcessedData\190223\190223-1111M3-stim-Pre-datahb.mat",...
%     "D:\ProcessedData\190223\190223-1111M3-stim-Post-datahb.mat"];
% fluorFiles = ["D:\ProcessedData\190223\190223-1111M1-stim-Pre-dataFluor.mat",...
%     "D:\ProcessedData\190223\190223-1111M1-stim-Post-dataFluor.mat",...
%     "D:\ProcessedData\190223\190223-1111M3-stim-Pre-dataFluor.mat",...
%     "D:\ProcessedData\190223\190223-1111M3-stim-Post-dataFluor.mat"];
% speckleFiles = ["D:\ProcessedData\190223\190223-1111M1-stim-Pre-dataSpeckle.mat",...
%     "D:\ProcessedData\190223\190223-1111M1-stim-Post-dataSpeckle.mat",...
%     "D:\ProcessedData\190223\190223-1111M3-stim-Pre-dataSpeckle.mat",...
%     "D:\ProcessedData\190223\190223-1111M3-stim-Post-dataSpeckle.mat"];
% maskFiles = ["D:\ProcessedData\190223\190223-1111M1-stim-LandmarksandMask.mat",...
%     "D:\ProcessedData\190223\190223-1111M1-stim-LandmarksandMask.mat",...
%     "D:\ProcessedData\190223\190223-1111M3-stim-LandmarksandMask.mat",...
%     "D:\ProcessedData\190223\190223-1111M3-stim-LandmarksandMask.mat"];

hbFiles = ["D:\ProcessedData\190305\190305-1111M1-stim-Pre-datahb.mat",...
    "D:\ProcessedData\190305\190305-1111M1-stim-Post-datahb.mat"];
fluorFiles = ["D:\ProcessedData\190305\190305-1111M1-stim-Pre-dataFluor.mat",...
    "D:\ProcessedData\190305\190305-1111M1-stim-Post-dataFluor.mat"];
speckleFiles = ["D:\ProcessedData\190305\190305-1111M1-stim-Pre-dataSpeckle.mat",...
    "D:\ProcessedData\190305\190305-1111M1-stim-Post-dataSpeckle.mat"];
maskFiles = ["D:\ProcessedData\190305\190305-1111M1-stim-LandmarksandMask.mat",...
    "D:\ProcessedData\190305\190305-1111M1-stim-LandmarksandMask.mat"];

roiSeed = [81 19];

for trialInd = 2:numel(hbFiles)
    load(hbFiles(trialInd));
    load(fluorFiles(trialInd));
    load(speckleFiles(trialInd));
    load(maskFiles(trialInd));
    
    xform_isbrain = mouse.process.affineTransform(isbrain,I);
    xform_isbrain = mouse.math.bin(xform_isbrain,4); xform_isbrain = xform_isbrain >= 8;
    xform_datahb = mouse.process.gsr(xform_datahb,xform_isbrain);
    xform_datafluorCorr = mouse.process.gsr(xform_datafluorCorr,xform_isbrain);
    baselineInd = mod(rawTime,60) < 5;
    xform_cbf = mouse.process.smoothImage(xform_cbf,5,1.2);
    xform_isbrainSmooth = mouse.process.smoothImage(xform_isbrain,5,1.2);
    xform_isbrainSmooth = xform_isbrainSmooth > 1 - 10*eps;
    xform_cbfMean = mean(xform_cbf(:,:,:,baselineInd),4);
    xform_cbf = mouse.process.gsr(xform_cbf,xform_isbrainSmooth);
    for t = 1:size(xform_cbf,4)
        xform_cbf(:,:,1,t) = xform_cbf(:,:,1,t)./xform_cbfMean;
    end
    
    [blockHb,blockHbTime] = mouse.preprocess.blockAvg(xform_datahb,rawTime,60,60);
    [blockFluor,blockFluorTime] = mouse.preprocess.blockAvg(xform_datafluorCorr,fluorTime,60,12);
    blockFluorTime = 1:5:60;
    [blockCBF,blockCBFTime] = mouse.preprocess.blockAvg(xform_cbf,rawTime,60,60);
    
    figure('Position',[100 100 1200 800]);
    for i = 1:60
        subplot(6,10,i);
        imagesc(squeeze(blockHb(:,:,1,i)),[-5E-6 5E-6]); axis(gca,'square'); yticks([]); xticks([]);
        colormap('jet');
    end
    
    figure('Position',[100 100 1200 800]);
    for i = 1:60
        subplot(6,10,i);
        imagesc(squeeze(blockCBF(:,:,1,i)),[-1E-1 1E-1]); axis(gca,'square'); yticks([]); xticks([]);
        colormap('jet');
    end
    
    figure('Position',[100 100 1000 600]);
    for i = 1:12
        subplot(3,4,i);
        imagesc(squeeze(blockFluor(:,:,1,i)),[-1E-2 1E-2]); axis(gca,'square'); yticks([]); xticks([]);
        colormap('jet');
        title(num2str(blockFluorTime(i)));
    end
    
    stimTime = blockHbTime > 8 & blockHbTime <= 11;
    baseTime = blockHbTime <= 5;
    stimMap = squeeze(mean(blockHb(:,:,1,stimTime),4));
    roi = mouse.expSpecific.getROI(stimMap,roiSeed);
    
    roiBlockHb = reshape(blockHb,size(blockHb,1)*size(blockHb,2),2,[]);
    roiBlockHb = roiBlockHb(roi,:,:); roiBlockHb = nanmean(roiBlockHb,1); roiBlockHb = squeeze(roiBlockHb);
    roiBlockHb = bsxfun(@minus,roiBlockHb,mean(roiBlockHb(:,baseTime),2));
    baseFluorTime = blockFluorTime <= 5;
    roiBlockFluor = reshape(blockFluor,size(blockFluor,1)*size(blockFluor,2),1,[]);
    roiBlockFluor = roiBlockFluor(roi,:,:); roiBlockFluor = nanmean(roiBlockFluor,1); roiBlockFluor = squeeze(roiBlockFluor);
    roiBlockFluor = bsxfun(@minus,roiBlockFluor,mean(roiBlockFluor(baseFluorTime)));
    roiCBF = reshape(blockCBF,size(blockCBF,1)*size(blockCBF,2),1,[]);
    roiCBF = roiCBF(roi,:,:); roiCBF = nanmean(roiCBF,1); roiCBF = squeeze(roiCBF);
    roiCBF = roiCBF - mean(roiCBF(baseTime));
    
    figure('Position',[100 100 400 400]);
    imagesc(roi); axis(gca,'square'); yticks([]); xticks([]); 
    
    figure('Position',[100 100 900 800]);
    roiHb = reshape(xform_datahb,size(xform_datahb,1)*size(xform_datahb,2),2,[]);
    roiHb = squeeze(mean(roiHb(roi,:,:),1));
    roiFluor = reshape(xform_datafluor,size(xform_datafluor,1)*size(xform_datafluor,2),1,[]);
    roiFluor = squeeze(mean(roiFluor(roi,:,:),1));
    roiFluorCorr = reshape(xform_datafluorCorr,size(xform_datafluorCorr,1)*size(xform_datafluorCorr,2),1,[]);
    roiFluorCorr = squeeze(mean(roiFluorCorr(roi,:,:),1));
    subplot(2,1,1);
    plot(rawTime,roiHb(1,:),'r'); hold on; plot(rawTime,roiHb(2,:),'b');
    title('Hb');
    xlabel('time (s)');
    subplot(2,1,2);
    plot(fluorTime,roiFluor); hold on; plot(fluorTime,roiFluorCorr);
    title('Fluor corrected');
    xlabel('time (s)'); 
    
    figure('Position',[100 100 900 800]);
    subplot(3,1,1);
    plot(blockHbTime,roiBlockHb(1,:),'r'); hold on; plot(blockHbTime,roiBlockHb(2,:),'b');
    plot(blockHbTime,sum(roiBlockHb,1),'k');
    title('Hb');
    xlabel('time (s)'); ylabel('Hb change (uM)');
    subplot(3,1,2);
    plot(blockFluorTime,roiBlockFluor);
    title('Fluor corrected');
    xlabel('time (s)'); ylabel('ratiometric');
    subplot(3,1,3);
    plot(blockHbTime,100*roiCBF); title('CBF'); xlabel('time (s)'); ylabel('% change');
    
end