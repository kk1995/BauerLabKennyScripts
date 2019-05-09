% obtains lag compared to roi obtained from infarct and stim response for
% each mouse.

excelFile = fullfile('D:\data','zach_gcamp_stroke_fc_trials.xlsx');
rowList = 2:167;

sR = 16.8;
saveFolder = "L:\ProcessedData\3_NeurovascularCoupling";

edgeLen = 3;
validRange = round(sR*3);
corrThr = 0.3;

%%

fMin = 1;
fMax = 4;

fMinStr = '1'; fMaxStr = '4';

%%

load('L:\ProcessedData\gcampStimROI.mat'); %stimROIAll
stimROIAll = logical(stimROIAll);
roi = load('D:\data\zachRosenthal\_stim\infarctroi.mat');
stimROIAll(:,:,1,5) = roi.infarctroi;
stimROIAll(:,:,2,5) = roi.infarctroi;
[~, ~, raw]=xlsread(excelFile,1, ['A',num2str(rowList(1)),':K',num2str(rowList(1))]);

hbTLagTime = [];
hbTLagAmp = [];
fluorLagTime = [];
fluorLagAmp = [];
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
        hbTLagTime = nanmean(hbTLagTime,5);
        hbTLagAmp = nanmean(hbTLagAmp,5);
        fluorLagTime = nanmean(fluorLagTime,5);
        fluorLagAmp = nanmean(fluorLagAmp,5);
        
        save(fullfile(saveDir,saveFile),'hbTLagTime','hbTLagAmp',...
            'fluorLagTime','fluorLagAmp','sR','mask','stimROIAll','-v7.3');
        hbTLagTime = [];
        hbTLagAmp = [];
        fluorLagTime = [];
        fluorLagAmp = [];
        mask = [];
    end
    
    prevMouseName = mouseName;
    
    saveDir = dataDir;
    saveFile = [mouseName '-' fMinStr '-' fMaxStr '-roi-lag.mat'];
    
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
    
    hbTLagTimeTrial = nan(128,128,2,4);
    hbTLagAmpTrial = nan(128,128,2,4);
    fluorLagTimeTrial = nan(128,128,2,4);
    fluorLagAmpTrial = nan(128,128,2,4);
    for i = 1:2
        for j = 1:4
            roi = stimROIAll(:,:,i,j);
            [hbTLagTimeTrial(:,:,i,j), hbTLagAmpTrial(:,:,i,j)] = mouse.conn.regionalLag(hbT,roi,edgeLen,validRange,corrThr);
            [fluorLagTimeTrial(:,:,i,j), fluorLagAmpTrial(:,:,i,j)] = mouse.conn.regionalLag(g6,roi,edgeLen,validRange,corrThr);
        end
    end
    hbTLagTimeTrial = hbTLagTimeTrial./sR;
    fluorLagTimeTrial = fluorLagTimeTrial./sR;
    
    hbTLagTime = cat(5,hbTLagTime,hbTLagTimeTrial);
    hbTLagAmp = cat(5,hbTLagAmp,hbTLagAmpTrial);
    fluorLagTime = cat(5,fluorLagTime,fluorLagTimeTrial);
    fluorLagAmp = cat(5,fluorLagAmp,fluorLagAmpTrial);
    mask = cat(3,mask,maskData.xform_isbrain);
end

hbTLagTime = nanmean(hbTLagTime,5);
hbTLagAmp = nanmean(hbTLagAmp,5);
fluorLagTime = nanmean(fluorLagTime,5);
fluorLagAmp = nanmean(fluorLagAmp,5);

save(fullfile(saveDir,saveFile),'hbTLagTime','hbTLagAmp',...
    'fluorLagTime','fluorLagAmp','sR','mask','stimROIAll','-v7.3');