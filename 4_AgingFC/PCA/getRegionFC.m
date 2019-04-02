excelFile = "D:\data\deborahData.xlsx";
pcaData = "L:\ProcessedData\pcs.mat";
saveFile2 = "regionPCAFC_gsr.mat";
rows = 2:22;

pcaDataObj = matfile(pcaData);
coeff = pcaDataObj.coeff(:,1:20);
explained = pcaDataObj.explained;
brain = pcaDataObj.brain;

% get coefficients
coeffInd = 1:find(cumsum(explained) > 90,1,'first');
coeffs = zeros(128^2,numel(coeffInd));
coeffs(brain,:) = coeff(:,coeffInd);


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
        data = mouse.process.gsr(data,trialData.xform_isbrain);
        data = reshape(data,128*128,[]);
        fcData = nan(numel(coeffInd),size(data,2));
        for j = 1:numel(coeffInd)
            fcData(j,:) = sum(data.*repmat(coeffs(:,j),1,size(data,2)),1);
        end
        fcMap = mouse.conn.getFC(fcData);
        
        if contains(fullRawName(i),"YV")
            youngFC = cat(3,youngFC,fcMap);
        elseif contains(fullRawName(i),"OV")
            oldFC = cat(3,oldFC,fcMap);
        end
    end
end

save(fullfile(saveFolder,saveFile2),'youngFC','oldFC','-v7.3');