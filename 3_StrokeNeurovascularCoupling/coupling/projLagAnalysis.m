% load("D:\data\170126\170126-2528_baseline-dataGCaMP-fc1.mat");
excelFile = "D:\data\Stroke Study 1 sorted.xlsx";
saveSubFolder = "baseline_projLag";
files = 1:14;

dsFactor = 4;

fMin = 0.009;
fMax = 0.5;
tZone = [2 2 2]; % oxy, gcamp, oxy-gcamp

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
        fileName = [dataDate '-' raw{2} '-dataGCaMP-fc' num2str(run) '.mat'];
        runDir = [runDir; string(fullfile(dataDir,dataDate,fileName))];
    end
    
    for run = 1:numel(runDir)
        disp(['  Run # ' num2str(run)]);
        t0 = tic;
        
        % load data
        load(runDir(run),'oxy','deoxy','gcamp6corr','xform_mask','info');
        
        sR = info.framerate;
        
        oxy = mouse.freq.filterData(oxy,fMin,fMax,sR);
        gcamp6corr = mouse.freq.filterData(gcamp6corr,fMin,fMax,sR);
        maskRun = logical(xform_mask);
        
        edgeLen = 3;
        validRange = round(tZone*sR);
        
        %% downsample
        oxyDS = zeros(size(oxy,1)/dsFactor,size(oxy,2)/dsFactor,size(oxy,3));
        gcamp6corrDS = zeros(size(gcamp6corr,1)/dsFactor,size(gcamp6corr,2)/dsFactor,size(gcamp6corr,3));
        for t = 1:size(oxy,3)
            oxyDS(:,:,t) = mouse.math.dsSpace(oxy(:,:,t),dsFactor);
        end
        for t = 1:size(gcamp6corr,3)
            gcamp6corrDS(:,:,t) = mouse.math.dsSpace(gcamp6corr(:,:,t),dsFactor);
        end
        xform_mask = mouse.math.dsSpace(xform_mask,dsFactor);
        
        %% lag analysis
        
        [lagTimeOxyG6,lagAmpOxyG6] = mouse.conn.projLag(oxyDS,gcamp6corrDS,edgeLen,validRange(3));
        [lagTimeOxy,lagAmpOxy] = mouse.conn.projLag(oxyDS,oxyDS,edgeLen,validRange(1));
        [lagTimeG6,lagAmpG6] = mouse.conn.projLag(gcamp6corrDS,gcamp6corrDS,edgeLen,validRange(2));
        
        lagTimeOxy = lagTimeOxy./info.framerate;
        lagTimeG6 = lagTimeG6./info.framerate;
        lagTimeOxyG6 = lagTimeOxyG6./info.framerate;
        
        %% save
        
        meta.sR = sR;
        meta.fMin = fMin;
        meta.fMax = fMax;
        meta.dsFactor = dsFactor;
        meta.tZone = tZone;
        
        saveFile = strcat(mouseName,"-run",num2str(run),"-projLagOxyG6-ds",num2str(dsFactor),".mat");
        saveFile = fullfile(saveDir,saveSubFolder,saveFile);
        save(saveFile,'lagTimeOxy','lagAmpOxy','lagTimeG6','lagAmpG6','lagTimeOxyG6','lagAmpOxyG6','meta','xform_mask');
        disp(['  took '  num2str(toc(t0)) ' seconds.']);
    end
    
end