% obtains lag compared to roi obtained from infarct and stim response for
% each mouse.

excelFile = fullfile('D:\data','zach_gcamp_stroke_fc_trials.xlsx');
rowList = 44:83;

saveFolder = "L:\ProcessedData\3_NeurovascularCoupling";

%%

fMin = 0.01;
fMax = 0.08;

fMinStr = '0p01'; fMaxStr = '0p08';

%%

[~, ~, raw]=xlsread(excelFile,1, ['A',num2str(rowList(1)),':K',num2str(rowList(1))]);

hbTFC = [];
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
        hbTFC = nanmean(hbTFC,3);
        fluorFC = nanmean(fluorFC,3);
        
        save(fullfile(saveDir,saveFile),'hbTFC','fluorFC','mask','-v7.3');
        hbTFC = [];
        fluorFC = [];
        mask = [];
    end
    
    prevMouseName = mouseName;
    
    saveDir = dataDir;
    saveFile = [mouseName '-' fMinStr '-' fMaxStr '-homotopic-connectivity.mat'];
    
    % load
    maskData = load(fullfile(dataDir,[dataFileName(1:end-1) '-LandmarksAndMask.mat']));
    hbData = load(fullfile(dataDir,[dataFileName '-datahb.mat']));
    fluorData = load(fullfile(dataDir,[dataFileName '-datafluor.mat']));
    
    % filter
    hbData.xform_datahb = mouse.freq.filterData(hbData.xform_datahb,fMin,fMax,sR);
    fluorData.xform_datafluorCorr = mouse.freq.filterData(fluorData.xform_datafluorCorr,fMin,fMax,sR);
    
    % create lag data
    hbT = squeeze(sum(hbData.xform_datahb,3));
    g6 = squeeze(fluorData.xform_datafluorCorr);
    
    hbTFCTrial = mouse.conn.bilateralFC(hbT);
    fluorFCTrial = mouse.conn.bilateralFC(g6);
    
    hbTFC = cat(3,hbTFC,hbTFCTrial);
    fluorFC = cat(3,fluorFC,fluorFCTrial);
    mask = cat(3,mask,maskData.xform_isbrain);
end