%% Assumptions made about this experiment:
% Autofluorescence is time invariant.

%% params
databaseFile = 'D:\Documents\GitHub\BauerLab\data\NewProbeSample.xlsx';
excelInd = 2;  % rows from Excel Database
ledFiles = {'D:\Documents\GitHub\OIS\Spectroscopy\LED Spectra\150917_TL_628nm_Pol.txt',...
    'D:\Documents\GitHub\OIS\Spectroscopy\LED Spectra\150917_TL_590nm_Pol.txt',...
    'D:\Documents\GitHub\OIS\Spectroscopy\LED Spectra\150917_Mtex_530nm_Pol.txt',...
    'D:\Documents\GitHub\OIS\Spectroscopy\LED Spectra\150917_TL_470nm_Pol.txt'};
oisSpecies = 2:4;
probeSpecies = 1;
numLED = numel(oisSpecies) + numel(probeSpecies);

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
    sessiontype=eval(raw{6});
    rawdataloc=fullfile(rawdatadir, recDate);
    directory=fullfile(saveloc, recDate);
    
    maskLoadFile = fullfile(rawdataloc,[recDate,'-', mouse,'Pre.tif']);
    saveMaskFile = fullfile(directory,[recDate,'-', mouse,'-LandmarksandMask.mat']);
    
    % get landmarks and save mask file
    wlImage = getLandMarksandMask(maskLoadFile, saveMaskFile, system);
    
    % save WL image
    maskFile = fullfile(directory,[recDate,'-',mouse,'-LandmarksandMask.mat']);
    maskPicFile = fullfile(directory,[recDate,'-',mouse,'-WL.tif']);
    if ~isempty(wlImage)
        imwrite(wlImage,maskPicFile,'tiff');
    end
end

%% for each mouse get data and analyze
for n = excelInd
    
    % read from database
    [~, ~, raw]=xlsread(databaseFile,1, ['A',num2str(n),':F',num2str(n)]);
    % get relevant values from database
    recDate=num2str(raw{1});
    mouse=raw{2};
    rawdatadir=raw{3};
    saveloc=raw{4};
    system=raw{5};
    sessiontype=eval(raw{6});
    rawdataloc=fullfile(rawdatadir, recDate);
    directory=fullfile(saveloc, recDate);
    maskFile = fullfile(directory,[recDate,'-',mouse,'-LandmarksandMask.mat']);
    
    %% get Hb
    disp('Get raw');
    % find relevant files
    D = dir(rawdataloc); D(1:2) = [];
    postFileName = {};
    for file = 1:numel(D)
        if ~isempty(strfind(D(file).name,[recDate,'-', mouse]))
            if isempty(strfind(D(file).name,'Pre'))
                postFileName = [postFileName; {D(file).name}];
            end
        end
    end
    preFileName = [recDate,'-', mouse, 'Pre.tif'];
    
    % get raw
    preRawData = loadTiffRaw(fullfile(rawdataloc,preFileName),numLED);
    preRawData(:,:,:,1) = []; % remove first frame
    postRawData = loadTiffRaw(fullfile(rawdataloc,postFileName{1}),numLED);
    postRawData(:,:,:,1) = []; % remove first frame
    lastFrame = squeeze(postRawData(:,:,:,size(postRawData,4))); % used for next file
    for file = 2:numel(postFileName) % for each file for post probe data
        rawDataFile = loadTiffRaw(fullfile(rawdataloc,postFileName{file}),numLED);
        firstFrame = rawDataFile(:,:,:,1);
        diffFrame = lastFrame - firstFrame;
        rawDataFile = rawDataFile + repmat(diffFrame,1,1,1,size(rawDataFile,4));
        lastFrame = squeeze(rawDataFile(:,:,:,size(rawDataFile,4))); % used for next file
        postRawData = cat(4,postRawData,rawDataFile); % load and concat
    end
    
    disp('Get OIS data');
    % getting OIS data
    load(maskFile);
    isbrain = logical(isbrain);
    info = session2procInfo(sessiontype); % getting meta info from session type
    [preDataHb, ~, ~, ~, info]=procOIS(preRawData(:,:,oisSpecies,:), info, ledFiles(oisSpecies), isbrain);
    preDataHb = transformHb(preDataHb, I);
    
    [postDataHb, WL, op, E, info]=procOIS(postRawData(:,:,oisSpecies,:), info, ledFiles(oisSpecies), isbrain);
    postDataHb = transformHb(postDataHb, I);
    
    %% get fluorescence
    disp('Get fluorescence data');
    preFluorData = procFluor(preRawData(:,:,probeSpecies,:),info);
    preFluorData = transformHb(preFluorData, I);
    
    postFluorData = procFluor(postRawData(:,:,probeSpecies,:),info);
    postFluorData = transformHb(postFluorData, I);
    
    %% remove autofluorescence
    disp('Remove autofluorescence');
    
    
end
