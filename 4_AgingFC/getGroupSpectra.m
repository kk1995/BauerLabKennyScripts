excelFile = "D:\data\deborahData.xlsx";
nfft = 256;
fs = 1;
saveFile2 = "avgSpectra_gsr.mat";

rows = 2:22;

[~,~,excelData] = xlsread(excelFile,1,['A' num2str(rows(1)) ':' xlscol(5) num2str(max(rows))]);

% get info for each row
fullRawName = [];
for i = 1:size(excelData,1)
    rawName = strcat(num2str(excelData{i,1}),"-",excelData{i,2},"-",excelData{i,3},"-cat.mat");
    fullRawName = [fullRawName fullfile(excelData{i,4},rawName)];
end
saveFolder = string(excelData{1,5});

yvSpectra = [];
ovSpectra = [];
odSpectra = [];
yvBrain = [];
ovBrain = [];
odBrain = [];

for i = 1:numel(fullRawName)
    disp([num2str(i) '/' num2str(numel(fullRawName))]);
    trialData = load(fullRawName(i));
    
    data = trialData.xform_datahb;
    data = squeeze(data(:,:,1,:));
    data = mouse.process.gsr(data,trialData.xform_isbrain);
    
    spectra = nan(128,128,numel(pwelch(rand(1,size(data,3)),[],[],nfft,fs)));
    for y = 1:128
        for x = 1:128
            [spectra(y,x,:),freq] = pwelch(squeeze(data(y,x,:)),[],[],nfft,fs);
        end
    end
    
    if contains(fullRawName(i),"YV")
        yvSpectra = cat(4,yvSpectra,spectra);
        yvBrain = cat(3,yvBrain,trialData.xform_isbrain);
    elseif contains(fullRawName(i),"OV")
        ovSpectra = cat(4,ovSpectra,spectra);
        ovBrain = cat(3,ovBrain,trialData.xform_isbrain);
    elseif contains(fullRawName(i),"OD")
        odSpectra = cat(4,odSpectra,spectra);
        odBrain = cat(3,odBrain,trialData.xform_isbrain);
    end
end

save(fullfile(saveFolder,saveFile2),'freq','yvSpectra','yvBrain','ovSpectra','ovBrain','odSpectra','odBrain','-v7.3');