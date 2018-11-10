%% Objective

% Get lag matrix for signal with global signal

%% parameters

% load parameters
excelFile = fullfile('D:\data','Stroke Study 1 sorted.xlsx');

fileInd = 4:5; % which mice to do (excel row ind)
frameRate = 16.81;

figDir = 'D:\figures\3_StrokeNeurovascularCoupling';
% data choice parameters
species = 1:2; % HbO == 1

% spectral parameters
sR = 1;
fMin = 0.009;
fMax = 0.08;
butterOrder = 5;

% lag parameters
reduceRatio = 1; % has to be power of 4
tZone = 7;
edgeLen = 3;

% save parameters
saveFolder = 'D:\data\zachRosenthal';

% switches
loadData = true; % should be true unless you want to use data and mask variables from previous run
useFilter = true;
saveData = true;

%% readying for multiple files

fileNumel = numel(fileInd);


%% actual analysis

for file = 1:fileNumel
    % initialization
    lagMat = [];
    beta = {};
    gs = {};
    mask = [];
    [~, ~, raw]=xlsread(excelFile,1, ['A',num2str(fileInd(file)),':F',num2str(fileInd(file))]);
    mouseName = raw{2};
    saveFile = ['HbT_lag_gs_' mouseName '.mat'];
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
            maskFile = xform_mask;
            
        else
            disp('  Skipping loading data');
            
        end
        t1 = toc(t1);
        disp(['    Took ' num2str(t1) ' seconds.']);
        
        t2 = tic;
        disp('  Getting global signal');
        %% get global signal
        data = cat(3,reshape(oxy,[128,128,1,size(oxy,3)]),reshape(deoxy,[128,128,1,size(deoxy,3)]));
        [gsrData, globalSignal, betaRun]=gsr(data,maskFile);
        
        data = squeeze(sum(data(:,:,species,:),3));
        globalSignal = squeeze(sum(globalSignal(species,:),1));
        t2 = toc(t2);
        disp(['    Took ' num2str(t2) ' seconds.']);
        
        %% spectral filter
        
        t3 = tic;
        if useFilter
            disp('  Conducting spectral filtering');
            
            % butterworth
            [b,a] = butter(butterOrder,[fMin fMax]/(sR/2));
            
            % make wavelet for that freq
            fCenter = (fMin + fMax)/2;
            fwhm = fMax - fMin;
            wavelet = makeGabor(fCenter,fwhm,sR);
            
            filtData = zeros(size(data));
            
            % for each spatial and species
            for spatDim1 = 1:size(data,1)
%                 if mod(spatDim1,round(size(data,1)/16)) == 1
%                     disp(['    ' num2str(spatDim1) '/' num2str(size(data,1))]);
%                 end
                for spatDim2 = 1:size(data,2)
                    ind = [1 size(data,3)];
                    % select the data. Edges are considered to reduce edge effects.
                    edgeLength = round(numel(wavelet)/2);
                    [selectedData, realInd, hasFalse] = selectWithEdges(squeeze(data(spatDim1,spatDim2,:)),ind,edgeLength);
                    
                    % filter
                    filtDataTemp = filtfilt(b,a,selectedData);
                    filtDataTemp = filtDataTemp(realInd(1):realInd(2));
                    
                    filtData(spatDim1,spatDim2,:) = filtDataTemp;
                end
            end
            
            % global signal filter
            
            ind = [1 size(data,3)];
            [selectedData, realInd, hasFalse] = selectWithEdges(squeeze(globalSignal),ind,edgeLength);
            gsTemp = filtfilt(b,a,selectedData);
            gsTemp = gsTemp(realInd(1):realInd(2));
            globalSignal = gsTemp;
        else
            disp('  Skipping spectral filtering');
            filtData = data;
        end
        t3 = toc(t3);
        disp(['    Took ' num2str(t3) ' seconds.']);
        
        %% lag analysis
        
        t4 = tic;
        disp('  Conducting lag analysis');
        % choose species (in this case we just combine HbO and HbR)
        globSubHb = real(filtData);
        
        % reduce spatial dimension to 1 (Hilbert curve)
        globSubReshaped = nan(size(globSubHb,1)*size(globSubHb,2), size(globSubHb,3));
        for time = 1:size(globSubHb,3)
            [globSubReshaped(:,time), hilbertInd] = hilbertCurve(globSubHb(:,:,time)); % reducing 2D to 1D with hilbert curve
        end
        maskHilbert = hilbertCurve(logical(maskFile)); % reducing 2D to 1D for mask
        
        % reduce dimensionality
        maxPix = size(globSubReshaped,1);
        globSubReshaped = globSubReshaped(reduceRatio:reduceRatio:maxPix,:);
        maskHilbert = maskHilbert(reduceRatio:reduceRatio:maxPix);
        
        
        % initialize array for lag data and amplitude data
        lagMatRun = zeros(size(globSubReshaped,1),1);
        ampMatFile = zeros(size(globSubReshaped,1),1);
        
        % finding covariance for each pixel pairs
        for pix1 = 1:size(globSubReshaped,1) % for each pixel
            
%             if mod(pix1,size(globSubReshaped,1)/32)==1
%                 disp(['    ' num2str(pix1) '/' num2str(size(globSubReshaped,1))]); % just displaying which pixel we are on
%             end
            if maskHilbert(pix1)
                
                data1 = squeeze(globSubReshaped(pix1,:));
                
                [lagTime,lagAmp,covResult] = findLag(data1,globalSignal,edgeLen); % finding lag; data 1 lags gs by how much
                
                % adjust lag time to frame rate
                lagTime = lagTime/frameRate;
                
                % remove any lag time that is absurd
                if abs(lagTime) > tZone
                    lagTime = NaN;
                    lagAmp = NaN;
                end
                
                lagMatRun(pix1) = lagTime;
                ampMatFile(pix1) = lagAmp;
            end
        end
        t4 = toc(t4);
        disp(['    Took ' num2str(t4) ' seconds.']);
        
        lagMatRun = lagMatRun./sR;
        % row pixel data lags behind col pixel data by how much. Should take
        % average to a row vector to get average lag.
        
        lagMatRun = hilbertCurveRev(lagMatRun);
        maskHilbert = hilbertCurveRev(maskHilbert);
        
        % add to total matrix
        lagMat = cat(3,lagMat,lagMatRun);
        beta = [beta;{betaRun}];
        gs = [gs;{globalSignal}];
        mask = cat(3,mask,maskHilbert);
    end
    
    %% plot
    
    disp('Plotting and Saving');
    
    for run = 1:3
        f1 = figure('Position',[100 100 600 500]);
        plotData = squeeze(lagMat(:,:,run));
        alphaData = double(mean(mask,3));
        alphaData(isnan(plotData(:))) = 0;
        image1 = imagesc(plotData,[-0.5 0.5]);
        set(image1,'AlphaData',alphaData);
        colormap('jet');
        colorbar();
        savefig(f1,fullfile(figDir,[mouseName '-' num2str(run) '.fig']));
        close(f1)
    end
    
    f2 = figure('Position',[100 100 600 500]);
    plotData = nanmean(lagMat,3);
    alphaData = double(mean(mask,3));
    alphaData(isnan(plotData(:))) = 0;
    image1 = imagesc(plotData,[-0.5 0.5]);
    set(image1,'AlphaData',alphaData);
    colormap('jet');
    colorbar();
    savefig(f2,fullfile(figDir,[mouseName '-mean.fig']));
    close(f2)
    
    %% save
    
    if saveData
        save(fullfile(saveFolder,saveFile),'lagMat','beta','gs','mask');
    end
end





% individual

% mouse = 1;
% disp('Plot');
% figure('Position',[100 100 600 500]);
% image1 = imagesc(squeeze(lagMat(:,:,mouse)),[-1 1]);
% set(image1,'AlphaData',double(squeeze(mask(:,:,mouse))));
% colormap('jet');
% colorbar();


