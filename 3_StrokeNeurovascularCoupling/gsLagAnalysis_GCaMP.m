function gsLagAnalysis_GCaMP(varargin)
% gsLagAnalysis_GCaMP(fileInd,fRange,sR)

if nargin < 1
    fileInd = 1:14; % which mice to do (excel row ind)
else
    fileInd = varargin{1};
end

if nargin < 2
    % fMin = 0.009; fMax = 0.5;
    fRange = [0.5 5];
else
    fRange = varargin{2};
end
fMin = fRange(1);
fMax = fRange(2);

% spectral parameters
if nargin < 3
    sR = 16.81;
else
    sR = varargin{3};
end

%% Objective

% Get lag matrix for signal with global signal

%% parameters

% load parameters
excelFile = fullfile('D:\data','Stroke Study 1 sorted.xlsx');

figDir = 'D:\figures\3_StrokeNeurovascularCoupling';



fMinStr = num2str(fMin);
fMinStr(strfind(fMinStr,'.')) = 'p';

fMaxStr = num2str(fMax);
fMaxStr(strfind(fMaxStr,'.')) = 'p';
figNameExt = [fMinStr 'to' fMaxStr];

% lag parameters
tZone = 2;
edgeLen = 3;



% switches
loadData = true; % should be true unless you want to use data and mask variables from previous run
useFilter = true;
saveData = true;

%% readying for multiple files

fileNumel = numel(fileInd);


%% actual analysis

for file = 1:fileNumel
    
    if fileInd(file) <= 14
        week = 'baseline';
    elseif fileInd(file) <= 28
        week = 'week1';
    elseif fileInd(file) <= 42
        week = 'week4';
    else
        week = 'week8';
    end
    
    
    % save parameters
    saveFolder = ['D:\data\zachRosenthal\' week '_GCaMP_lag_gs_' figNameExt];
    
    if exist(saveFolder) == 0
        mkdir(saveFolder);
    end
    
    % initialization
    lagMat = [];
    ampMat = [];
    mask = [];
    
    [~, ~, raw]=xlsread(excelFile,1, ['A',num2str(fileInd(file)),':F',num2str(fileInd(file))]);
    mouseName = raw{2};
    saveFile = ['GCaMP_lag_gs_' mouseName '_' figNameExt '.mat'];
    disp(['File # ' num2str(file) '/' num2str(fileNumel)]);
    for run = 1:3
        disp(['Run # ' num2str(run)]);
        %% load data
        t1 = tic;
        if loadData
            disp('  Loading data');
            dataDir = raw{3};
            dataDate = num2str(raw{1});
            fileName = [dataDate '-' raw{2} '-dataGCaMP-fc' num2str(run) '.mat'];
            load(fullfile(dataDir,dataDate,fileName));
            maskFile = logical(xform_mask);
            disp(['  ' raw{2}]);
            
        else
            disp('  Skipping loading data');
            
        end
        t1 = toc(t1);
        disp(['    Took ' num2str(t1) ' seconds.']);
        
        data = gcamp6corr;
        
        %% spectral filter
        
        t3 = tic;
        if useFilter
            disp('  Conducting spectral filtering');
            filtData = zeros(size(data));
            
            % for each spatial and species
            for spatDim1 = 1:size(data,1)
                for spatDim2 = 1:size(data,2)
                    ind = [1 size(data,3)];
                    % select the data. Edges are considered to reduce edge effects.
                    edgeLength = round(sR/fMin/2); % consider at least half the wavelength
                    [selectedData, realInd, hasFalse] = selectWithEdges(squeeze(data(spatDim1,spatDim2,:)),ind,edgeLength);
                    
                    % filter
                    filtDataTemp = highpass(selectedData,fMin,sR);
                    filtDataTemp = lowpass(filtDataTemp,fMax,sR);
                    filtDataTemp = filtDataTemp(realInd(1):realInd(2));
                    
                    filtData(spatDim1,spatDim2,:) = filtDataTemp;
                end
            end
        else
            disp('  Skipping spectral filtering');
            filtData = data;
        end
        t3 = toc(t3);
        disp(['    Took ' num2str(t3) ' seconds.']);
        
        %% lag analysis
        
        t4 = tic;
        disp('  Conducting lag analysis');
        lagData = reshape(filtData,size(filtData,1)*size(filtData,2),size(filtData,3));
        lagData = lagData(maskFile(:),:);
        [lagTime,lagAmp] = gsLag(lagData,edgeLen,round(tZone*sR));
        
        % adjust lag time to frame rate
        lagTime = lagTime./sR;
        
        lagMatRun = nan(128,128);
        lagMatRun(maskFile(:)) = lagTime;
        
        ampMatRun = nan(128,128);
        ampMatRun(maskFile(:)) = lagAmp;
        
        % add to total matrix
        lagMat = cat(3,lagMat,lagMatRun);
        ampMat = cat(3,ampMat,ampMatRun);
        mask = cat(3,mask,maskFile);
        
        t4 = toc(t4);
        disp(['    Took ' num2str(t4) ' seconds.']);
    end
    
    %% plot
    
    disp('Plotting and Saving');
    
    for run = 1:3
        f1 = figure('Position',[100 100 600 500]);
        plotData = squeeze(lagMat(:,:,run));
        alphaData = double(mean(mask,3));
        alphaData(isnan(plotData(:))) = 0;
        image1 = imagesc(plotData,[-1 1]);
        set(image1,'AlphaData',alphaData);
        set(gca,'Visible','off');
        colormap('jet');
        colorbar();
        savefig(f1,fullfile(figDir,[mouseName '-' figNameExt '-' num2str(run) '.fig']));
        close(f1)
    end
    
    f2 = figure('Position',[100 100 600 500]);
    plotData = nanmean(lagMat,3);
    alphaData = double(mean(mask,3));
    alphaData(isnan(plotData(:))) = 0;
    image1 = imagesc(plotData,[-1 1]);
    set(image1,'AlphaData',alphaData);
    set(gca,'Visible','off');
    colormap('jet');
    colorbar();
    savefig(f2,fullfile(figDir,[mouseName '-GCaMP' figNameExt '-mean.fig']));
    close(f2)
    
    %% save
    
    if saveData
        save(fullfile(saveFolder,saveFile),'lagMat','ampMat','mask');
    end
end
end