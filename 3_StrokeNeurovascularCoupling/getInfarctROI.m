% plots lag relative to region

excelFile = fullfile('D:\data','zach_gcamp_stroke_fc_trials.xlsx');
rowList = 44:83;

sR = 16.8;
saveFolder = "L:\ProcessedData\3_NeurovascularCoupling";

%%

fMin = 0.01;
fMax = 0.08;

fMinStr = '0p01'; fMaxStr = '0p08';

%%

hbFC = [];
fluorFC = [];
mask = [];

% make data file list
dataFileList = [];
for row = rowList
    [~, ~, raw]=xlsread(excelFile,1, ['A',num2str(row),':K',num2str(row)]);
    mouseName = raw{2};
    dataDir = raw{5};
    dataFile = [mouseName '-' fMinStr '-' fMaxStr '-homotopic-connectivity.mat'];
    dataFileList = [dataFileList string(fullfile(dataDir,dataFile))];
end
dataFileList = unique(dataFileList);

% concatenate multiple mouse lag data
rowInd = 0;

for dataFile = dataFileList
    rowInd = rowInd + 1;
    disp(['File # ' num2str(rowInd) '/' num2str(numel(dataFileList))]);
    
    try
        mouseData = load(dataFile);
        
        hbFC = cat(3,hbFC,mouseData.hbTFC);
        fluorFC = cat(3,fluorFC,mouseData.fluorFC);
        mask = cat(3,mask,mean(mouseData.mask,3) > 0);
    catch
    end
end

%% get roi

roiCandidate = false(128); roiCandidate(50:70,23:45) = true;
infarctroi = nanmean(fluorFC,3) < 0.3 & roiCandidate;

save('D:\ProcessedData\zachInfarctROI.mat','infarctroi','-v7.3');
