excelFile = "D:\data\deborahData.xlsx";
saveFile = "avgNodeDegree_gsr.mat";
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

yvND = [];
ovND = [];
odND = [];
yvBrain = [];
ovBrain = [];
odBrain = [];

for i = 1:numel(fullRawName)
    disp([num2str(i) '/' num2str(numel(fullRawName))]);
    trialData = load(fullRawName(i),'xform_isbrain');
    
    if contains(fullRawName(i),"YV")
        yvBrain = cat(3,yvBrain,trialData.xform_isbrain);
    elseif contains(fullRawName(i),"OV")
        ovBrain = cat(3,ovBrain,trialData.xform_isbrain);
    elseif contains(fullRawName(i),"OD")
        odBrain = cat(3,odBrain,trialData.xform_isbrain);
    end
end

mask = cat(3,yvBrain,ovBrain,odBrain); mask = sum(mask,3) == 21;

for i = 1:numel(fullRawName)
    disp([num2str(i) '/' num2str(numel(fullRawName))]);
    trialData = load(fullRawName(i));
    
    data = trialData.xform_datahb;
    data = squeeze(data(:,:,1,:));
    data = mouse.process.gsr(data,trialData.xform_isbrain);
    fcMap = mouse.conn.getFC(data);
    fcMap = atanh(fcMap);
    
    fcMap(~mask,~mask) = 0;
    nodeDegree = sum(fcMap >= 0.4);
    nodeDegree = reshape(nodeDegree,128,128);
    nodeDegree = nodeDegree/sum(mask(:));
    
    if contains(fullRawName(i),"YV")
        yvND = cat(3,yvND,nodeDegree);
    elseif contains(fullRawName(i),"OV")
        ovND = cat(3,ovND,nodeDegree);
    elseif contains(fullRawName(i),"OD")
        odND = cat(3,odND,nodeDegree);
    end
end

save(fullfile(saveFolder,saveFile),'yvBrain','yvND','ovBrain','ovND','odBrain','odND','-v7.3');