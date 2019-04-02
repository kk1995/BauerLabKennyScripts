excelFile = "D:\data\deborahData.xlsx";
saveFile = "avgFC_gsr.mat";
saveFileTrialPrefix = "FC";
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

yvFC = zeros(128^2);
yvN = zeros(128^2);
ovFC = zeros(128^2);
ovN = zeros(128^2);
odFC = zeros(128^2);
odN = zeros(128^2);

groupInd = zeros(3,1);

for i = 1:numel(fullRawName)
    disp([num2str(i) '/' num2str(numel(fullRawName))]);
    trialData = load(fullRawName(i));
    
    data = trialData.xform_datahb;
    data = squeeze(data(:,:,1,:));
    data = mouse.process.gsr(data,trialData.xform_isbrain);
    fcMap = mouse.conn.getFC(data);
    fcMap = atanh(fcMap);
    
    if contains(fullRawName(i),"YV")
        groupInd(1) = groupInd(1) + 1;
        saveFileTrial = fullfile(saveFolder,strcat(saveFileTrialPrefix,"-YV",num2str(groupInd(1)),".mat"));
        save(saveFileTrial,'fcMap','-v7.3');
        yvFC = yvFC + fcMap;
        yvN = yvN + ~isnan(fcMap);
    elseif contains(fullRawName(i),"OV")
        groupInd(2) = groupInd(2) + 1;
        saveFileTrial = fullfile(saveFolder,strcat(saveFileTrialPrefix,"-OV",num2str(groupInd(2)),".mat"));
        save(saveFileTrial,'fcMap','-v7.3');
        ovFC = ovFC + fcMap;
        ovN = ovN + ~isnan(fcMap);
    elseif contains(fullRawName(i),"OD")
        groupInd(3) = groupInd(3) + 1;
        saveFileTrial = fullfile(saveFolder,strcat(saveFileTrialPrefix,"-OD",num2str(groupInd(3)),".mat"));
        save(saveFileTrial,'fcMap','-v7.3');
        odFC = odFC + fcMap;
        odN = odN + ~isnan(fcMap);
    end
end

yvFC = yvFC./yvN;
ovFC = ovFC./ovN;
odFC = odFC./ovN;

save(fullfile(saveFolder,saveFile),'yvFC','ovFC','odFC','-v7.3');