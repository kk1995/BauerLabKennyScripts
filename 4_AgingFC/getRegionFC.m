excelFile = "D:\data\deborahData.xlsx";
atlasFile = "D:\data\atlas16.mat";
saveFile = "region16FC.mat";
saveFile2 = "region16FC_gsr.mat";
rows = 2:22;

load(atlasFile);

[B,I] = sort(atlas(:));

[~,~,excelData] = xlsread(excelFile,1,['A' num2str(rows(1)) ':' xlscol(5) num2str(max(rows))]);

% get info for each row
fullRawName = [];
for i = 1:size(excelData,1)
    rawName = strcat(num2str(excelData{i,1}),"-",excelData{i,2},"-",excelData{i,3},"-cat.mat");
    fullRawName = [fullRawName fullfile(excelData{i,4},rawName)];
end
saveFolder = string(excelData{1,5});

% load each data, then add the matrix

youngFC = [];
oldFC = [];

for i = 1:numel(fullRawName)
    disp([num2str(i) '/' num2str(numel(fullRawName))]);
    if contains(fullRawName(i),"YV") || contains(fullRawName(i),"OV")
        trialData = load(fullRawName(i));
        
        data = trialData.xform_datahb;
        data = squeeze(data(:,:,1,:));
        data = reshape(data,128*128,[]);
        data = data(I,:);
        data2 = nan(max(B),size(data,2));
        for j = 1:size(data2,1)
            data2(j,:) = nanmean(data(B==j,:),1);
        end
        fcMap = mouse.conn.getFC(data2);
        
        if contains(fullRawName(i),"YV")
            youngFC = cat(3,youngFC,fcMap);
        elseif contains(fullRawName(i),"OV")
            oldFC = cat(3,oldFC,fcMap);
        end
    end
end

save(fullfile(saveFolder,saveFile),'youngFC','oldFC','-v7.3');

youngFC = [];
oldFC = [];

for i = 1:numel(fullRawName)
    disp([num2str(i) '/' num2str(numel(fullRawName))]);
    if contains(fullRawName(i),"YV") || contains(fullRawName(i),"OV")
        trialData = load(fullRawName(i));
        
        data = trialData.xform_datahb;
        data = squeeze(data(:,:,1,:));
        data = mouse.process.gsr(data,trialData.xform_isbrain);
        data = reshape(data,128*128,[]);
        data = data(I,:);
        data2 = nan(max(B),size(data,2));
        for j = 1:size(data2,1)
            data2(j,:) = nanmean(data(B==j,:),1);
        end
        fcMap = mouse.conn.getFC(data2);
        
        if contains(fullRawName(i),"YV")
            youngFC = cat(3,youngFC,fcMap);
        elseif contains(fullRawName(i),"OV")
            oldFC = cat(3,oldFC,fcMap);
        end
    end
end

save(fullfile(saveFolder,saveFile2),'youngFC','oldFC','-v7.3');