%% Assumptions made about this experiment:
% Autofluorescence is time invariant.

% processing:
%   logmean on all channels
%   obtain Hb through procOIS
%   gsr on Hb

%% params
% databaseFile = 'D:\data\NewProbeSample.xlsx';
databaseFile = 'D:\data\SalineProbe.xlsx';
excelInd = 10;  % rows from Excel Database
ledFiles = {'C:\Repositories\GitHub\OIS\Spectroscopy\LED Spectra\150917_TL_470nm_Pol.txt',...
    'C:\Repositories\GitHub\OIS\Spectroscopy\LED Spectra\150917_Mtex_530nm_Pol.txt',...
    'C:\Repositories\GitHub\OIS\Spectroscopy\LED Spectra\150917_TL_590nm_Pol.txt'...
    'C:\Repositories\GitHub\OIS\Spectroscopy\LED Spectra\150917_TL_628nm_Pol.txt'};
hbSpecies = 2:4; % usually 2:4.
probeSpecies = 1;
numLED = numel(hbSpecies) + numel(probeSpecies);
opticalPropertyFile = 'D:\data\opticalProperties\mouseOpticalProperties.mat'; % loads in optical properties
absCoeffFile = 'C:\Repositories\GitHub\OIS\Spectroscopy\prahl_extinct_coef.txt'; % for Hb
dataDir = 'D:\data';
saveDir = 'D:\data';
useGsr = true; % are you going to use global signal regression?

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
    
    sInfo = mouseAnalysis.expSpecific.sysInfo(system);
    
    D = dir(rawLoc); D(1:2) = [];
    for file = 1:numel(D)
        if ~isempty(strfind(D(file).name,[recDate '-' mouse])) && D(file).bytes > 16
            maskLoadFile = fullfile(D(file).folder,D(file).name);
        end
    end
%     maskLoadFile = fullfile(rawLoc,[recDate,'-', mouse,'Pre.tif']);
    saveMaskFile = fullfile(maskDir,[recDate,'-', mouse,'-LandmarksandMask.mat']);
    
    % get landmarks and save mask file
    wlImage = mouseAnalysis.expSpecific.getLandMarksandMask(maskLoadFile, sInfo);
    
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
    
    
    % get mask and info
    load(maskFile);
    isbrain = logical(isbrain);
    info = mouseAnalysis.expSpecific.session2procInfo(sessionType); % getting meta info from session type
    
    
    %% get raw
    disp('Get pre-probe raw');
    preRawFile = fullfile(dataDir,recDate,[recDate '-' mouse '-Raw-Pre.mat']);
%     preRawFile = fullfile(dataDir,recDate,[recDate '-' mouse '-ResampledRaw-Pre.mat']);
    
    load(preRawFile);
    
    %% get Hb
    
%     % led correction. Only fluorescence gets corrected.
%     disp('Correct pre-probe data for LED fluctuations');
%     [x,y] = meshgrid(1:10,1:10);
%     inTriangle = true(size(x));
%     for pix = 1:numel(x)
%         if x(pix) + y(pix) > 10
%             inTriangle(pix) = false;
%         end
%     end
%     x = x(inTriangle); y = y(inTriangle);
%     notBrainInd = y(:)+128*(x(:)-1);
%     preRawNotBrain = mouseAnalysis.expSpecific.getAvgLED(squeeze(preRaw(:,:,probeSpecies,:)),notBrainInd);
%     
%     % only conduct LED correction for probe species
%     preRaw(:,:,probeSpecies,:) = mouseAnalysis.preprocess.removeLinearTrend(preRaw(:,:,probeSpecies,:),preRawNotBrain);
    
    % get Hb from raw pre probe
    disp('Get pre-probe Hb data');
    [preHb, ~, ~, info]=mouseAnalysis.expSpecific.procOIS(preRaw(:,:,hbSpecies,:), info, ledFiles(hbSpecies), isbrain);
    if useGsr
        [preHb, gs, beta]=mouseAnalysis.preprocess.gsr(preHb,isbrain);
    end
    xform_hb = mouseAnalysis.expSpecific.transformHb(preHb, I);
    xform_isbrain = mouseAnalysis.expSpecific.transformHb(isbrain,I);
    
    preHbSize = size(xform_hb);
    xform_hb = reshape(xform_hb,preHbSize(1)*preHbSize(2),preHbSize(3),preHbSize(4));
    xform_hb(~xform_isbrain(:),:,:) = nan;
    xform_hb = reshape(xform_hb,preHbSize);
    
    %% get Fluor
    disp('Get pre-probe fluorescence data');
    preFluor = preRaw(:,:,probeSpecies,:);
    clear preRaw
    
    preFluor = mouseAnalysis.expSpecific.procFluor(preFluor,info,false);
    xform_fluor = mouseAnalysis.expSpecific.transformHb(preFluor, I);
    clear preFluor;
    baselineFluor = mean(xform_fluor,4);
    xform_fluor = xform_fluor./repmat(baselineFluor,[1 1 1 size(xform_fluor,4)]);
    xform_fluor = xform_fluor - 1;
    
%     xform_fluorMean = reshape(xform_fluor,[size(xform_fluor,1)*size(xform_fluor,2) size(xform_fluor,3) size(xform_fluor,4)]);
%     xform_fluorMean = squeeze(nanmean(xform_fluorMean,3));
%     xform_fluorMean = reshape(xform_fluorMean,[size(xform_fluor,1) size(xform_fluor,2)]);
    
%     % get relative ratio
%     preFluorTrend = single(lowpass(double(preFluor),0.009,info.framerate));
%     preFluorRatio = preFluor./preFluorTrend;
%     xform_fluor = transformHb(preFluor, I);
%     clear preFluor;
%     xform_fluorRatio = transformHb(preFluorRatio, I);
%     clear preFluorRatio;
%     xform_fluorCell = catByTime(xform_fluorRatio,preTime,timeBounds);
%     for i = 1:numel(xform_fluorCell)
%         xform_fluorCell{i} = mean(xform_fluorCell{i},4);
%     end
    
    %% save pre-probe data
    disp('Saving pre-probe data');
    t_hb = preTime;
    t_fluor = preTime;
    
    save(saveFilePre,'xform_isbrain','xform_hb','t_hb','xform_fluor',...
        't_fluor','-v7.3');
    
    clear xform_hb xform_fluor xform_fluorRatio
    
    %% get post-probe raw
    disp('Get post-probe Hb data');
    
    D = dir(fullfile(dataDir,recDate));
    D(1:2) = [];
    isFile = false(numel(D),1);
    for dirFile = 1:numel(D)
        strMatches = strfind(D(dirFile).name,[recDate '-' mouse '-Raw-Post-']);
        isFile(dirFile) = ~isempty(strMatches);
    end
    
    for file = 1:sum(isFile)
        disp(['  file #' num2str(file)]);
        postRawFile = fullfile(dataDir,recDate,[recDate '-' mouse '-Raw-Post-' num2str(file) '.mat']);
        load(postRawFile);
        
%         disp('Correct post-probe data for LED fluctuations');
%         
%         % get pixels for LED correction
%         [x,y] = meshgrid(1:10,1:10);
%         inTriangle = true(size(x));
%         for pix = 1:numel(x)
%             if x(pix) + y(pix) > 10
%                 inTriangle(pix) = false;
%             end
%         end
%         x = x(inTriangle); y = y(inTriangle);
%         notBrainInd = y(:)+128*(x(:)-1);
%         postRawNotBrain = mouseAnalysis.expSpecific.getAvgLED(...
%             squeeze(postRawFile(:,:,probeSpecies,:)),notBrainInd);
% 
%         coeff = nan(size(postRawFile,1),size(postRawFile,2),size(postRawFile,3),2);
%         if file == 1
%             initialVal = nan(size(postRawFile,1),size(postRawFile,2));
%             for ch = probeSpecies
%                 [postRawFile(:,:,ch,:), coeffCh,initialValFile] = ...
%                     mouseAnalysis.preprocess.removeLinearTrend(...
%                     postRawFile(:,:,ch,:),postRawNotBrain);
%                 initialVal = initialValFile;
%                 coeff(:,:,ch,:) = coeffCh;
%             end
%         else
%             for ch = probeSpecies
%                 [postRawFile(:,:,ch,:), coeffCh,initialValFile] = ...
%                     mouseAnalysis.preprocess.removeLinearTrend(...
%                     postRawFile(:,:,ch,:),postRawNotBrain,initialVal);
%                 coeff(:,:,ch,:) = coeffCh;
%             end
%         end
%                 
%         clear postRawNotBrain;
        
        oisRaw = postRawFile(:,:,hbSpecies,:);
        fluorRaw = postRawFile(:,:,probeSpecies,:);
        
        clear postRawFile;
        
        %% get post-probe Hb
        
        [hb, WL, op, E, info] = mouseAnalysis.expSpecific.procOIS(oisRaw, info, ledFiles(hbSpecies), isbrain);
        clear oisRaw;
        
        if useGsr % global signal regression
            [hb, gs, beta] = mouseAnalysis.preprocess.gsr(hb,isbrain);
        end
        xform_hb = mouseAnalysis.expSpecific.transformHb(hb, I);
        clear hb;
        
        hbSize = size(xform_hb);
        xform_hb = reshape(xform_hb,hbSize(1)*hbSize(2),hbSize(3),hbSize(4));
        xform_hb(~xform_isbrain(:),:,:) = nan;
        xform_hb = reshape(xform_hb,hbSize);
        
        %% get post-probe Fluor
        
        disp('Get post-probe fluor data');
        postFluor = mouseAnalysis.expSpecific.procFluor(fluorRaw,info,false);
        clear fluorRaw;
        
        %         postFluorTrend = single(lowpass(double(postFluor),...
        %             0.009,info.framerate));
        %         postFluorRatio = postFluor./postFluorTrend;
        %         clear postFluorTrend;
        postFluorT = 1:size(postFluor,4);
        postFluorT = postFluorT./info.freqout;
        
        xform_fluor = mouseAnalysis.expSpecific.transformHb(postFluor, I);
        clear postFluor;
        
        % changing xform_fluor into percentage change
        baselineInd = round(size(xform_fluor,4)*0.9):size(xform_fluor,4);
        baselineFluor = mean(xform_fluor(:,:,:,baselineInd),4);
        xform_fluor = xform_fluor./repmat(baselineFluor,[1 1 1 size(xform_fluor,4)]);
        xform_fluor = xform_fluor - 1;
        %% save post-probe data
        
        disp('Saving post-probe data');
        
        t_hb = postTimeFile;
        t_fluor = postTimeFile;
        
        saveFilePost = fullfile(saveDirMouse,[recDate '-' mouse '-Post-' modification '-' num2str(file) '.mat']);
        save(saveFilePost,'xform_isbrain','xform_hb','t_hb',...
        'xform_fluor','t_fluor','-v7.3');
    
        clear xform_hb t_hb xform_fluor t_fluor
    end
    
end
