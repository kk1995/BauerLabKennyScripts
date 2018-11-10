%% Objective

% 1. To get the paired beta value for each pixel pair
% 2. To get the lag value for each pixel pair
% 3. To place the lag value and beta value together for comparison
% 4. Do comparison analysis (correlation of beta product and absolute of lag value difference?)

%% load data
dataDir = '/Volumes/NO NAME/Data';
dataFile = '150107-Thy1M5-fc-catPreStim.mat';

% load(fullfile(dataDir,dataFile));

data = xform_datahb; % n x m x species x time
mask = xform_isbrain; % n x m

%% remove global signal

disp('Conducting global signal regression');

[oxyGsr, deOxyGsr, gs, beta]=gsr(data,mask);
oxyGsr = reshape(oxyGsr,size(data,1),size(data,2),1,size(data,4));
deOxyGsr = reshape(deOxyGsr,size(data,1),size(data,2),1,size(data,4));

gsrData = cat(3,oxyGsr,deOxyGsr);

%% spectral filter and lag analyses

% parameters
sR = 1;
fMin = 0.009;
fMax = 0.08;
reduceRatio = 16; % has to be power of 4
tZone = 10;
edgeLen = 3;

% butterworth
[b,a] = butter(5,[fMin fMax]/(sR/2));

for condition = 1:2
    if condition == 1
        preFiltData = data;
    else
        preFiltData = gsrData;
    end
    
    % make wavelet for that freq
    fCenter = (fMin + fMax)/2;
    fwhm = fMax - fMin;
    wavelet = makeGabor(fCenter,fwhm,sR);
    
    filtData = zeros(size(data));
    
    % for each spatial and species
    for spatDim1 = 1:size(data,1)
        disp([num2str(spatDim1) '/' num2str(size(data,1))])
        for spatDim2 = 1:size(data,2)
            for species = 1:size(data,3)
                ind = [1 size(data,4)];
                % select the data. Edges are considered to reduce edge effects.
                edgeLength = round(numel(wavelet)/2);
                [selectedData, realInd, hasFalse] = selectWithEdges(squeeze(preFiltData(spatDim1,spatDim2,species,:)),ind,edgeLength);
                
                % filter
                filtDataTemp = conv(selectedData,wavelet,'same');
%                 filtDataTemp = filter(b,a,selectedData);
                filtDataTemp = filtDataTemp(realInd(1):realInd(2));
                
                filtData(spatDim1,spatDim2,species,:) = filtDataTemp;
            end
        end
    end
    
    disp('Conducting lag analysis');
    
    % choose species (in this case we just combine HbO and HbR)
    globSubHb = squeeze(real(filtData(:,:,1,:)));
    
    % reduce spatial dimension to 1 (Hilbert curve)
    globSubReshaped = nan(size(globSubHb,1)*size(globSubHb,2), size(globSubHb,3));
    for time = 1:size(globSubHb,3)
        [globSubReshaped(:,time), hilbertInd] = hilbertCurve(globSubHb(:,:,time)); % reducing 2D to 1D with hilbert curve
    end
    maskHilbert = hilbertCurve(logical(mask)); % reducing 2D to 1D for mask
    betaHilbert = hilbertCurve(beta(1,:));
    
    % reduce dimensionality
    maxPix = size(globSubReshaped,1);
    globSubReshaped = globSubReshaped(reduceRatio:reduceRatio:maxPix,:);
    maskHilbert = maskHilbert(reduceRatio:reduceRatio:maxPix);
    betaHilbert = betaHilbert(reduceRatio:reduceRatio:maxPix);
    
    
    % initialize array for lag data and amplitude data
    lagMat = zeros(size(globSubReshaped,1));
    ampMat = zeros(size(globSubReshaped,1));
    
    % finding covariance for each pixel pairs
    for pix1 = 1:size(globSubReshaped,1) % for each pixel
        
        if mod(pix1,size(globSubReshaped,1)/32)==1
            disp([num2str(pix1) '/' num2str(size(globSubReshaped,1))]); % just displaying which pixel we are on
        end
        
        for pix2 = 1:size(globSubReshaped,1) % for each pixel
            if maskHilbert(pix1) && maskHilbert(pix2)
                
                data1 = squeeze(globSubReshaped(pix1,:));
                data2 = squeeze(globSubReshaped(pix2,:));
                
                [lagTime,lagAmp] = findLag(data1,data2,tZone,edgeLen); % finding lag; data 1 lags data 2 by how much
                
                lagMat(pix1, pix2) = lagTime;
                ampMat(pix1, pix2) = lagAmp;
            end
        end
    end
    % row pixel data lags behind col pixel data by how much. Should take
    % average to a row vector to get average lag.
    
    lagMat = lagMat./sR;
    
    if condition == 1
        lagMatNone = lagMat;
    else
        lagMatGsr = lagMat;
    end
end

%%

% find the mean lag for each pixel
lagMatMean = zeros(size(globSubReshaped,1),1);
for pix1 = 1:size(globSubReshaped,1)
    if maskHilbert(pix1)
        lagMatMean(pix1) = mean(lagMatNone(pix1,maskHilbert),2);
    end
end

% revert back to 2D array
lagMatMean = hilbertCurveRev(lagMatMean);

figure;
imagesc(lagMatMean,[-1 1]);

% find the mean lag for each pixel
lagMatMean = zeros(size(globSubReshaped,1),1);
for pix1 = 1:size(globSubReshaped,1)
    if maskHilbert(pix1)
        lagMatMean(pix1) = mean(lagMatGsr(pix1,maskHilbert),2);
    end
end

% revert back to 2D array
lagMatMean = hilbertCurveRev(lagMatMean);
figure;
imagesc(lagMatMean,[-1 1]);

%% make beta directly comparable

betaHilbert1 = repmat(betaHilbert,numel(betaHilbert),1);
betaHilbert2 = repmat(betaHilbert',1,numel(betaHilbert));

%% compare

x = abs(betaHilbert1(:) .* betaHilbert2(:));
y = abs(lagMatNone(:));
% y = abs(lagMatGsr(:) - lagMatNone(:));

[rho, pVal] = corr(x,y,'type','Pearson');
disp(num2str(rho));
% scatter(x,y,'filled');