excelFile = fullfile('D:\data','zach_gcamp_stroke_stim_trials.xlsx');
rowList = 2:43;
blockLenTime = 20; % 5 sec rest, 5 sec stim, 10 sec rest
sR = 16.8;
useGsr = true;
baselineInd = 1:floor(sR*5);

rowInd = 0;
for row = rowList
    rowInd = rowInd + 1;
    disp(['File # ' num2str(row) '/' num2str(numel(rowList))]);
    
    [~, ~, raw]=xlsread(excelFile,1, ['A',num2str(row),':K',num2str(row)]);
    mouseName = raw{2};
    dataDir = raw{5};
    dataFileName = raw{7};
    sR = raw{11};
    
    saveFile = [dataFileName '-blockAvg.mat'];
    
    % load and get block avg
    load(fullfile(dataDir,[dataFileName(1:end-1) '-LandmarksAndMask.mat']));
    load(fullfile(dataDir,[dataFileName '-datahb.mat']));
    load(fullfile(dataDir,[dataFileName '-datafluor.mat']));
    
    wl = mouse.process.affineTransform(WL,I);

    [hbBlock, ~] = mouse.preprocess.blockAvg(xform_datahb,rawTime,blockLenTime,sR*blockLenTime);
    hbBlock = bsxfun(@minus,hbBlock,mean(hbBlock(:,:,:,baselineInd),4));
    
    [fluorBlock, blockTime] = mouse.preprocess.blockAvg(xform_datafluorCorr,rawTime,blockLenTime,sR*blockLenTime);
    fluorBlock = bsxfun(@minus,fluorBlock,mean(fluorBlock(:,:,:,baselineInd),4));
    
    % save
    save(fullfile(dataDir,saveFile),'hbBlock','fluorBlock','blockTime','I','wl','xform_isbrain');
end