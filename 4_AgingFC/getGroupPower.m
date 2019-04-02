excelFile = "D:\data\deborahData.xlsx";
saveFile2 = "variance_gsr.mat";

rows = 2:22;

[~,~,excelData] = xlsread(excelFile,1,['A' num2str(rows(1)) ':' xlscol(5) num2str(max(rows))]);

% get info for each row
fullRawName = [];
for i = 1:size(excelData,1)
    rawName = strcat(num2str(excelData{i,1}),"-",excelData{i,2},"-",excelData{i,3},"-cat.mat");
    fullRawName = [fullRawName fullfile(excelData{i,4},rawName)];
end
saveFolder = string(excelData{1,5});

yvVar = [];
ovVar = [];
odVar = [];
yvBrain = [];
ovBrain = [];
odBrain = [];

for i = 1:numel(fullRawName)
    disp([num2str(i) '/' num2str(numel(fullRawName))]);
    trialData = load(fullRawName(i));
    
    data = trialData.xform_datahb;
    data = squeeze(data(:,:,1,:));
    data = mouse.process.gsr(data,trialData.xform_isbrain);
    
    spectra = var(data,0,3);
    
    if contains(fullRawName(i),"YV")
        yvVar = cat(3,yvVar,spectra);
        yvBrain = cat(3,yvBrain,trialData.xform_isbrain);
    elseif contains(fullRawName(i),"OV")
        ovVar = cat(3,ovVar,spectra);
        ovBrain = cat(3,ovBrain,trialData.xform_isbrain);
    elseif contains(fullRawName(i),"OD")
        odVar = cat(3,odVar,spectra);
        odBrain = cat(3,odBrain,trialData.xform_isbrain);
    end
end

save(fullfile(saveFolder,saveFile2),'freq','yvVar','yvBrain','ovVar','ovBrain','odVar','odBrain','-v7.3');