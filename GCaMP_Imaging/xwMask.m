% this is to be run only to get mask

% run for each excel row
excelFile = "D:\data\GCaMP_awake.xlsx";
excelRows = 2:7;

speciesNum = 4;

for excelRow = excelRows
    disp(num2str(excelRow));
    
    [~, ~, excelRaw]=xlsread(excelFile,1, ['A',num2str(excelRow),':G',num2str(excelRow)]);
    recDate = excelRaw{1}; recDate = string(recDate);
    mouseName = excelRaw{2}; mouseName = string(mouseName);
    tiffFileDir = excelRaw{3}; tiffFileDir = strcat(tiffFileDir,recDate);
    saveDir = excelRaw{4}; saveDir = string(saveDir);
    systemType = excelRaw{5};
    sessionType = excelRaw{6}; sessionType = sessionType(3:end-2);
    frameRate = excelRaw{7};
    
    systemInfo = mouse.expSpecific.sysInfo(systemType);
    
    maskFileName = strcat(recDate,"-",mouseName,"-mask.mat");
    maskFileName = fullfile(saveDir,maskFileName);
    
    if exist(maskFileName)
    else
        runInd = 1; % for each run
        
        tiffFileName = strcat(recDate,"-",mouseName,"-",sessionType,num2str(runInd),".tif");
        tiffFileName = fullfile(tiffFileDir,tiffFileName);
        
        raw = mouse.preprocess.loadTiffRawMultiple(tiffFileName,speciesNum);
        rgbInd = systemInfo.rgb;
        WL = squeeze(raw(:,:,rgbInd,1)); % makes nxnx3 array for white light image
        [isbrain, markers] = mouse.expSpecific.getLandMarksandMask(WL);
        xform_isbrain = mouse.expSpecific.transformHb(isbrain, markers);
        
        % save mask
        save(maskFileName,'isbrain','xform_isbrain','markers');
    end
    
    close all;
end