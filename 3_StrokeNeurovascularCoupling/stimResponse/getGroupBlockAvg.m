excelFile = fullfile('D:\data','zach_gcamp_stroke_stim_trials.xlsx');
rowList = 2:43;
blockLenTime = 20; % 5 sec rest, 5 sec stim, 10 sec rest
sR = 16.8;
useGsr = true;
baselineInd = 1:floor(sR*5);

rowStr = [num2str(rowList(1)) '-' num2str(rowList(end))];

[~, ~, raw]=xlsread(excelFile,1, ['A',num2str(rowList(1)),':K',num2str(rowList(1))]);
saveDir = raw{5}; saveDir = fileparts(saveDir);
saveFile = [rowStr '-blockAvg.mat'];

rowInd = 0;
prevMouseName = [];
hbBlock = [];
fluorBlock = [];

for row = rowList
    rowInd = rowInd + 1;
    disp(['File # ' num2str(row) '/' num2str(numel(rowList))]);
    
    [~, ~, raw]=xlsread(excelFile,1, ['A',num2str(row),':K',num2str(row)]);
    mouseName = raw{2};
    dataDir = raw{5};
    dataFileName = raw{7};
    sR = raw{11};
    
    if ~strcmp(prevMouseName,mouseName)
        
        hbBlock = cat(5,hbBlock,mean(hbBlockMouse,5));
        fluorBlock = cat(5,fluorBlock,mean(fluorBlockMouse,5));
        
        prevMouseName = mouseName;
        hbBlockMouse = [];
        fluorBlockMouse = [];
    end
    
    % load and get block avg
    trialData = load(fullfile(dataDir,[dataFileName '-blockAvg.mat']));
    
    hbBlockMouse = cat(5,hbBlockMouse,trialData.hbBlock);
    fluorBlockMouse = cat(5,fluorBlockMouse,trialData.fluorBlock);
end

% save
save(fullfile(saveDir,saveFile),'hbBlock','fluorBlock','blockTime','I','wl','xform_isbrain');
