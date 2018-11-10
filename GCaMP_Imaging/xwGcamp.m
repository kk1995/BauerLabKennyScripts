%% state where the led spectrum files and extinction coefficient files are
ledDir = "C:\Repositories\GitHub\OIS\Spectroscopy\LED Spectra\";
extCoeffDir = "C:\Repositories\GitHub\OIS\Spectroscopy\";

%% run for each excel row
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
    
    for runInd = 1:3 % for each run
        tiffFileName = strcat(recDate,"-",mouseName,"-",sessionType,"-",num2str(runInd),".mat");
        tiffFileName = fullfile(tiffFileDir,tiffFileName);
        saveDataFileName = strcat(recDate,"-",mouseName,"-",sessionType,"-",num2str(runInd),"-processed.mat");
        saveDataFileName = fullfile(saveDir,saveDataFileName);
        maskFileName = strcat(recDate,"-",mouseName,"-",sessionType,"-",num2str(runInd),"-mask.mat");
        maskFileName = fullfile(saveDir,maskFileName);
        
        systemInfo = mouse.expSpecific.sysInfo(systemType);
        sessionInfo = mouse.expSpecific.session2procInfo(sessionType);
        
        if isfile(maskFileName)
            % mask file exists
            [xform_hb, xform_gcamp, xform_gcampCorr, isbrain, xform_isbrain, markers] ...
                = gcampImaging(tiffFileName, systemInfo, sessionInfo, ...
                ledDir, extCoeffDir);
        else
            % mask file does not exist, so it has to be created
            [xform_hb, xform_gcamp, xform_gcampCorr, isbrain, xform_isbrain, markers] ...
                = gcampImaging(tiffFileName, systemInfo, sessionInfo, ...
                ledDir, extCoeffDir, isbrain, markers);
            
            % save mask
            save(maskFileName,'isbrain','xform_isbrain','markers');
        end
        
        % save data
        save(saveDataFileName,'xform_hb','xform_gcamp','xform_gcampCorr',...
            'isbrain','xform_isbrain','markers','-v7.3');
    end
end