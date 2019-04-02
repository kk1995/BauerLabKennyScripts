excelFile = "D:\data\zach_gcamp_stroke_fc_trials.xlsx";
nfft = 2048;
fs = 16.8;
rows = 2:43;

saveFile = strcat("hbtSpectra_gsr-",num2str(rows(1)),"-",num2str(rows(end)),".mat");
saveFile2 = strcat("g6corrSpectra_gsr-",num2str(rows(1)),"-",num2str(rows(end)),".mat");

trialInfo = getTrialInfo(excelFile,rows);

saveFolder = trialInfo(1).saveDir;
saveFolder = fileparts(saveFolder);

spectra = [];
mask = [];

trialNum = numel(trialInfo);
for i = 1:trialNum
    disp([num2str(i) '/' num2str(trialNum)]);
    fluorData = load(trialInfo(i).hbFile);
    maskData = load(trialInfo(i).maskFile);
    
    xform_isbrain = maskData.xform_isbrain;
        
    data = squeeze(sum(fluorData.xform_datahb,3));
    data = mouse.process.gsr(data,xform_isbrain);
    
    spectraTrial = nan(128,128,numel(pwelch(rand(1,size(data,3)),[],[],nfft,fs)));
    for y = 1:128
        for x = 1:128
            [spectraTrial(y,x,:),freq] = pwelch(squeeze(data(y,x,:)),[],[],nfft,fs);
        end
    end
    spectra = cat(4,spectra,spectraTrial);
    mask = cat(3,mask,xform_isbrain);
end

save(fullfile(saveFolder,saveFile),'freq','spectra','mask','-v7.3');

%%

spectra = [];
mask = [];

for i = 1:trialNum
    disp([num2str(i) '/' num2str(trialNum)]);
    fluorData = load(trialInfo(i).fluorFile);
    maskData = load(trialInfo(i).maskFile);
    
    xform_isbrain = maskData.xform_isbrain;
        
    data = squeeze(fluorData.xform_datafluorCorr);
    data = mouse.process.gsr(data,xform_isbrain);
    
    spectraTrial = nan(128,128,numel(pwelch(rand(1,size(data,3)),[],[],nfft,fs)));
    for y = 1:128
        for x = 1:128
            [spectraTrial(y,x,:),freq] = pwelch(squeeze(data(y,x,:)),[],[],nfft,fs);
        end
    end
    spectra = cat(4,spectra,spectraTrial);
    mask = cat(3,mask,xform_isbrain);
end

save(fullfile(saveFolder,saveFile2),'freq','spectra','mask','-v7.3');