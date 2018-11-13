function regionalFCMultipleMice(fileInd,fRange,roiCenter,regionName,varargin)

if isempty(roiCenter)
    roiCenter = [66,33];
end

if isempty(varargin)
    varargin{1} = false;
end
doGsr = varargin{1};

excelFile = fullfile('D:\data','Stroke Study 1 sorted.xlsx');
% fileInd = 1:56; % which mice to do (excel row ind)
% fRange = [0.009 0.5];
sR = 16.81;
species = 1:2;

% calculating other parameters
fMin = fRange(1);
fMax = fRange(2);
fMinStr = num2str(fMin);
fMinStr(strfind(fMinStr,'.')) = 'p';

fMaxStr = num2str(fMax);
fMaxStr(strfind(fMaxStr,'.')) = 'p';
figNameExt = [fMinStr 'to' fMaxStr];

if doGsr
    figNameExt = [figNameExt '-GSR'];
end

% doing analysis for each file
fileNumel = numel(fileInd);
for file = 1:fileNumel
    t0 = tic;
    disp(['File # ' num2str(file)]);
    if fileInd(file) <= 14
        week = 'baseline';
    elseif fileInd(file) <= 28
        week = 'week1';
    elseif fileInd(file) <= 42
        week = 'week4';
    else
        week = 'week8';
    end
    
    [~, ~, raw]=xlsread(excelFile,1, ['A',num2str(fileInd(file)),':F',num2str(fileInd(file))]);
    mouseName = raw{2};
    dataDir = raw{3};
    
    % determine roi
    roi = circleCoor(roiCenter,3);
    roi = (roi(2,:)-1)*128+roi(1,:);
    fcDataHbO = [];
    fcDataHbR = [];
    fcDataHbT = [];
    fcDataGCaMP = [];
    for run = 1:3
        disp(['  Run # ' num2str(run)]);
        % load data
        dataDate = num2str(raw{1});
        fileName = [dataDate '-' raw{2} '-dataGCaMP-fc' num2str(run) '.mat'];
        load(fullfile(dataDir,dataDate,fileName),'oxy','deoxy','gcamp6corr','xform_mask');
        maskRun = logical(xform_mask);
        dataHbO = oxy;
        dataHbR = deoxy;
        dataHbT = cat(3,reshape(oxy,128,128,1,[]),reshape(deoxy,128,128,1,[]));
        clear oxy deoxy
        dataHbT = squeeze(sum(dataHbT(:,:,species,:),3));
        dataGCaMP = gcamp6corr;
        
        % filter data
        dataHbO = mouse.freq.filterData(dataHbO,fMin,fMax,sR);
        dataHbR = mouse.freq.filterData(dataHbR,fMin,fMax,sR);
        dataHbT = mouse.freq.filterData(dataHbT,fMin,fMax,sR);
        dataGCaMP = mouse.freq.filterData(dataGCaMP,fMin,fMax,sR);
        
        % gsr
        if doGsr
            dataHbO = mouse.preprocess.gsr(dataHbO,maskRun);
            dataHbR = mouse.preprocess.gsr(dataHbR,maskRun);
            dataHbT = mouse.preprocess.gsr(dataHbT,maskRun);
            dataGCaMP = mouse.preprocess.gsr(dataGCaMP,maskRun);
        end
        
        
        % fc analysis
        fcDataRun = mouse.conn.regionalFC(dataHbO,fRange,sR,maskRun,roi);
        fcDataRun = mean(fcDataRun,1);
        fcDataRunMouse = nan(128,128);
        fcDataRunMouse(maskRun(:)) = fcDataRun;
        fcDataHbO = cat(3,fcDataHbO,fcDataRunMouse);
        
        fcDataRun = mouse.conn.regionalFC(dataHbR,fRange,sR,maskRun,roi);
        fcDataRun = mean(fcDataRun,1);
        fcDataRunMouse = nan(128,128);
        fcDataRunMouse(maskRun(:)) = fcDataRun;
        fcDataHbR = cat(3,fcDataHbR,fcDataRunMouse);
        
        fcDataRun = mouse.conn.regionalFC(dataHbT,fRange,sR,maskRun,roi);
        fcDataRun = mean(fcDataRun,1);
        fcDataRunMouse = nan(128,128);
        fcDataRunMouse(maskRun(:)) = fcDataRun;
        fcDataHbT = cat(3,fcDataHbT,fcDataRunMouse);
        
        fcDataRun = mouse.conn.regionalFC(dataGCaMP,fRange,sR,maskRun,roi);
        fcDataRun = mean(fcDataRun,1);
        fcDataRunMouse = nan(128,128);
        fcDataRunMouse(maskRun(:)) = fcDataRun;
        fcDataGCaMP = cat(3,fcDataGCaMP,fcDataRunMouse);
        clear dataHbO dataHbR dataHbT dataGCaMP
    end
    
    % save
    saveFolderHbO = ['D:\data\zachRosenthal\' week '_HbO_fc_' regionName '_' figNameExt];
    saveFolderHbR = ['D:\data\zachRosenthal\' week '_HbR_fc_' regionName '_' figNameExt];
    saveFolderHbT = ['D:\data\zachRosenthal\' week '_HbT_fc_' regionName '_' figNameExt];
    saveFolderGCaMP = ['D:\data\zachRosenthal\' week '_GCaMP_fc_' regionName '_' figNameExt];
    
    if exist(saveFolderHbO) == 0
        mkdir(saveFolderHbO);
    end
    
    if exist(saveFolderHbR) == 0
        mkdir(saveFolderHbR);
    end
    
    if exist(saveFolderHbT) == 0
        mkdir(saveFolderHbT);
    end
    
    if exist(saveFolderGCaMP) == 0
        mkdir(saveFolderGCaMP);
    end
    
    saveFileHbO = ['HbO_fc_' mouseName '_' figNameExt '.mat'];
    saveFileHbR = ['HbR_fc_' mouseName '_' figNameExt '.mat'];
    saveFileHbT = ['HbT_fc_' mouseName '_' figNameExt '.mat'];
    saveFileGCaMP = ['GCaMP_fc_' mouseName '_' figNameExt '.mat'];
    save(fullfile(saveFolderHbO,saveFileHbO),'fcDataHbO','xform_mask');
    save(fullfile(saveFolderHbR,saveFileHbR),'fcDataHbR','xform_mask');
    save(fullfile(saveFolderHbT,saveFileHbT),'fcDataHbT','xform_mask');
    save(fullfile(saveFolderGCaMP,saveFileGCaMP),'fcDataGCaMP','xform_mask');
    disp(['Took ' num2str(toc(t0)) ' seconds.']);
    clear fcDataHbO fcDataHbR fcDataHbT fcDataGCaMP
end
end