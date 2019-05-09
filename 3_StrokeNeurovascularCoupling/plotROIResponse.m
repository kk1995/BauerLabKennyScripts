function plotROIResponse(excelFile,rows,useGsr)

% this script is a wrapper around fluor package that shows how
% the package should be used. As shown, you feed an excel file with file locations,
% then get system and session information either via the functions
% sysInfo.m and sesInfo.m or manual addition. Run fluor.preprocess and
% fluor.process functions to get the desired results.

blockLen = 20; % seconds
stimStart = 5; % seconds
stimResponseTime = [9 11]; % seconds
roiSeed = [60 29];

%% read the excel file to get the list of file names

trialInfo = mouse.expSpecific.extractExcel(excelFile,rows);
saveFileLocs = trialInfo.saveFolder;
saveFileMaskNames = trialInfo.saveFilePrefixMask;
saveFileDataPrefixes = trialInfo.saveFilePrefixData;

trialNum = numel(saveFileLocs);

%% preprocess and process
disp('preprocess and process');

roiResponse = [];
roi = [];

for trial = 1:trialNum
    disp(['Trial # ' num2str(trial) '/' num2str(trialNum)]);
    
    % load
    saveFileDataPrefix = fullfile(saveFileLocs(trial),saveFileDataPrefixes(trial));
    
    if useGsr
        saveFile = strcat(saveFileDataPrefix,"-roiResponse-gsr.mat");
    else
        saveFile = strcat(saveFileDataPrefix,"-roiResponse.mat");
    end
    if exist(saveFile)
        load(saveFile);
    else
        
        saveFileLoc = saveFileLocs(trial);
        saveFileMaskName = saveFileMaskNames(trial);
        maskFileName = string(fullfile(saveFileLoc,strcat(saveFileMaskName,"-LandmarksandMask.mat")));
        mask = load(maskFileName);
        hbFileName = strcat(saveFileDataPrefix,"-datahb.mat");
        load(hbFileName);
        fluorFileName = strcat(saveFileDataPrefix,"-dataFluor.mat");
        load(fluorFileName);
        
        % gsr
        if useGsr
            xform_datahb = mouse.process.gsr(xform_datahb,mask.xform_isbrain);
            xform_datafluorCorr = mouse.process.gsr(xform_datafluorCorr,mask.xform_isbrain);
        end
        % make block avg
        fs = readerInfo.FreqOut;
        [hbBlock, hbTime] = mouse.preprocess.blockAvg(xform_datahb,rawTime,blockLen,fs*blockLen);
        [fluorBlock, fluorTime] = mouse.preprocess.blockAvg(xform_datafluorCorr,rawTime,blockLen,fs*blockLen);
        preStimHb = mean(hbBlock(:,:,:,hbTime < stimStart),4);
        hbBlock = bsxfun(@minus,hbBlock,preStimHb);
        preStimFluor = mean(fluorBlock(:,:,:,fluorTime < stimStart),4);
        fluorBlock = bsxfun(@minus,fluorBlock,preStimFluor);
        
        % get roi
        stimResponse = mean(hbBlock(:,:,:,hbTime > stimResponseTime(1) & hbTime < stimResponseTime(2)),4);
        roiTrial = mouse.expSpecific.getROI(stimResponse(:,:,1),roiSeed);
        
        % make roi response
        hbBlock = reshape(hbBlock,size(hbBlock,1)*size(hbBlock,2),2,[]);
        fluorBlock = reshape(fluorBlock,size(fluorBlock,1)*size(fluorBlock,2),[]);
        roiResponseTrial = cat(1,squeeze(mean(hbBlock(roiTrial,:,:),1)),squeeze(mean(fluorBlock(roiTrial,:),1)));
        
        % save
        save(saveFile,'hbTime','fluorTime','roiResponseTrial','-v7.3');
    end
    
    % plot roi response
    f1 = figure('Position',[100 100 800 350]);
    subplot(1,2,1); imagesc(roiTrial); axis(gca,'square'); yticks([]); xticks([]);
    subplot(1,2,2);
    plot(hbTime,roiResponseTrial(1,:)*1000,'r'); hold on; plot(hbTime,roiResponseTrial(2,:)*1000,'b');
    plot(hbTime,sum(roiResponseTrial(1:2,:),1)*1000,'k');
    plot(fluorTime,roiResponseTrial(3,:),'m'); xlabel('time (s)');
    legend('HbO (mM)','HbR (mM)','HbT (mM)','GCaMP');
    
    if useGsr
        saveFigureName = strcat(saveFileDataPrefix,"-roiResponse-gsr.fig");
    else
        saveFigureName = strcat(saveFileDataPrefix,"-roiResponse.fig");
    end
    savefig(f1,saveFigureName);
    close(f1);
    
    % add to trial avg data
    roiResponse = cat(3,roiResponse,roiResponseTrial);
    roi = cat(3,roi,roiTrial);
end

roiResponse = mean(roiResponse,3);
roi = mean(roi,3);

% plot roi response
f1 = figure('Position',[100 100 800 350]);
subplot(1,2,1); imagesc(roi); axis(gca,'square'); yticks([]); xticks([]);
subplot(1,2,2);
plot(hbTime,roiResponse(1,:)*1000,'r'); hold on; plot(hbTime,roiResponse(2,:)*1000,'b');
plot(hbTime,sum(roiResponse(1:2,:),1)*1000,'k');
plot(fluorTime,roiResponse(3,:),'m'); xlabel('time (s)');
legend('HbO (mM)','HbR (mM)','HbT (mM)','GCaMP');

saveFileLoc = fileparts(saveFileLocs(1));
if useGsr
    saveFigureName = fullfile(saveFileLoc,strcat(num2str(rows(1)),"-",num2str(rows(end)),"-roiResponse-gsr.fig"));
else
    saveFigureName = fullfile(saveFileLoc,strcat(num2str(rows(1)),"-",num2str(rows(end)),"-roiResponse.fig"));
end
savefig(f1,saveFigureName);
close(f1);

end