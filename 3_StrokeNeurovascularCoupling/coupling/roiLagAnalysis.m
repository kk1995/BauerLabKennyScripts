% here, gsLag means lag of global signals. Global signal of each species is
% calculated and then the lag of one global signal to another is measured.

excelFile = "D:\data\Stroke Study 1 sorted.xlsx";
saveSubFolder = "baseline_gsXLag";
files = 5:14;

fMin = 0.02;
fMax = 2;
tZone = 4; % oxy, gcamp, oxy-gcamp

roi = 34*128+60;

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
        
        oxy = highpass(oxy,fMin,sR);
        oxy = lowpass(oxy,fMax,sR);
        deoxy = highpass(deoxy,fMin,sR);
        deoxy = lowpass(deoxy,fMax,sR);
        gcamp6corr = highpass(gcamp6corr,fMin,sR);
        gcamp6corr = lowpass(gcamp6corr,fMax,sR);
        
%         oxy = mouse.freq.filterData(oxy,fMin,fMax,sR);
%         deoxy = mouse.freq.filterData(deoxy,fMin,fMax,sR);
%         gcamp6corr = mouse.freq.filterData(gcamp6corr,fMin,fMax,sR);
        
        edgeLen = 3;
        validRange = round(tZone*sR);
        
        %% get gs
        
        hbT = oxy+deoxy;
        hbTRoi = reshape(hbT,[],size(oxy,3));
        hbTRoi = hbTRoi(roi(:),:);
        hbTRoi = nanmean(hbTRoi,1);
        gcamp6corrRoi = reshape(gcamp6corr,[],size(gcamp6corr,3));
        gcamp6corrRoi = gcamp6corrRoi(roi(:),:);
        gcamp6corrRoi = nanmean(gcamp6corrRoi,1);
        
        %% lag analysis
        
        [lagTimeHbTG6Run,lagAmpHbTG6Run,covResult] = mouse.conn.findLag(hbTRoi,gcamp6corrRoi,true,true,...
            validRange,edgeLen,0);
        
        lagTimeHbTG6Run = lagTimeHbTG6Run./sR;
        
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