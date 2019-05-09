excelFile = fullfile('D:\data','zach_gcamp_stroke_stim_left_trials.xlsx');
rowList = 127:168;
% rowList = [126:141 143:167];
blockLenTime = 20; % 5 sec rest, 5 sec stim, 10 sec rest
sR = 16.8;
useGsr = true;
baselineInd = 1:floor(sR*5);

rowStr = [num2str(rowList(1)) '-' num2str(rowList(end))];

[~, ~, raw]=xlsread(excelFile,1, ['A',num2str(rowList(1)),':K',num2str(rowList(1))]);
saveDir = raw{5}; saveDir = fileparts(saveDir);
saveFile = ['zach_gcamp_stroke_stim_left-' rowStr '-blockAvg.mat'];

rowInd = 0;
prevMouseName = raw{2};
hbBlock = [];
fluorBlock = [];
mask = [];
hbBlockMouse = [];
fluorBlockMouse = [];
maskMouse = [];

for row = rowList
    rowInd = rowInd + 1;
    disp(['File # ' num2str(rowInd) '/' num2str(numel(rowList))]);
    
    [~, ~, raw]=xlsread(excelFile,1, ['A',num2str(row),':K',num2str(row)]);
    mouseName = raw{2};
    dataDir = raw{5};
    dataFileName = raw{7};
    sR = raw{11};
    
    if ~strcmp(prevMouseName,mouseName)
        
        hbBlock = cat(5,hbBlock,mean(hbBlockMouse,5));
        fluorBlock = cat(5,fluorBlock,mean(fluorBlockMouse,5));
        mask = cat(3,mask,maskMouse(:,:,1));
        
        prevMouseName = mouseName;
        hbBlockMouse = [];
        fluorBlockMouse = [];
        maskMouse = [];
    end
    
    % load
    maskData = load(fullfile(dataDir,[dataFileName(1:end-1) '-LandmarksAndMask.mat']));
    hbData = load(fullfile(dataDir,[dataFileName '-datahb.mat']));
    fluorData = load(fullfile(dataDir,[dataFileName '-datafluor.mat']));
    
    % gsr
    hbData.xform_datahb = mouse.process.gsr(hbData.xform_datahb,maskData.xform_isbrain);
    fluorData.xform_datafluorCorr = mouse.process.gsr(fluorData.xform_datafluorCorr,maskData.xform_isbrain);
    
    % create block avg
    maskTrial = maskData.xform_isbrain;
    
    [hbBlockTrial, ~] = mouse.preprocess.blockAvg(hbData.xform_datahb,hbData.rawTime,blockLenTime,sR*blockLenTime);
    hbBlockTrial = bsxfun(@minus,hbBlockTrial,mean(hbBlockTrial(:,:,:,baselineInd),4));
    
    [fluorBlockTrial, blockTime] = mouse.preprocess.blockAvg(fluorData.xform_datafluorCorr,fluorData.rawTime,blockLenTime,sR*blockLenTime);
    fluorBlockTrial = bsxfun(@minus,fluorBlockTrial,mean(fluorBlockTrial(:,:,:,baselineInd),4));
    
    hbBlockMouse = cat(5,hbBlockMouse,hbBlockTrial);
    fluorBlockMouse = cat(5,fluorBlockMouse,fluorBlockTrial);
    maskMouse = cat(3,maskMouse,maskTrial);
end

hbBlock = cat(5,hbBlock,mean(hbBlockMouse,5));
fluorBlock = cat(5,fluorBlock,mean(fluorBlockMouse,5));
mask = cat(3,mask,maskMouse(:,:,1));

% save
save(fullfile(saveDir,saveFile),'hbBlock','fluorBlock','blockTime','mask','rowList');
