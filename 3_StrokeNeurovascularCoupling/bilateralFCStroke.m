function bilateralFCStroke(varargin)
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

fNumel = size(fRange,1);

% spectral parameters
if nargin < 3
    sR = 16.81;
else
    sR = varargin{3};
end

useGsr = true;

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
    
    fcMouse = [];
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
        
        if useGsr
            dataRun = gsr(dataRun,maskRun);
        end
        
        % fc analysis
        fcDataRun = [];
        catDim = (size(fRange,1)>1) + 3;
        for species = 1:size(dataRun,3)
            fcDataRunFreq = [];
            for freq = 1:size(fRange,1)
                fMin = fRange(freq,1);
                fMax = fRange(freq,2);
                
                %% spectral filter
                filtData = mouseAnalysis.freq.filterData(squeeze(dataRun(:,:,species,:)),fMin,fMax,sR);
                fcDataRunFreq = cat(3,fcDataRunFreq,...
                    mouseAnalysis.conn.bilateralFC(filtData));
            end
            
            if size(fRange,1) > 1
                fcDataRun = cat(4,fcDataRun,fcDataRunFreq);
            else
                fcDataRun = cat(3,fcDataRun,fcDataRunFreq);
            end
        end
        
        if numel(size(fcDataRun)) > 3
            fcDataRun = permute(fcDataRun,[1 2 4 3]);
        end
        % spatial x spatial x species x freq
        
        fcMouse = cat(catDim+1,fcMouse,fcDataRun);
        maskMouse = cat(3,maskMouse,maskRun);
    end
    
    % averaging over runs
    fcMouseMean = nanmean(fcMouse,numel(size(fcMouse)));
    maskMouse = nanmean(maskMouse,3);
    
    %% save
    for fInd = 1:fNumel
        % make metaData for quick survey of the data
        metaData.mouse = mouse;
        metaData.fRange = fRange(fInd,:);
        if useGsr
            metaData.sigRes = 'GSR';
        else
            metaData.sigRes = '';
        end
        metaData.speciesNum = size(fcMouse,3);
        metaData.spatialSize = [size(fcMouse,1) size(fcMouse,2)];
        metaData.lagType = 'bilateral';
        
        fcMouse = squeeze(fcMouseMean(:,:,:,fInd));
        
        % save parameters
        fMinStr = num2str(fRange(fInd,1));
        fMinStr(strfind(fMinStr,'.')) = 'p';
        
        fMaxStr = num2str(fRange(fInd,2));
        fMaxStr(strfind(fMaxStr,'.')) = 'p';
        figNameExt = [fMinStr 'to' fMaxStr];
        
        if useGsr
            figNameExt = ['GSR_' figNameExt];
        end
        saveFolder = ['D:\data\zachRosenthal\' week '_fc_bilateral_' figNameExt];
        if exist(saveFolder) == 0
            mkdir(saveFolder);
        end
        saveFile = ['fc_bilateral_' mouseName '_' figNameExt '.mat'];
        save(fullfile(saveFolder,saveFile),'fcMouse','maskMouse','metaData');
    end
    tMouse = toc(tMouse);
    disp(['  Mouse # ' num2str(mouse) ' took ' num2str(tMouse) ' seconds.']);
end