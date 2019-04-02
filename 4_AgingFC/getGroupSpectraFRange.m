excelFile = "D:\data\deborahData.xlsx";
fRange = [0.01 0.02];
% saveFile = "avgSpectra0p009to0p08.mat";
saveFile2 = "avgSpectra0p01to0p02_gsr.mat";

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

% youngSpectra = [];
% oldSpectra = [];
% youngBrain = [];
% oldBrain = [];
% 
% for i = 1:numel(fullRawName)
%     disp([num2str(i) '/' num2str(numel(fullRawName))]);
%     if contains(fullRawName(i),"YV") || contains(fullRawName(i),"OV")
%         trialData = load(fullRawName(i));
%         
%         data = trialData.xform_datahb;
%         data = squeeze(data(:,:,1,:));
%         
%         spectra = abs(fft(data,[],3));
%         freq = linspace(0,1,size(spectra,3));
%         inRange = freq >= fRange(1) & freq <= fRange(2);
%         spectra = spectra(:,:,inRange);
%         spectra = mean(spectra,3);
%         
%         if contains(fullRawName(i),"YV")
%             youngSpectra = cat(3,youngSpectra,spectra);
%             youngBrain = cat(3,youngBrain,trialData.xform_isbrain);
%         elseif contains(fullRawName(i),"OV")
%             oldSpectra = cat(3,oldSpectra,spectra);
%             oldBrain = cat(3,oldBrain,trialData.xform_isbrain);
%         end
%     end
% end
% 
% save(fullfile(saveFolder,saveFile),'youngSpectra','youngBrain','oldSpectra','oldBrain','-v7.3');

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
    
    spectra = abs(fft(data,[],3));
    freq = linspace(0,1,size(spectra,3));
    inRange = freq >= fRange(1) & freq <= fRange(2);
    spectra = spectra(:,:,inRange);
    spectra = mean(spectra,3);
    
    if contains(fullRawName(i),"YV")
        yvSpectra = cat(3,yvSpectra,spectra);
        yvBrain = cat(3,yvBrain,trialData.xform_isbrain);
    elseif contains(fullRawName(i),"OV")
        ovSpectra = cat(3,ovSpectra,spectra);
        ovBrain = cat(3,ovBrain,trialData.xform_isbrain);
    elseif contains(fullRawName(i),"OD")
        odSpectra = cat(3,odSpectra,spectra);
        odBrain = cat(3,odBrain,trialData.xform_isbrain);
    end
end

save(fullfile(saveFolder,saveFile2),'yvSpectra','yvBrain','ovSpectra','ovBrain','odSpectra','odBrain','-v7.3');