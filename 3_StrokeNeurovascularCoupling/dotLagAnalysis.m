function dotLagAnalysis(varargin)
% dotLagAnalysis(fileInd,fRange,sR)

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

% fMin = fRange(1);
% fMax = fRange(2);

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

fMinStr = num2str(fMin);
fMinStr(strfind(fMinStr,'.')) = 'p';

fMaxStr = num2str(fMax);
fMaxStr(strfind(fMaxStr,'.')) = 'p';
figNameExt = [fMinStr 'to' fMaxStr];

if useGsr
    figNameExt = ['GSR_' figNameExt];
end

% lag parameters
tZone = 8; % in seconds
edgeLen = 3;

% switches
loadData = true; % should be true unless you want to use data and mask variables from previous run
useFilter = true;
saveData = true;

%% readying for multiple files

fileNumel = numel(fileInd);


%% actual analysis

for file = 1:fileNumel % for each file
    
    % determine which week it is from file order
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
    saveFolder = ['D:\data\zachRosenthal\' week '_lag_dot_' figNameExt];
    
    if exist(saveFolder) == 0
        mkdir(saveFolder);
    end

    % initialization of output data
    lagMat = cell(3,1);
    ampMat = cell(3,1);
    mask = cell(3,1);
    
    [~, ~, raw]=xlsread(excelFile,1, ['A',num2str(fileInd(file)),':F',num2str(fileInd(file))]);
    mouseName = raw{2};
    saveFile = ['lag_dot_' mouseName '_' figNameExt '.mat'];
    disp(['File # ' num2str(file) '/' num2str(fileNumel)]);
    for run = 1:3 % for each run in mouse
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
        
        %% gsr
        
        % gsr
        if useGsr
            data = gsr(data,maskFile);
        end
        
        %% spectral filter
        
        t3 = tic;
        if useFilter
            disp('  Conducting spectral filtering');
            filtData = zeros(size(data));
            
            % for each spatial and species
            for spatDim1 = 1:size(data,1)
                for spatDim2 = 1:size(data,2)
                    for specInd = 1:3
                        ind = [1 size(data,4)];
                        % select the data. Edges are considered to reduce edge effects.
                        edgeLength = round(sR/fMin/2); % consider at least half the wavelength
                        [selectedData, realInd, ~] = selectWithEdges(squeeze(data(spatDim1,spatDim2,specInd,:)),ind,edgeLength);
                        
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
        
        % output is 4D matrix with 3rd dimension as species. Species order
        % is HbO, HbR, and gcamp.
        
        %% lag analysis
        
        t4 = tic;
        disp('  Conducting lag analysis');
        for specInd = 1:3
            % determine which hemoglobin species to use
            if specInd < 3
                species = specInd; % HbO, HbR
            else
                species = 1:2; % HbT
            end
            
            % get the filtered data to do lag analysis on
            lagData1 = squeeze(sum(filtData(:,:,species,:),3)); %HbT
            lagData2 = squeeze(filtData(:,:,3,:)); %GCaMP
            
            % find dot lag
            [lagTime,lagAmp] = dotLag(lagData1,lagData2,edgeLen,round(tZone*sR));
            
            % adjust lag time to frame rate
            lagTime = lagTime./sR;
            
            % remove things outside of mask
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
    
    %% save
    
    if saveData
        save(fullfile(saveFolder,saveFile),'lagMat','ampMat','mask');
    end
end
end