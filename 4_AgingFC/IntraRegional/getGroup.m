excelFile = "D:\data\deborahData.xlsx";
atlasFile = "D:\data\atlas12.mat";
saveFile = "intra12FC_gsr.mat";
rows = 2:22;

load(atlasFile);

[~,~,excelData] = xlsread(excelFile,1,['A' num2str(rows(1)) ':' xlscol(5) num2str(max(rows))]);

% get info for each row
fullRawName = [];
for i = 1:size(excelData,1)
    rawName = strcat(num2str(excelData{i,1}),"-",excelData{i,2},"-",excelData{i,3},"-cat.mat");
    fullRawName = [fullRawName fullfile(excelData{i,4},rawName)];
end
saveFolder = string(excelData{1,5});

% load each data, then add the matrix

yvFC = [];
ovFC = [];
odFC = [];

for i = 1:numel(fullRawName)
    disp([num2str(i) '/' num2str(numel(fullRawName))]);
    trialData = load(fullRawName(i));
    
    data = trialData.xform_datahb;
    data = squeeze(data(:,:,1,:));
    data = mouse.process.gsr(data,trialData.xform_isbrain);    
    fcMap = mouse.conn.getFC(data);
    fcMap = atanh(fcMap);
    fcMap(isinf(fcMap)) = nan;
    
    fcMap2 = nan(numel(seedNames),1);
    for j = 1:numel(seedNames)
        regionData = fcMap(atlas==j,atlas==j);
        regionData = regionData(:);
        fcMap2(j) = nanmean(regionData);
    end
    fcMap = fcMap2;
        
    if contains(fullRawName(i),"YV")
        yvFC = cat(2,yvFC,fcMap);
    elseif contains(fullRawName(i),"OV")
        ovFC = cat(2,ovFC,fcMap);
    elseif contains(fullRawName(i),"OD")
        odFC = cat(2,odFC,fcMap);
    end
end

save(fullfile(saveFolder,saveFile),'yvFC','ovFC','odFC','-v7.3');