% here, gsLag means lag of global signals. Global signal of each species is
% calculated and then the lag of one global signal to another is measured.

excelFile = "D:\data\Stroke Study 1 sorted.xlsx";
saveSubFolder = "baseline_gsXLag";
files = 1:14;

fMin = 0.009;
fMax = 0.5;
tZone = 2; % oxy, gcamp, oxy-gcamp

stimStatus = 'fc';

for file = files
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
    lagTimeHbTG6 = nan(numRuns,1);
    lagAmpHbTG6 = nan(numRuns,1);
    
    for run = 1:numRuns
        disp(['  Run # ' num2str(run)]);
        t0 = tic;
        
        % load data
        load(runDir(run),'oxy','deoxy','gcamp6corr','xform_mask','info');
        
        sR = info.framerate;
        
%         oxy = mouse.freq.filterData(oxy,fMin,fMax,sR);
%         deoxy = mouse.freq.filterData(deoxy,fMin,fMax,sR);
%         gcamp6corr = mouse.freq.filterData(gcamp6corr,fMin,fMax,sR);
        maskRun = logical(xform_mask);
        
        edgeLen = 3;
        validRange = round(tZone*sR);
        
        %% get gs
        
        hbT = oxy+deoxy;
        hbTGS = reshape(hbT,[],size(oxy,3));
        hbTGS = hbTGS(maskRun(:),:);
        hbTGS = nanmean(hbTGS,1);
        gcamp6corrGS = reshape(gcamp6corr,[],size(gcamp6corr,3));
        gcamp6corrGS = gcamp6corrGS(maskRun(:),:);
        gcamp6corrGS = nanmean(gcamp6corrGS,1);
        
        %% lag analysis
        
        [lagTimeHbTG6Run,lagAmpHbTG6Run,covResult] = mouse.conn.findLag(hbTGS,gcamp6corrGS,true,true,...
            validRange,edgeLen,0);
        
        lagTimeHbTG6Run = lagTimeHbTG6Run./info.framerate;
        
        lagTimeHbTG6(run) = lagTimeHbTG6Run;
        lagAmpHbTG6(run) = lagAmpHbTG6Run;
    end
    
    %% save
    
    meta.sR = sR;
    meta.fMin = fMin;
    meta.fMax = fMax;
    meta.tZone = tZone;
    
    saveFile = strcat(mouseName,"-",string(stimStatus),"-gsXLagHbTG6.mat");
    saveFile = fullfile(saveDir,saveSubFolder,saveFile);
    save(saveFile,'lagTimeHbTG6','lagAmpHbTG6','meta','xform_mask');
    disp(['  took '  num2str(toc(t0)) ' seconds.']);
    
end