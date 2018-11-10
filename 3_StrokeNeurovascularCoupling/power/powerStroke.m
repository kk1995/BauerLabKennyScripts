function powerStroke(varargin)
% bilateralLagStroke(fileInd,fRange,sR)

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

% spectral parameters
if nargin < 3
    sR = 16.81;
else
    sR = varargin{3};
end

if nargin < 4
    badRuns = cell(numel(fileInd),1);
else
    badRuns = varargin{4};
end

if nargin < 5
    useGsr = false;
else
    useGsr = varargin{5};
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
    
    % removes bad runs specified
    runDir(badRuns{mouse}) = [];
    
    dataFreq = [];
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
        
        % power analysis
        dataRunSize = size(dataRun);
%         dataRunFreq = nan([dataRunSize(1:end-1) size(fRange,1)]);
        dataRunFreq = fft(dataRun,dataRunSize(end),numel(dataRunSize));
        f = linspace(0,sR,dataRunSize(end));
        fInd = find(f >= fRange(1),1,'first'):find(f <= fRange(2),1,'last');
        dataRunFreq = dataRunFreq(:,:,:,fInd);
        f = f(fInd);
%         for freq = 1:size(fRange,1)
%             dataRunFreqTemp = filterData(dataRun,fRange(freq,1),fRange(freq,2),sR);
%             dataRunFreqTemp = rms(dataRunFreqTemp,4);
%             dataRunFreq(:,:,:,freq) = dataRunFreqTemp;
%         end
        
        dataFreq = cat(numel(size(dataRunFreq))+1,dataFreq,dataRunFreq);
    end
    
    % averaging over runs
    dataFreq = nanmean(dataFreq,numel(size(dataFreq)));
    
    %% save
    % make metaData for quick survey of the data
    metaData.mouse = mouse;
    metaData.fRange = fRange;
    if useGsr
        metaData.sigRes = 'GSR';
    else
        metaData.sigRes = '';
    end
    if useGsr
        figNameExt = '_GSR';
    else
        figNameExt = '';
    end
    saveFolder = ['D:\data\zachRosenthal\' week '_power' figNameExt];
    if exist(saveFolder) == 0
        mkdir(saveFolder);
    end
    saveFile = ['power_' mouseName figNameExt '.mat'];
    save(fullfile(saveFolder,saveFile),'dataFreq','metaData','f','maskRun');
    
    tMouse = toc(tMouse);
    disp(['  Mouse # ' num2str(mouse) ' took ' num2str(tMouse) ' seconds.']);
end