% run for each excel row
excelFile = "D:\data\GCaMP_awake.xlsx";
excelRows = 2:7;

for excelRow = excelRows
    [~, ~, excelRaw]=xlsread(excelFile,1, ['A',num2str(excelRow),':G',num2str(excelRow)]);
    recDate = excelRaw{1}; recDate = string(recDate);
    mouseName = excelRaw{2}; mouseName = string(mouseName);
    tiffFileDir = excelRaw{3}; tiffFileDir = strcat(tiffFileDir,recDate);
    saveDir = excelRaw{4}; saveDir = string(saveDir);
    systemType = excelRaw{5};
    sessionType = excelRaw{6}; sessionType = sessionType(3:end-2);
    frameRate = excelRaw{7};
    
    systemInfo = mouse.expSpecific.sysInfo(systemType);
    sessionInfo = mouse.expSpecific.session2procInfo(sessionType);
    
    % manually change sessionInfo since Xiaodan uses some different
    % parameters for fc and stim sessions
    if strcmp(char(sessionType),'fc')
        sessionInfo.framerate = frameRate;
        sessionInfo.freqout = frameRate;
        sessionInfo.highpass = 0.01;
        sessionInfo.lowpass = 0.5;
    elseif strcmp(char(sessionType),'stim')
        sessionInfo.framerate = frameRate;
        sessionInfo.freqout = frameRate;
        sessionInfo.highpass = 0.01;
        sessionInfo.lowpass = 8;
        % Highpass is already at Nyquist frequency for downsampled
        % frequency. I recommend making downsampling not as harsh
        % (maybe make it 8 Hz?)
    end
    
    maskFileName = strcat(recDate,"-",mouseName,"-mask.mat");
    maskFileName = fullfile(saveDir,maskFileName);
    
    for runInd = 1:3 % for each run
        
        tiffFileName = strcat(recDate,"-",mouseName,"-",sessionType,num2str(runInd),".tif");
        tiffFileName = fullfile(tiffFileDir,tiffFileName);
        saveDataFileName = strcat(recDate,"-",mouseName,"-",sessionType,num2str(runInd),"-processed.mat");
        saveDataFileName = fullfile(saveDir,saveDataFileName);
        
        if isfile(maskFileName)
            
            load(maskFileName);
            
            % mask file exists
            [raw, time, xform_hb, xform_gcamp, xform_gcampCorr, isbrain, xform_isbrain, markers] ...
                = gcamp.gcampImaging(tiffFileName, systemInfo, sessionInfo, isbrain, markers);
        else
            % mask file does not exist, so it has to be created
            [raw, time, xform_hb, xform_gcamp, xform_gcampCorr, isbrain, xform_isbrain, markers] ...
                = gcamp.gcampImaging(tiffFileName, systemInfo, sessionInfo);
            
            % save mask
            save(maskFileName,'isbrain','xform_isbrain','markers');
        end
        
        % save data
        save(saveDataFileName,'raw','time','xform_hb','xform_gcamp','xform_gcampCorr',...
            'isbrain','xform_isbrain','markers','-v7.3');
    end
end