function getGroupFCV2(rowList,fRange)
% loads in seedFC data and organizes the data into mouse averages

excelFile = fullfile('D:\data','zach_gcamp_stroke_fc_trials.xlsx');
% rowList = 2:167;

sR = 16.8;
saveDir = "L:\ProcessedData";

%%

fMin = fRange(1);
fMax = fRange(2);
freqStr = [num2str(fMin),'-',num2str(fMax)];
freqStr(strfind(freqStr,'.')) = 'p';

%%

load('L:\ProcessedData\gcampStimROI.mat'); %stimROIAll
stimROIAll = logical(stimROIAll);

[~, ~, raw]=xlsread(excelFile,1, ['A',num2str(rowList(1)),':K',num2str(rowList(1))]);

hbFC = [];
fluorFC = [];
mask = [];

hbFCMouse = [];
fluorFCMouse = [];
maskMouse = [];
rowInd = 0;
prevMouseName = raw{2};
mouseName = prevMouseName;

[~,prefix] = fileparts(excelFile);
saveFile = [prefix '-rows' num2str(rowList(1)) '~' num2str(rowList(end)) ...
    '-roiFC-' freqStr '.mat'];

for row = rowList
    rowInd = rowInd + 1;
    disp(['File # ' num2str(rowInd) '/' num2str(numel(rowList))]);
    
    [~, ~, raw]=xlsread(excelFile,1, ['A',num2str(row),':K',num2str(row)]);
    mouseName = raw{2};
    dataDir = raw{5};
    dataFileName = raw{7};
    sR = raw{11};
    
    if ~strcmp(prevMouseName,mouseName)
        hbFCMouse = nanmean(hbFCMouse,3);
        fluorFCMouse = nanmean(fluorFCMouse,3);
        maskMouse = nanmean(maskMouse,3);
        
        hbFC = cat(3,hbFC,hbFCMouse);
        fluorFC = cat(3,fluorFC,fluorFCMouse);
        mask = cat(3,mask,maskMouse);
        
        hbFCMouse = [];
        fluorFCMouse = [];
        maskMouse = [];
    end
    
    prevMouseName = mouseName;
    
    % load fc data
    dataFile = [dataFileName '-seedFCHbTG6-' freqStr '-11199-135.mat'];
    trialData = load(fullfile(dataDir,dataFile));
        
    maskData = load(fullfile(dataDir,[dataFileName(1:end-1) '-LandmarksAndMask.mat']));
    
    hbFCTrialROI = nan(2,4);
    fluorFCTrialROI = nan(2,4);
    for i = 1:2
        for j = 1:4
            roi = stimROIAll(:,:,i,j);
            hbFCTrial1 = trialData.fcHbTrial(roi);
            hbFCTrial1 = nanmean(hbFCTrial1);
            hbFCTrialROI(i,j) = hbFCTrial1;
            
            fluorFCTrial1 = trialData.fcFluorTrial(roi);
            fluorFCTrial1 = nanmean(fluorFCTrial1);
            fluorFCTrialROI(i,j) = fluorFCTrial1;
        end
    end
    
    hbFCMouse = cat(3,hbFCMouse,hbFCTrialROI);
    fluorFCMouse = cat(3,fluorFCMouse,fluorFCTrialROI);
    maskMouse = cat(3,maskMouse,maskData.xform_isbrain);
end

hbFCMouse = nanmean(hbFCMouse,3);
fluorFCMouse = nanmean(fluorFCMouse,3);
maskMouse = nanmean(maskMouse,3);

hbFC = cat(3,hbFC,hbFCMouse);
fluorFC = cat(3,fluorFC,fluorFCMouse);
mask = cat(3,mask,maskMouse);

save(fullfile(saveDir,saveFile),'hbFC','fluorFC','mask','stimROIAll','-v7.3');

end