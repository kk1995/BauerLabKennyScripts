function getGroupFC(rowList)

excelFile = fullfile('D:\data','zach_gcamp_stroke_fc_trials.xlsx');
% rowList = 2:167;

sR = 16.8;
saveFolder = "L:\ProcessedData\3_NeurovascularCoupling";

%%

fMin = 0.5;
fMax = 4;

fMinStr = '0p5'; fMaxStr = '4';

%%

load('L:\ProcessedData\gcampStimROI.mat'); %stimROIAll
stimROIAll = logical(stimROIAll);

[~, ~, raw]=xlsread(excelFile,1, ['A',num2str(rowList(1)),':K',num2str(rowList(1))]);

hbFC = [];
fluorFC = [];
mask = [];
rowInd = 0;
prevMouseName = raw{2};
mouseName = prevMouseName;

for row = rowList
    rowInd = rowInd + 1;
    disp(['File # ' num2str(rowInd) '/' num2str(numel(rowList))]);
    
    [~, ~, raw]=xlsread(excelFile,1, ['A',num2str(row),':K',num2str(row)]);
    mouseName = raw{2};
    dataDir = raw{5};
    dataFileName = raw{7};
    sR = raw{11};
    
    if ~strcmp(prevMouseName,mouseName)
        hbFC = nanmean(hbFC,5);
        fluorFC = nanmean(fluorFC,5);
        
        save(fullfile(saveDir,saveFile),'hbFC','fluorFC','mask','stimROIAll','-v7.3');
        hbFC = [];
        fluorFC = [];
        mask = [];
    end
    
    prevMouseName = mouseName;
    
    saveDir = dataDir;
    saveFile = [mouseName '-' fMinStr '-' fMaxStr '-roi-fc.mat'];
    
    % load
    maskData = load(fullfile(dataDir,[dataFileName(1:end-1) '-LandmarksAndMask.mat']));
    hbData = load(fullfile(dataDir,[dataFileName '-datahb.mat']));
    fluorData = load(fullfile(dataDir,[dataFileName '-datafluor.mat']));
    
    % filter
    hbData.xform_datahb = mouse.freq.filterData(hbData.xform_datahb,fMin,fMax,sR);
    fluorData.xform_datafluorCorr = mouse.freq.filterData(fluorData.xform_datafluorCorr,fMin,fMax,sR);
    
    % gsr
    hbData.xform_datahb = mouse.process.gsr(hbData.xform_datahb,maskData.xform_isbrain);
    fluorData.xform_datafluorCorr = mouse.process.gsr(fluorData.xform_datafluorCorr,maskData.xform_isbrain);
    
    % create fc
    hbFCTrial = mouse.conn.getFC(sum(hbData.xform_datahb,3));
    hbFCTrial = atanh(hbFCTrial);
    hbFCTrial(isinf(hbFCTrial)) = 0;
    fluorFCTrial = mouse.conn.getFC(fluorData.xform_datafluorCorr);
    fluorFCTrial = atanh(fluorFCTrial);
    fluorFCTrial(isinf(fluorFCTrial)) = 0;
    
    hbFCTrialROI = nan(128,128,2,4);
    fluorFCTrialROI = nan(128,128,2,4);
    for i = 1:2
        for j = 1:4
            roi = stimROIAll(:,:,i,j);
            hbFCTrial1 = hbFCTrial(roi(:),:);
            hbFCTrial1 = nanmean(hbFCTrial1,1);
            hbFCTrialROI(:,:,i,j) = reshape(hbFCTrial1,128,128);
            
            fluorFCTrial1 = fluorFCTrial(roi(:),:);
            fluorFCTrial1 = nanmean(fluorFCTrial1,1);
            fluorFCTrialROI(:,:,i,j) = reshape(fluorFCTrial1,128,128);
        end
    end
    
    hbFC = cat(5,hbFC,hbFCTrialROI);
    fluorFC = cat(5,fluorFC,fluorFCTrialROI);
    mask = cat(3,mask,maskData.xform_isbrain);
end
end