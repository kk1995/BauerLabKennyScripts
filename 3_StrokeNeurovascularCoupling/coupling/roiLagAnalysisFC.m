% here, we find the lag of average roi response.

files = 1:14;

data1Ind = 1; % hbo
data2Ind = 4; % gcamp6 corr

fMin = 0.009;
fMax = 0.5;
tZone = 4; % oxy, gcamp, oxy-gcamp

roiFile = 'D:\data\zachRosenthal\_stim\ROI R 75.mat';
roiData = load(roiFile);
roi = roiData.roiR75;

stimStatus = 'fc';

lagTime = [];
lagAmp = [];

%%

excelFile = "D:\data\Stroke Study 1 sorted.xlsx";
saveSubFolder = "baseline_roiXLag";
dataNames = ["Hbo","Hbr","G6","G6corr"];
saveFileSuffix = strjoin(dataNames([data1Ind data2Ind]),'');


%%
for file = files
    t0 = tic;
    fileInd = find(file == files);
    disp(['File # ' num2str(file)]);
    [~, ~, raw]=xlsread(excelFile,1, ['A',num2str(file),':F',num2str(file)]);
    mouseName = string(raw{2});
    saveDir = string(raw{4});
    
    % make str array of run files
    runDir = [];
    for run = 1:3
        dataDir = raw{3};
        dataDate = num2str(raw{1});
        fileName = [dataDate '-' raw{2} '-dataGCaMP-' stimStatus num2str(run) '.mat'];
        runDir = [runDir; string(fullfile(dataDir,dataDate,fileName))];
    end
    numRuns = numel(runDir);
    
    roiResponse = [];
    for run = 1:numRuns
        disp(['  Run # ' num2str(run)]);
        
        
        % load data
        load(runDir(run),'oxy','deoxy','gcamp6','gcamp6corr','xform_mask','info');
        
        sR = info.framerate;
        
        oxy = cat(3,oxy(:,:,1),oxy);
        deoxy = cat(3,deoxy(:,:,1),deoxy);
        gcamp6 = cat(3,gcamp6(:,:,1),gcamp6);
        gcamp6corr = cat(3,gcamp6corr(:,:,1),gcamp6corr);
        
        runData = cat(4,oxy,deoxy,gcamp6,gcamp6corr); % 128x128x5040x4
        % oxy, deoxy, gcamp6, gcamp6corr
        runData = permute(runData,[1,2,4,3]);
        
        runData = mouse.freq.filterData(runData,fMin,fMax,sR);
        
        roiResponseRun = reshape(runData,128*128,4,[]);
        roiResponseRun = roiResponseRun(roi,:,:);
        roiResponseRun = squeeze(nanmean(roiResponseRun,1));
        
        edgeLen = 3;
        validRange = round(tZone*sR);
                
        data1 = sum(roiResponseRun(data1Ind,:),1);
        data2 = sum(roiResponseRun(data2Ind,:),1);
        
        [lagTimeRun,lagAmpRun,covResult] = mouse.conn.findLag(data1,data2,true,true,...
            validRange,edgeLen,0);
        
        lagTimeRun = lagTimeRun./sR;
        
        lagTime = [lagTime lagTimeRun];
        lagAmp = [lagAmp lagAmpRun];
    end
    
    disp(['  took '  num2str(toc(t0)) ' seconds.']);

end


%% save

meta.sR = sR;
meta.fMin = fMin;
meta.fMax = fMax;
meta.files = files;
meta.tZone = tZone;
meta.data1 = data1Ind;
meta.data2 = data2Ind;
meta.dataInd = ["hbo","hbr","gcamp","gcampcorr"];

saveFile = strcat(string(stimStatus),"-gsXLag",saveFileSuffix,".mat");
saveFile = fullfile(saveDir,saveSubFolder,saveFile);
save(saveFile,'lagTime','lagAmp','meta','xform_mask');
