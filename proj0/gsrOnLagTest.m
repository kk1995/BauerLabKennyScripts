%% parameters

% data choice parameters
species = 1; % HbO == 1

% spectral parameters
sR = 1;
fMin = 0.009;
fMax = 0.08;
butterOrder = 5;

% lag parameters
reduceRatio = 64; % has to be power of 4
tZone = 7;
edgeLen = 3;

% save parameters
saveFolder = '/Users/kenny/Documents/GitHub/BauerLab/data';
saveFile = 'withoutGsr_HbO_n3.mat';

% switches
loadData = true; % should be true unless you want to use data and mask variables from previous run
useGsr = true;
useFilter = true;
saveData = false;


%% readying for multiple files
fileNumel = numel(dataFile);
lagMat = [];
lagMatMean = [];
beta = [];
gs = [];

%% actual analysis

for file = 1:fileNumel
    t0 = tic;
    disp(['File # ' num2str(file) '/' num2str(fileNumel)]);
    %% load data
    
    t1 = tic;
    if loadData
        disp('  Loading data');
        
        xform_datahb = zeros(128,128,1,500);
        t = 0:size(xform_datahb,4)-1; t = t./sR;
        for pix1 = 1:128
            for pix2 = 1:128
                time = (t - (pix1-1)*0.02);
                xform_datahb(pix1,pix2,1,:) = (1/0.05).*sin(2*pi*0.05*time) + (1/0.02).*sin(2*pi*0.02*time);
                xform_datahb(pix1,pix2,1,:) = awgn(squeeze(xform_datahb(pix1,pix2,1,:)),20,'measured');
            end
        end
        xform_isbrain = true(128,128);
        
        data = xform_datahb; % n x m x species x time
        mask = xform_isbrain; % n x m
    else
        disp('  Skipping loading data');
        
    end
    
    % get only relevant species
    data = sum(data(:,:,species,:),3);
    
    t1 = toc(t1);
    disp(['  Took ' num2str(t1) ' seconds.']);
    
    %% remove global signal
    
    t2 = tic;
    if useGsr
        disp('  Conducting global signal regression');
        [oxyGsr, ~, gsFile, betaFile]=gsr(data,mask);
        oxyGsr = reshape(oxyGsr,size(data,1),size(data,2),1,size(data,4));
        
        gsrData = oxyGsr;
    else
        disp('  Skipping global signal regression');
        
        gsrData = data;
        betaFile = zeros(size(data,1),size(data,2));
    end
    t2 = toc(t2);
    disp(['  Took ' num2str(t2) ' seconds.']);
    
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
            if mod(spatDim1,round(size(data,1)/16)) == 1
                disp(['    ' num2str(spatDim1) '/' num2str(size(data,1))]);
            end
            for spatDim2 = 1:size(data,2)
                for spec = species
                    ind = [1 size(data,4)];
                    % select the data. Edges are considered to reduce edge effects.
                    edgeLength = round(numel(wavelet)/2);
                    [selectedData, realInd, hasFalse] = selectWithEdges(squeeze(gsrData(spatDim1,spatDim2,spec,:)),ind,edgeLength);
                    
                    % filter
                    filtDataTemp = filtfilt(b,a,selectedData);
                    filtDataTemp = filtDataTemp(realInd(1):realInd(2));
                    
                    filtData(spatDim1,spatDim2,spec,:) = filtDataTemp;
                end
            end
        end
    else
        disp('  Skipping spectral filtering');
        filtData = gsrData;
    end
    t3 = toc(t3);
    disp(['  Took ' num2str(t3) ' seconds.']);
    
    %% lag analysis
    
    t4 = tic;
    disp('  Conducting lag analysis');
    
    % objective is lag matrix (n*m x n*m)
    
    % choose species (in this case we just combine HbO and HbR)
    globSubHb = squeeze(real(filtData));
    
    % reduce spatial dimension to 1 (Hilbert curve)
    globSubReshaped = nan(size(globSubHb,1)*size(globSubHb,2), size(globSubHb,3));
    for time = 1:size(globSubHb,3)
        [globSubReshaped(:,time), hilbertInd] = hilbertCurve(globSubHb(:,:,time)); % reducing 2D to 1D with hilbert curve
    end
    maskHilbert = hilbertCurve(logical(mask)); % reducing 2D to 1D for mask
    betaHilbert = hilbertCurve(betaFile);
    
    % reduce dimensionality
    maxPix = size(globSubReshaped,1);
    globSubReshaped = globSubReshaped(reduceRatio:reduceRatio:maxPix,:);
    maskHilbert = maskHilbert(reduceRatio:reduceRatio:maxPix);
    betaHilbert = betaHilbert(reduceRatio:reduceRatio:maxPix);
    
    % initialize array for lag data and amplitude data
    lagMatFile = zeros(size(globSubReshaped,1));
    ampMat = zeros(size(globSubReshaped,1));
    
    % finding covariance for each pixel pairs
    for pix1 = 1:size(globSubReshaped,1) % for each pixel
        
        if mod(pix1,size(globSubReshaped,1)/16)==1
            disp(['    ' num2str(pix1) '/' num2str(size(globSubReshaped,1))]); % just displaying which pixel we are on
        end
        
        for pix2 = 1:size(globSubReshaped,1) % for each pixel
            if maskHilbert(pix1) && maskHilbert(pix2)
                
                data1 = squeeze(globSubReshaped(pix1,:));
                data2 = squeeze(globSubReshaped(pix2,:));
                
                [lagTime,lagAmp,covResult,sign] = findLag(data1,data2,edgeLen); % finding lag
                
                if abs(lagTime) > tZone
                    lagTime = NaN;
                    lagAmp = NaN;
                end
                
                lagMatFile(pix1, pix2) = lagTime;
                ampMat(pix1, pix2) = lagAmp;
            end
        end
    end
    lagMatFile = lagMatFile./sR;
    
    % find the mean lag for each pixel
    lagMatMeanFile = zeros(size(globSubReshaped,1),1);
    for pix1 = 1:size(globSubReshaped,1)
        if maskHilbert(pix1)
            lagMatMeanFile(pix1) = nanmean(lagMatFile(pix1,maskHilbert));
        end
    end
    
    % revert back to 2D array
    lagMatMeanFile = hilbertCurveRev(lagMatMeanFile);
    
    % add to total matrix
    lagMat = cat(3,lagMat,lagMatFile);
    lagMatMean = cat(3,lagMatMean,lagMatMeanFile);
    beta = cat(3,beta,hilbertCurveRev(betaHilbert));
    gs = cat(1,gs,gsFile);
    
    t4 = toc(t4);
    disp(['  Took ' num2str(t4) ' seconds.']);
    t0 = toc(t0);
    disp(['File took ' num2str(t0) ' seconds.']);
end

%% plot

disp('Plot');

figure('Position',[100 100 600 500]);
imagesc(mean(lagMatMean,3),[-1 1]); colorbar();

figure;
histogram(lagMat(:),'BinWidth',0.1)
set(gca,'YScale','log'); xlim([-7 7]);

%% save

if saveData
    save(fullfile(saveFolder,saveFile),'lagMat','lagMatMean','beta','gs');
end
