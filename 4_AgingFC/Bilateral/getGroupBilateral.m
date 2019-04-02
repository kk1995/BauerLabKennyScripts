excelFile = "D:\data\deborahData.xlsx";
saveFile = "avgBilateral_gsr.mat";
rows = 2:22;

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
yvBrain = [];
ovBrain = [];
odBrain = [];

for i = 1:numel(fullRawName)
    disp([num2str(i) '/' num2str(numel(fullRawName))]);
    trialData = load(fullRawName(i));
    
    data = trialData.xform_datahb;
    data = squeeze(data(:,:,1,:));
    data = mouse.process.gsr(data,trialData.xform_isbrain);
    fcMap = mouse.conn.bilateralFC(data);
    fcMap = atanh(fcMap);
    
    if contains(fullRawName(i),"YV")
        yvFC = cat(3,yvFC,fcMap);
        yvBrain = cat(3,yvBrain,trialData.xform_isbrain);
    elseif contains(fullRawName(i),"OV")
        ovFC = cat(3,ovFC,fcMap);
        ovBrain = cat(3,ovBrain,trialData.xform_isbrain);
    elseif contains(fullRawName(i),"OD")
        odFC = cat(3,odFC,fcMap);
        odBrain = cat(3,odBrain,trialData.xform_isbrain);
    end
end

save(fullfile(saveFolder,saveFile),'yvBrain','yvFC','ovBrain','ovFC','odBrain','odFC','-v7.3');