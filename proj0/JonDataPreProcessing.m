dataDir = '/Volumes/NO NAME/Data/15C2M2pre';
maskDir = '/Volumes/NO NAME/Data/mask';
saveDir = '/Volumes/NO NAME/Data/';
[~, saveFile, ~] = fileparts(dataDir);
saveFile = [saveFile '_preprocessed_cat.mat'];

dataFileList = dir(dataDir); dataFileList = fileListPreprocess(dataFileList);
relevantDataFile = false(numel(dataFileList),1);
dataFileNum = zeros(numel(dataFileList),1);
for i = 1:numel(dataFileList)
    if dataFileList(i).bytes > 1E8
        dataFileNum(i) = str2double(dataFileList(i).name(18:strfind(dataFileList(i).name,'.tif')-1));
        relevantDataFile(i) = true;
    end
end
dataFileList = dataFileList(relevantDataFile);
dataFileNum = dataFileNum(relevantDataFile);

% order dataFileList
[dataFileNum, I] = sort(dataFileNum);
dataFileList = dataFileList(I);

maskFileList = dir(maskDir); maskFileList = fileListPreprocess(maskFileList);

fileNumel = numel(dataFileList);
data = [];

for file = 1:fileNumel
    disp(['File # ' num2str(file) '/' num2str(fileNumel)]);
    % find the relevant mask file
    maskNumel = numel(maskFileList);
    relevantMask = false(maskNumel,1);
    dataFileName = dataFileList(file).name;
    dataDate = dataFileName(1:6);
    dataMouse = dataFileName(strfind(dataFileName,'M') + 1);
    for maskInd = 1:maskNumel
        maskName = maskFileList(maskInd).name;
        maskDate = maskName(1:6);
        mousePrevInd = strfind(maskName,'M');
        mousePrevInd = mousePrevInd(1);
        maskMouse = maskName(mousePrevInd + 1);
        if strcmp(maskDate,dataDate) && strcmp(maskMouse,dataMouse)
            relevantMask(maskInd) = true;
        end
    end
    maskFileName = fullfile(maskDir,maskFileList(relevantMask).name);
    
    % preprocessing
    disp('  Preprocessing');
    [~, dataFile, ~, ~, ~, ~] = procOIS(fullfile(dataFileList(file).folder,dataFileList(file).name));
    data = cat(4,data,dataFile);
    mask = load(maskFileName,'isbrain'); mask = mask.isbrain;
end

disp('  Saving');
save(fullfile(saveDir,saveFile),'data','mask');
