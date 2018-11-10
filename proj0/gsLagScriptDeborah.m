%% Objective

% Get lag matrix for signal with global signal

%% parameters

% load parameters
excelFile = fullfile('D:\data','EastDeborah.xlsx');
dataDir = 'J:\Deborah''s data';
group = {'OD'};

% data choice parameters
species = 1; % HbO == 1

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
saveGroup = group{1};
for i = 2:numel(group)
    saveGroup = [saveGroup '_' group{i}];
end
saveFolder = 'D:\data\Deborah';
saveFile = ['HbO_Deborah_gs_' saveGroup '_n'];

% switches
loadData = true; % should be true unless you want to use data and mask variables from previous run
useFilter = true;
saveData = true;

%% readying for multiple files

dataFile = excel2FileBauer(excelFile,dataDir,group);

fileNumel = numel(dataFile);
saveFile = [saveFile num2str(fileNumel) '.mat'];

% initialization
lagMat = [];
beta = [];
gs = {};
mask = [];

%% actual analysis

for file = 1:fileNumel
    t0 = tic;
    disp(['File # ' num2str(file) '/' num2str(fileNumel)]);
    %% load data
    
    t1 = tic;
    if loadData
        disp('  Loading data');
        
        load(fullfile(dataDir,dataFile{file}),'xform_datahb','xform_isbrain');
        
        data = xform_datahb; % n x m x species x time
        maskFile = xform_isbrain; % n x m
        
    else
        disp('  Skipping loading data');
        
    end
    t1 = toc(t1);
    disp(['  Took ' num2str(t1) ' seconds.']);
    
    %% get global signal
    
    [oxyGsr, deOxyGsr, gsFile, betaFile]=gsr(data,maskFile);
    
    data = squeeze(sum(data(:,:,species,:),3));
    gsFile = squeeze(sum(gsFile(species,:),1));
    
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
        [selectedData, realInd, hasFalse] = selectWithEdges(squeeze(gsFile),ind,edgeLength);
        gsTemp = filtfilt(b,a,selectedData);
        gsTemp = gsTemp(realInd(1):realInd(2));
        gsFile = gsTemp;
    else
        disp('  Skipping spectral filtering');
        filtData = data;
    end
    t3 = toc(t3);
    disp(['  Took ' num2str(t3) ' seconds.']);
    
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
    betaHilbert = hilbertCurve(betaFile(1,:));
    
    % reduce dimensionality
    maxPix = size(globSubReshaped,1);
    globSubReshaped = globSubReshaped(reduceRatio:reduceRatio:maxPix,:);
    maskHilbert = maskHilbert(reduceRatio:reduceRatio:maxPix);
    betaHilbert = betaHilbert(reduceRatio:reduceRatio:maxPix);
    
    
    % initialize array for lag data and amplitude data
    lagMatFile = zeros(size(globSubReshaped,1),1);
    ampMatFile = zeros(size(globSubReshaped,1),1);
    
    % finding covariance for each pixel pairs
    for pix1 = 1:size(globSubReshaped,1) % for each pixel
        
        if mod(pix1,size(globSubReshaped,1)/32)==1
            disp(['  ' num2str(pix1) '/' num2str(size(globSubReshaped,1))]); % just displaying which pixel we are on
        end
        if maskHilbert(pix1)
            
            data1 = squeeze(globSubReshaped(pix1,:));
            
            [lagTime,lagAmp,covResult] = findLag(data1,gsFile,edgeLen); % finding lag; data 1 lags gs by how much
            
            % remove any lag time that is absurd
            if abs(lagTime) > tZone
                    lagTime = NaN;
                    lagAmp = NaN;
            end
                
            lagMatFile(pix1) = lagTime;
            ampMatFile(pix1) = lagAmp;
        end
    end
    lagMatFile = lagMatFile./sR;
    % row pixel data lags behind col pixel data by how much. Should take
    % average to a row vector to get average lag.
    
    lagMatFile = hilbertCurveRev(lagMatFile);
    maskHilbert = hilbertCurveRev(maskHilbert);
    
    % add to total matrix
    lagMat = cat(3,lagMat,lagMatFile);
    beta = cat(3,beta,hilbertCurveRev(betaHilbert));
    gs = [gs;{gsFile}];
    mask = cat(3,mask,maskHilbert);
end



%% plot

disp('Plot');
figure('Position',[100 100 600 500]);
image1 = imagesc(nanmean(lagMat,3),[-1 1]);
set(image1,'AlphaData',double(mean(mask,3)));
colormap('jet');
colorbar();

% individual

% mouse = 1;
% disp('Plot');
% figure('Position',[100 100 600 500]);
% image1 = imagesc(squeeze(lagMat(:,:,mouse)),[-1 1]);
% set(image1,'AlphaData',double(squeeze(mask(:,:,mouse))));
% colormap('jet');
% colorbar();

%% save

if saveData
    save(fullfile(saveFolder,saveFile),'lagMat','lagMatMean','beta','gs','mask');
end
