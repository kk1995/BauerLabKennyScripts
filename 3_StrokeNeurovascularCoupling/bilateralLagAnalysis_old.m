function bilateralLagAnalysis(varargin)
% gsLagAnalysis(fileInd,fRange,sR)

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

if nargin < 4
    useGsr = false;
else
    useGsr = varargin{4};
end

%% Objective

% Get lag matrix for signal with global signal

%% parameters

% load parameters
excelFile = fullfile('D:\data','Stroke Study 1 sorted.xlsx');

figDir = 'D:\figures\3_StrokeNeurovascularCoupling';
% data choice parameters
% species = 1:2; % HbO == 1

fMinStr = num2str(fMin);
fMinStr(strfind(fMinStr,'.')) = 'p';

fMaxStr = num2str(fMax);
fMaxStr(strfind(fMaxStr,'.')) = 'p';
figNameExt = [fMinStr 'to' fMaxStr];

if useGsr
    figNameExt = ['GSR_' figNameExt];
end

% lag parameters
tZone = 2;
edgeLen = 3;

% save parameters
% saveFolder = ['D:\data\zachRosenthal\week1_HbT_lag_gs_' figNameExt];


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
    saveFolder = ['D:\data\zachRosenthal\' week '_lag_bilateral_' figNameExt];
    
    if exist(saveFolder) == 0
        mkdir(saveFolder);
    end

    % initialization
    lagMat = cell(4,1);
    ampMat = cell(4,1);
    mask = cell(4,1);
    
    [~, ~, raw]=xlsread(excelFile,1, ['A',num2str(fileInd(file)),':F',num2str(fileInd(file))]);
    mouseName = raw{2};
    saveFile = ['lag_bilateral_' mouseName '_' figNameExt '.mat'];
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
        
        data = cat(3,reshape(oxy,128,128,1,[]),reshape(deoxy,128,128,1,[]),reshape(gcamp6corr,128,128,1,[]));
%         data = squeeze(sum(data(:,:,species,:),3));
        
        %% spectral filter
        
        t3 = tic;
        if useFilter
            disp('  Conducting spectral filtering');
            filtData = zeros(size(data));
            
            % for each spatial and species
            for spatDim1 = 1:size(data,1)
%                 disp(num2str(spatDim1));
                for spatDim2 = 1:size(data,2)
                    for specInd = 1:3
                        ind = [1 size(data,4)];
                        % select the data. Edges are considered to reduce edge effects.
                        edgeLength = round(sR/fMin/2); % consider at least half the wavelength
                        [selectedData, realInd, hasFalse] = selectWithEdges(squeeze(data(spatDim1,spatDim2,specInd,:)),ind,edgeLength);
                        
                        % filter
                        filtDataTemp = gaborFilter(selectedData,fMin,fMax,sR);
                        filtDataTemp = real(filtDataTemp);
%                         filtDataTemp = highpass(selectedData,fMin,sR);
%                         filtDataTemp = lowpass(filtDataTemp,fMax,sR);
                        filtDataTemp = filtDataTemp(realInd(1):realInd(2));
                        
                        filtData(spatDim1,spatDim2,specInd,:) = filtDataTemp;
                    end
                end
            end
        else
            disp('  Skipping spectral filtering');
            filtData = data;
        end
        t3 = toc(t3);
        disp(['    Took ' num2str(t3) ' seconds.']);
        
        
        %% gsr
        
        % gsr
        if useGsr
            filtData = gsr(filtData,maskFile);
        end

        %% lag analysis
        
        t4 = tic;
        disp('  Conducting lag analysis');
        lagData = filtData;
%         lagData = reshape(filtData,size(filtData,1)*size(filtData,2),size(filtData,3));
%         lagData = reshape(filtData,size(filtData,1)*size(filtData,2),size(filtData,3),size(filtData,4));
%         lagData = lagData(maskFile(:),:,:);
        
        for specInd = 1:4
            if specInd == 3
                species = 1:2;
            elseif specInd < 3
                species = specInd;
            else
                species = 3;
            end
            [lagTime,lagAmp,covResult] = bilateralLag(squeeze(sum(lagData(:,:,species,:),3)),edgeLen,round(tZone*sR));
            
            % adjust lag time to frame rate
            lagTime = lagTime./sR;
            
            % remove values outside of mask
            lagTime(~maskFile) = nan;
            lagAmp(~maskFile) = nan;
            
            % add to total matrix
            lagMat{specInd} = cat(3,lagMat{specInd},lagTime);
            ampMat{specInd} = cat(3,ampMat{specInd},lagAmp);
            mask{specInd} = cat(3,mask{specInd},maskFile);
        end
        
        t4 = toc(t4);
        disp(['    Took ' num2str(t4) ' seconds.']);
    end
    
    %% plot
    
    disp('Plotting and Saving');
    
    for run = 1:3
        f1 = figure('Position',[100 100 600 500]);
        plotData = squeeze(lagMat{specInd}(:,:,run));
        alphaData = double(mean(mask{specInd},3));
        alphaData(isnan(plotData(:))) = 0;
        image1 = imagesc(plotData,[-1 1]);
        set(image1,'AlphaData',alphaData);
        colormap('jet');
        colorbar();
        savefig(f1,fullfile(figDir,[mouseName '-' figNameExt '-' num2str(run) '.fig']));
        close(f1)
    end
    
    f2 = figure('Position',[100 100 600 500]);
    plotData = nanmean(lagMat{specInd},3);
    alphaData = double(mean(mask{specInd},3));
    alphaData(isnan(plotData(:))) = 0;
    image1 = imagesc(plotData,[-1 1]);
    set(image1,'AlphaData',alphaData);
    colormap('jet');
    colorbar();
    savefig(f2,fullfile(figDir,[mouseName '-' figNameExt '-mean.fig']));
    close(f2)
    
    %% save
    
    if saveData
        save(fullfile(saveFolder,saveFile),'lagMat','ampMat','mask');
    end
end
end