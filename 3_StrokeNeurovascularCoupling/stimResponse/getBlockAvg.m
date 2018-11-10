excelFile = fullfile('D:\data','Stroke Study 1 sorted.xlsx');
mouseInd = 1:56;
blockLenTime = 20; % 5 sec rest, 5 sec stim, 10 sec rest
sR = 16.8;
saveDirRoot = 'D:\data\zachRosenthal\_stim';
useGsr = true;

if useGsr
    disp('using GSR');
else
    disp('not using GSR');
end

for mouse = mouseInd
    disp(['File # ' num2str(mouse) '/' num2str(numel(mouseInd))]);
    if mouse <= 14
        week = 'baseline';
    elseif mouse <= 28
        week = 'week1';
    elseif mouse <= 42
        week = 'week4';
    else
        week = 'week8';
    end
    
    [~, ~, raw]=xlsread(excelFile,1, ['A',num2str(mouseInd(mouse)),':F',num2str(mouseInd(mouse))]);
    mouseName = raw{2};
    dataDir = raw{3};
    dataDate = num2str(raw{1});
    
    saveDir = fullfile(saveDirRoot,[week '_blockAvg']);
    saveFile = [mouseName '_blockAvg'];
    if useGsr
        saveFile = [saveFile '_GSR'];
        saveDir = [saveDir '_GSR'];
    end
    saveFile = [saveFile '.mat'];
    
    if ~exist(saveDir)
        mkdir(saveDir);
    end
    
    % make file list of runs
    runFileList = [];
    D = dir(fullfile(dataDir,dataDate)); D(1:2) = [];
    for fileInd = 1:numel(D)
        if contains(D(fileInd).name,mouseName) && contains(D(fileInd).name,'stim')
            runFileList = [runFileList; string(fullfile(dataDir,dataDate,D(fileInd).name))];
        end
    end
    
    oxyBlock = [];
    deoxyBlock = [];
    gcamp6corrBlock = [];
    
    for runInd = 1:numel(runFileList)
        
        load(runFileList(runInd));
        
        mask = xform_mask;
        
        oxy = cat(3,zeros(128,128),oxy);
        deoxy = cat(3,zeros(128,128),deoxy);
        gcamp6corr = cat(3,zeros(128,128),gcamp6corr);
        
        %% gsr
        if useGsr
            oxy = mouseAnalysis.preprocess.gsr(oxy,mask);
            deoxy = mouseAnalysis.preprocess.gsr(deoxy,mask);
            gcamp6corr = mouseAnalysis.preprocess.gsr(gcamp6corr,mask);
        end
        
        %% get number of time points in each block
        
        blockLen = sR*blockLenTime;
        
        %% get block avg
        
        % reshape data to be block time points x block
        oxy = reshape(oxy,128,128,blockLen,[]);
        deoxy = reshape(deoxy,128,128,blockLen,[]);
        gcamp6corr = reshape(gcamp6corr,128,128,blockLen,[]);
        
        oxyBlockRun = nanmean(oxy,4);
        deoxyBlockRun = nanmean(deoxy,4);
        gcamp6corrBlockRun = nanmean(gcamp6corr,4);
        
        tBlock = linspace(0,20,blockLen+1); % block time
        tBlock(1) = [];
        
        oxyBlock = cat(4,oxyBlock,oxyBlockRun);
        deoxyBlock = cat(4,deoxyBlock,deoxyBlockRun);
        gcamp6corrBlock = cat(4,gcamp6corrBlock,gcamp6corrBlockRun);
        
%         %% get roi response
        
%         roiFile = 'D:\data\zachRosenthal\_stim\ROI R 75.mat';
%         load(roiFile); % roiR75 (logical 128 x 128 array)
%         
%         oxyBlockVect = reshape(oxyBlock,[],size(oxyBlock,3)); % vectorize space
%         deoxyBlockVect = reshape(deoxyBlock,[],size(deoxyBlock,3)); % vectorize space
%         gcamp6corrBlockVect = reshape(gcamp6corrBlock,[],size(gcamp6corrBlock,3)); % vectorize space
%         
%         % only select the roi pixels
%         oxyROI = oxyBlockVect(roiR75,:);
%         deoxyROI = deoxyBlockVect(roiR75,:);
%         gcamp6corrROI = gcamp6corrBlockVect(roiR75,:);
%         
%         % avg over roi pixels
%         oxyROI = nanmean(oxyROI,1);
%         deoxyROI = nanmean(deoxyROI,1);
%         gcamp6corrROI = nanmean(gcamp6corrROI,1);
        
    end
    
    oxyBlock = cat(4,nanmean(oxyBlock(:,:,:,1:3),4),nanmean(oxyBlock(:,:,:,4:6),4));
    deoxyBlock = cat(4,nanmean(deoxyBlock(:,:,:,1:3),4),nanmean(deoxyBlock(:,:,:,4:6),4));
    gcamp6corrBlock = cat(4,nanmean(gcamp6corrBlock(:,:,:,1:3),4),nanmean(gcamp6corrBlock(:,:,:,4:6),4));
    
    
%     oxyBlock = nanmean(oxyBlock,4);
%     deoxyBlock = nanmean(deoxyBlock,4);
%     gcamp6corrBlock = nanmean(gcamp6corrBlock,4);
    
    metaData.dim3 = {'block time'};
    metaData.dim4 = {'R forepaw','L forepaw'};

    % save
    save(fullfile(saveDir,saveFile),'oxyBlock','deoxyBlock','gcamp6corrBlock','tBlock','metaData','mask');
end