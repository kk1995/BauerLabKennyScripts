excelFile = "D:\data\deborahData.xlsx";
atlasFile = "D:\data\atlas12.mat";
saveFile = "avgSeedFC_HbO_gsr.mat";
saveFileTrialPrefix = "seedFC";
rows = 2:22;

load(atlasFile);
atlasParsed = mouse.math.parseMap(atlas);

numSeeds = size(atlasParsed,3);
seeds = false(128*128,numSeeds);
for seedInd = 1:numSeeds
    seedCenter = mouse.math.centerOfMass(atlasParsed(:,:,seedInd));
    seedCenter = round(seedCenter);
    seedCoor = mouse.math.circleCoor(seedCenter,3);
    seedMapInd = mouse.math.matCoor2Ind(seedCoor,[128 128]);
    seeds(seedMapInd,seedInd) = true;
end
seeds = reshape(seeds,128,128,[]);

[~,~,excelData] = xlsread(excelFile,1,['A' num2str(rows(1)) ':' xlscol(5) num2str(max(rows))]);

% get info for each row
fullRawName = [];
for i = 1:size(excelData,1)
    rawName = strcat(num2str(excelData{i,1}),"-",excelData{i,2},"-",excelData{i,3},"-cat.mat");
    fullRawName = [fullRawName fullfile(excelData{i,4},rawName)];
end
saveFolder = string(excelData{1,5});

% load each data, then add the matrix

yvSeedFC = [];
ovSeedFC = [];
odSeedFC = [];
yvSeedMap = [];
ovSeedMap = [];
odSeedMap = [];

groupInd = zeros(3,1);

for i = 1:numel(fullRawName)
    disp([num2str(i) '/' num2str(numel(fullRawName))]);
    trialData = load(fullRawName(i));
    
    data = trialData.xform_datahb;
    data = squeeze(data(:,:,1,:));
    data = mouse.process.gsr(data,trialData.xform_isbrain);
    
    seedMap = nan(128,128,12);
    
    for seedInd = 1:12
        roi = seeds(:,:,seedInd);
        seedMap(:,:,seedInd) = mouse.conn.seedFCMap(data,roi);
    end
    seedFC = mouse.conn.seedFC(data,seeds);
    
    if contains(fullRawName(i),"YV")
        groupInd(1) = groupInd(1) + 1;
        saveFileTrial = fullfile(saveFolder,strcat(saveFileTrialPrefix,"-YV",num2str(groupInd(1)),".mat"));
        save(saveFileTrial,'seedMap','seedFC','-v7.3');
        yvSeedFC = cat(3,yvSeedFC,seedFC);
        yvSeedMap = cat(4,yvSeedMap,seedMap);
    elseif contains(fullRawName(i),"OV")
        groupInd(2) = groupInd(2) + 1;
        saveFileTrial = fullfile(saveFolder,strcat(saveFileTrialPrefix,"-OV",num2str(groupInd(2)),".mat"));
        save(saveFileTrial,'seedMap','seedFC','-v7.3');
        ovSeedFC = cat(3,ovSeedFC,seedFC);
        ovSeedMap = cat(4,ovSeedMap,seedMap);
    elseif contains(fullRawName(i),"OD")
        groupInd(3) = groupInd(3) + 1;
        saveFileTrial = fullfile(saveFolder,strcat(saveFileTrialPrefix,"-OD",num2str(groupInd(3)),".mat"));
        save(saveFileTrial,'seedMap','seedFC','-v7.3');
        odSeedFC = cat(3,odSeedFC,seedFC);
        odSeedMap = cat(4,odSeedMap,seedMap);
    end
end

save(fullfile(saveFolder,saveFile),'seeds','yvSeedFC','ovSeedFC','odSeedFC',...
    'yvSeedMap','ovSeedMap','odSeedMap','-v7.3');