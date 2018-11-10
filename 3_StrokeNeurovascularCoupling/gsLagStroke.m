function gsLagStroke(varargin)
% gsLagStroke(fileInd,fRange,sR)

if nargin < 1
    fileInd = 1:14; % which mice to do (excel row ind)
else
    fileInd = varargin{1};
end

if nargin < 2
    fRange = [0.5 5];
else
    fRange = varargin{2};
end

fNumel = size(fRange,1);

% spectral parameters
if nargin < 3
    sR = 16.81;
else
    sR = varargin{3};
end

if nargin < 4
    tZone = [];
else
    tZone = varargin{4};
end

if nargin < 5
    corrThr = 0.3;
else
    corrThr = varargin{5};
end

%% parameters

% load parameters
excelFile = fullfile('D:\data','Stroke Study 1 sorted.xlsx');

%% readying for multiple files

fileNumel = numel(fileInd);


%% actual analysis

for mouse = 1:fileNumel
    tMouse = tic;
    disp(['File # ' num2str(mouse) '/' num2str(fileNumel)]);
    
    if fileInd(mouse) <= 14
        week = 'baseline';
    elseif fileInd(mouse) <= 28
        week = 'week1';
    elseif fileInd(mouse) <= 42
        week = 'week4';
    else
        week = 'week8';
    end
    
    [~, ~, raw]=xlsread(excelFile,1, ['A',num2str(fileInd(mouse)),':F',num2str(fileInd(mouse))]);
    mouseName = raw{2};
    
    % make str array of run files
    runDir = [];
    for run = 1:3
        dataDir = raw{3};
        dataDate = num2str(raw{1});
        fileName = [dataDate '-' raw{2} '-dataGCaMP-fc' num2str(run) '.mat'];
        runDir = [runDir; string(fullfile(dataDir,dataDate,fileName))];
    end
    
    lagMouse = [];
    ampMouse = [];
    maskMouse = [];
    for run = 1:numel(runDir)
        disp(['  Run # ' num2str(run)]);
        % load data
        load(runDir(run),'oxy','deoxy','gcamp6corr','xform_mask');
        maskRun = logical(xform_mask);
        
        % make data variable
        hbO = reshape(oxy,128,128,1,[]); clear oxy;
        hbR = reshape(deoxy,128,128,1,[]); clear deoxy;
        dataRun = cat(3,hbO,hbR); 
        hbT = hbO+hbR;
        dataRun = cat(3,dataRun,hbT); clear hbO; clear hbR; clear hbT;
        gcamp = reshape(gcamp6corr,128,128,1,[]); clear gcamp6corr;
        dataRun = cat(3,dataRun,gcamp); clear gcamp;
        
        % lag analysis
        [lagRun, ampRun] = gsLagFile(dataRun,sR,maskRun,fRange,tZone,corrThr);
        
        lagMouse = cat(numel(size(lagRun))+1,lagMouse,lagRun);
        ampMouse = cat(numel(size(lagRun))+1,ampMouse,ampRun);
        maskMouse = cat(3,maskMouse,maskRun);
    end
    
    % averaging over runs
    lagMouseMean = nanmean(lagMouse,numel(size(lagMouse)));
    ampMouseMean = nanmean(ampMouse,numel(size(lagMouse)));
    
    %% save
    for fInd = 1:fNumel
        % make metaData for quick survey of the data
        metaData.mouse = mouse;
        metaData.fRange = fRange(fInd,:);
        metaData.corrThr = corrThr;
        metaData.sigRes = '';
        metaData.speciesNum = size(lagMouseMean,3);
        metaData.spatialSize = [size(lagMouseMean,1) size(lagMouseMean,2)];
        metaData.lagType = 'gs';
        
        lagMouse = squeeze(lagMouseMean(:,:,:,fInd));
        ampMouse = squeeze(ampMouseMean(:,:,:,fInd));
        
        % save parameters
        fMinStr = num2str(fRange(fInd,1));
        fMinStr(strfind(fMinStr,'.')) = 'p';
        
        fMaxStr = num2str(fRange(fInd,2));
        fMaxStr(strfind(fMaxStr,'.')) = 'p';
        figNameExt = [fMinStr 'to' fMaxStr];
        
        saveFolder = ['D:\data\zachRosenthal\' week '_lag_gs_' figNameExt];
        if exist(saveFolder) == 0
            mkdir(saveFolder);
        end
        saveFile = ['lag_gs_' mouseName '_' figNameExt '.mat'];
        save(fullfile(saveFolder,saveFile),'lagMouse','ampMouse','maskMouse','metaData');
    end
    tMouse = toc(tMouse);
    disp(['  Mouse # ' num2str(mouse) ' took ' num2str(tMouse) ' seconds.']);
end