excelFile = "D:\data\zach_gcamp_stroke_fc_trials.xlsx";
saveEachTrialFolder = "L:\ProcessedData\3_NeurovascularCoupling\trials";
saveFolder = "L:\ProcessedData\3_NeurovascularCoupling";
rows = 2:43;

%%

fs = 16.8;
fMin = 0.009;
fMax = 0.5;

fMinStr = "0p009"; fMaxStr = "0p5";

saveFilePrefix = strcat("hbtFC-fc-",fMinStr,"-",fMaxStr,"-row-");
saveFilePrefix2 = strcat("g6corrFC-fc-",fMinStr,"-",fMaxStr,"-row-");

trialInfo = getTrialInfo(excelFile,rows);

% saveFolder = trialInfo(1).saveDir;
% saveFolder = fileparts(saveFolder);

%%

fcAvg = zeros(128^2);
maskTotal = [];
sampleNum = zeros(128^2);

trialNum = numel(trialInfo);
for i = 1:trialNum
    disp([num2str(i) '/' num2str(trialNum)]);
    saveName = fullfile(saveEachTrialFolder,strcat(saveFilePrefix,num2str(rows(i)),".mat"));
    
    if exist(saveName)
        disp('loading');
        load(saveName)
    else
        disp('making');
        hbData = load(trialInfo(i).hbFile);
        maskData = load(trialInfo(i).maskFile);
        
        xform_isbrain = maskData.xform_isbrain;
        
        data = squeeze(sum(hbData.xform_datahb,3));
        data = mouse.freq.filterData(data,fMin,fMax,fs);
        data = mouse.process.gsr(data,xform_isbrain);
        fc = mouse.conn.getFC(data);
        clear data;
        fc = atanh(fc);
        mask = xform_isbrain;
        save(saveName,'fc','mask','-v7.3');
    end
    fc(isnan(fc)) = 0;
    fcAvg = fcAvg + fc;
    sampleNum = sampleNum + ~isnan(fc);
    maskTotal = cat(3,maskTotal,mask);
    clear fc;
end

fcAvg = fcAvg./sampleNum;

saveName = strcat(saveFilePrefix,num2str(rows(1)),"-",num2str(rows(end)),".mat");
save(fullfile(saveFolder,saveName),'fcAvg','sampleNum','maskTotal','-v7.3');

%%

fcAvg = zeros(128^2);
maskTotal = [];
sampleNum = zeros(128^2);

trialNum = numel(trialInfo);
for i = 1:trialNum
    disp([num2str(i) '/' num2str(trialNum)]);
    saveName = fullfile(saveEachTrialFolder,strcat(saveFilePrefix2,num2str(rows(i)),".mat"));
    if exist(saveName)
        disp('loading');
        load(saveName)
    else
        disp('making');
        fluorData = load(trialInfo(i).fluorFile);
        maskData = load(trialInfo(i).maskFile);
        
        xform_isbrain = maskData.xform_isbrain;
        
        data = squeeze(sum(fluorData.xform_datafluorCorr,3));
        data = mouse.freq.filterData(data,fMin,fMax,fs);
        data = mouse.process.gsr(data,xform_isbrain);
        fc = mouse.conn.getFC(data);
        clear data;
        fc = atanh(fc);
        mask = xform_isbrain;
        save(saveName,'fc','mask','-v7.3');
    end
    fc(isnan(fc)) = 0;
    fcAvg = fcAvg + fc;
    sampleNum = sampleNum + ~isnan(fc);
    maskTotal = cat(3,maskTotal,mask);
    clear fc;
end

fcAvg = fcAvg./sampleNum;

saveName = strcat(saveFilePrefix2,num2str(rows(1)),"-",num2str(rows(end)),".mat");
save(fullfile(saveFolder,saveName),'fcAvg','sampleNum','maskTotal','-v7.3');