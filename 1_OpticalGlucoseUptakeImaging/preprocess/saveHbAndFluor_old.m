%% Assumptions made about this experiment:
% Autofluorescence is time invariant.

% processing:
%   logmean on all channels
%   obtain Hb through procOIS
%   gsr on Hb


%% params
% databaseFile = 'D:\data\NewProbeSample.xlsx';
databaseFile = 'D:\data\SalineProbe.xlsx';
excelInd = 2;  % rows from Excel Database
ledFiles = {'C:\Repositories\GitHub\OIS\Spectroscopy\LED Spectra\150917_TL_470nm_Pol.txt',...
    'C:\Repositories\GitHub\OIS\Spectroscopy\LED Spectra\150917_Mtex_530nm_Pol.txt',...
    'C:\Repositories\GitHub\OIS\Spectroscopy\LED Spectra\150917_TL_590nm_Pol.txt'...
    'C:\Repositories\GitHub\OIS\Spectroscopy\LED Spectra\150917_TL_628nm_Pol.txt'};
hbSpecies = 2:4;
probeSpecies = 1;
numLED = numel(hbSpecies) + numel(probeSpecies);
opticalPropertyFile = 'D:\data\opticalProperties\mouseOpticalProperties.mat';
absCoeffFile = 'C:\Repositories\GitHub\OIS\Spectroscopy\prahl_extinct_coef.txt';
winSize = 600; % seconds
dataDir = 'D:\data';
saveDir = 'D:\data';
vidDir = 'D:\figures\glucoseUptakeImaging';
timeBounds = [0.5:59.5;1.5:60.5];
useGsr = 1;

%% load optical properties
load(opticalPropertyFile); % op
[waveLenHb, hbCoeffTemp] = getAbsCoeff(absCoeffFile);
[waveLenLed, intensityCell] = getLedFromText(ledFiles);
waveLength = 300:2:1000;
ledPower = nan(numel(waveLength),numel(intensityCell));
hbCoeff = nan(numel(waveLength),2);

% find led intensity at the waveLengths
for source = 1:numel(intensityCell)
    % Interpolate from Spectrometer Wavelengths to Reference Wavelengths
    ledPower(:,source) = interp1(waveLenLed{1},intensityCell{source},waveLength,'pchip');
end

for species = 1:size(hbCoeff,2)
    hbCoeff(:,species) = interp1(waveLenHb,hbCoeffTemp(:,species),waveLength,'pchip');
end
%%

if useGsr
    modification = 'GSR';
else
    modification = '';
end

%% for each mouse create mask
for n=excelInd
    %% make mask (skipped if already made)
    disp('Make mask');
    % read from database
    [~, ~, raw]=xlsread(databaseFile,1, ['A',num2str(n),':F',num2str(n)]);
    % get relevant values from database
    recDate=num2str(raw{1});
    mouse=raw{2};
    rawdatadir=raw{3};
    saveloc=raw{4};
    system=raw{5};
    sessionType=eval(raw{6});
    rawLoc=fullfile(rawdatadir, recDate);
    maskDir=fullfile(saveloc, recDate);
    
    D = dir(rawLoc); D(1:2) = [];
    for file = 1:numel(D)
        if ~isempty(strfind(D(file).name,[recDate '-' mouse])) && D(file).bytes > 16
            maskLoadFile = fullfile(D(file).folder,D(file).name);
        end
    end
%     maskLoadFile = fullfile(rawLoc,[recDate,'-', mouse,'Pre.tif']);
    saveMaskFile = fullfile(maskDir,[recDate,'-', mouse,'-LandmarksandMask.mat']);
    
    % get landmarks and save mask file
    wlImage = getLandMarksandMask(maskLoadFile, saveMaskFile, system);
    
    % save WL image
    maskPicFile = fullfile(maskDir,[recDate,'-',mouse,'-WL.tif']);
    if ~isempty(wlImage)
        imwrite(wlImage,maskPicFile,'tiff');
    end
end

%% for each mouse get data and analyze
for n = excelInd
    disp(['Excel row # ' num2str(n) '/' num2str(numel(excelInd)+1)]);
    
    % read from database
    [~, ~, raw]=xlsread(databaseFile,1, ['A',num2str(n),':F',num2str(n)]);
    % get relevant values from database
    recDate=num2str(raw{1});
    mouse=raw{2};
    rawdatadir=raw{3};
    saveloc=raw{4};
    system=raw{5};
    sessionType = eval(raw{6});
    rawLoc = fullfile(rawdatadir, recDate);
    maskDir = fullfile(saveloc, recDate);
    maskFile = fullfile(maskDir,[recDate,'-',mouse,'-LandmarksandMask.mat']);
    saveDirMouse = fullfile(saveDir,recDate);
    
    saveFilePre = fullfile(saveDirMouse,[recDate '-' mouse '-Pre-' modification '.mat']);
    saveFilePost = fullfile(saveDirMouse,[recDate '-' mouse '-Post-' modification '.mat']);
    
    
    % get mask and info
    load(maskFile);
    isbrain = logical(isbrain);
    info = session2procInfo(sessionType); % getting meta info from session type
    
    
    %% get raw
    disp('Get pre-probe raw');
    preRawFile = fullfile(dataDir,recDate,[recDate '-' mouse '-ResampledRaw-Pre.mat']);
%     preRawFile = fullfile(dataDir,recDate,[recDate '-' mouse '-ResampledRaw-Pre.mat']);
    
    load(preRawFile);
    
    
    %% get Hb
    
    % get Hb from raw pre probe
    disp('Get pre-probe Hb data');
    [preHb, ~, ~, ~, info]=procOIS(preRaw(:,:,hbSpecies,:), info, ledFiles(hbSpecies), isbrain);
    if useGsr
        [preHb, gs, beta]=gsr(preHb,isbrain);
    end
    xform_preHb = transformHb(preHb, I);
    xform_isbrain = transformHb(isbrain,I);
    
    preHbSize = size(xform_preHb);
    xform_preHb = reshape(xform_preHb,preHbSize(1)*preHbSize(2),preHbSize(3),preHbSize(4));
    xform_preHb(~xform_isbrain(:),:,:) = nan;
    xform_preHb = reshape(xform_preHb,preHbSize);
    
    % categorize by time
    preHbCell = catByTime(xform_preHb,preTime,timeBounds);
    
    preHbOAvg = [];
    preHbRAvg = [];
    for time = 1:60
        preHbOAvg = cat(3,preHbOAvg,mean(squeeze(preHbCell{time}(:,:,1,:)),3));
        preHbRAvg = cat(3,preHbRAvg,mean(squeeze(preHbCell{time}(:,:,2,:)),3));
    end
    
    %% get Fluor
    disp('Get pre-probe fluorescence data');
    preFluor = preRaw(:,:,probeSpecies,:);
    preFluor = procFluor(preFluor,info,false);
    preFluorDetrended = procFluor(preFluor,info,true);
    xform_preFluor = transformHb(preFluor, I);
    xform_preFluorDetrended = transformHb(preFluorDetrended, I);
    clear preRaw
    
    preFluorCell = catByTime(xform_preFluor,preTime,timeBounds);
    
    
    %% save pre-probe data
    disp('Saving pre-probe data');
%     imagesc2Vid(preHbOAvg,4,[-0.003 0.003],fullfile(vidDir,[recDate '-' mouse '-HbO' modification '_pre.avi']));
%     imagesc2Vid(preHbRAvg,4,[-0.003 0.003],fullfile(vidDir,[recDate '-' mouse '-HbR' modification '_pre.avi']));
%     imagesc2Vid(preHbOAvg,4,[-0.003 0.003],fullfile(vidDir,[recDate '-' mouse '-HbO' modification '_pre_Compressed.avi']),'Compressed');
%     imagesc2Vid(preHbRAvg,4,[-0.003 0.003],fullfile(vidDir,[recDate '-' mouse '-HbR' modification '_pre_Compressed.avi']),'Compressed');
    
    xform_datahb = xform_preHb;
    t_hb = preTime;
    datahbCell = preHbCell;
    xform_dataFluor = xform_preFluor;
    xform_dataFluorDetrended = xform_preFluorDetrended;
    t_Fluor = preTime;
    dataFluorCell = preFluorCell;
    
    save(saveFilePre,'xform_isbrain','xform_datahb','t_hb','datahbCell','xform_dataFluor','xform_dataFluorDetrended','t_Fluor','dataFluorCell','-v7.3');
    
    %% get post-probe raw
    disp('Get post-probe raw');
%     postRawFile = fullfile(dataDir,recDate,[recDate '-' mouse '-ResampledRaw-Post.mat']);
    postRawFile = fullfile(dataDir,recDate,[recDate '-' mouse '-ResampledRaw-Post.mat']);
    load(postRawFile);
    
    %% get post-probe Hb
    
    disp('Get post-probe Hb data');
    
    [postHb, WL, op, E, info] = procOIS(postRaw(:,:,hbSpecies,:), info, ledFiles(hbSpecies), isbrain);
    
    if useGsr % global signal regression
        [postHb, gs, beta]=gsr(postHb,isbrain);
    end
    xform_postHb = transformHb(postHb, I);
    
    postHbSize = size(xform_postHb);
    xform_postHb = reshape(xform_postHb,postHbSize(1)*postHbSize(2),postHbSize(3),postHbSize(4));
    xform_postHb(~xform_isbrain(:),:,:) = nan;
    xform_postHb = reshape(xform_postHb,postHbSize);
    
    % categorize by time
    postHbCell = catByTime(xform_postHb,postTime,timeBounds);
    
    postHbOAvg = [];
    postHbRAvg = [];
    for time = 1:60
        postHbOAvg = cat(3,postHbOAvg,mean(squeeze(postHbCell{time}(:,:,1,:)),3));
        postHbRAvg = cat(3,postHbRAvg,mean(squeeze(postHbCell{time}(:,:,2,:)),3));
    end
    
    %% get post-probe Fluor
    
    disp('Get post-probe fluor data');
    postFluor = procFluor(postRaw(:,:,probeSpecies,:),info,false);
    postFluorDetrended = procFluor(postRaw(:,:,probeSpecies,:),info,true);
    xform_postFluor = transformHb(postFluor, I);
    xform_postFluorDetrended = transformHb(postFluorDetrended, I);
    postFluorT = 1:size(postFluor,4); postFluorT = postFluorT./info.freqout;
    postFluorCell = catByTime(postFluor,postTime,timeBounds);
    
    %% save post-probe data
    
    disp('Saving post-probe data');
%     imagesc2Vid(postHbOAvg,4,[-0.003 0.003],fullfile(vidDir,[recDate '-' mouse '-HbO' modification '_post.avi']));
%     imagesc2Vid(postHbRAvg,4,[-0.003 0.003],fullfile(vidDir,[recDate '-' mouse '-HbR' modification '_post.avi']));
%     imagesc2Vid(postHbOAvg,4,[-0.003 0.003],fullfile(vidDir,[recDate '-' mouse '-HbO' modification '_post_Compressed.avi']),'Compressed');
%     imagesc2Vid(postHbRAvg,4,[-0.003 0.003],fullfile(vidDir,[recDate '-' mouse '-HbR' modification '_post_Compressed.avi']),'Compressed');
    
    xform_datahb = xform_postHb;
    t_hb = postTime;
    datahbCell = postHbCell;
    xform_dataFluor = xform_postFluor;
    xform_dataFluorDetrended = xform_postFluorDetrended;
    t_Fluor = postTime;
    dataFluorCell = postFluorCell;
    
    save(saveFilePost,'xform_isbrain','xform_datahb','t_hb','datahbCell','xform_dataFluor','xform_dataFluorDetrended','t_Fluor','dataFluorCell','-v7.3');
    
    clear postRaw postHb postHbCell postFluor postFluorCell
    
    
end
