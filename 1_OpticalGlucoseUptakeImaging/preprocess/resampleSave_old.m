% saves raw data at lower frequency for me to work with

%% params
% databaseFile = 'D:\data\SalineProbe.xlsx';
databaseFile = 'D:\data\NewProbeSample.xlsx';
excelInd = 5:7;  % rows from Excel Database
saveDir = 'D:\data';
saveFilePref = 'probe';
% saveFilePref = 'saline';
numLED = 4;

%% for each mouse get data and analyze
for n = excelInd
    disp(['Excel row # ' num2str(n) '/' num2str(max(excelInd))]);
    
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
    saveDirMouse = fullfile(saveDir,recDate);
    if ~isfolder(saveDirMouse)
        mkdir(saveDirMouse);
    end
    
    saveFilePre = fullfile(saveDirMouse,[recDate '-' mouse '-ResampledRaw-Pre.mat']);
    saveFilePost = fullfile(saveDirMouse,[recDate '-' mouse '-ResampledRaw-Post.mat']);
    
    %% get Hb
    disp('Get pre-probe raw');
    
    % find relevant files
    [preFileName,postFileName] = getFileNames_Probe(rawdatadir,recDate,mouse); % this depends on which probe data you look at
%     [preFileName,postFileName] = getFileNames_SalineProbe(databaseFile,recDate,mouse); % this depends on which probe data you look at
    
    info = session2procInfo(sessionType); % getting meta info from session type
    preRaw = loadTiffRaw(preFileName,numLED);
    preTime = 0:size(preRaw,4)-1;
    preTime = preTime./info.framerate;
    preRaw(:,:,:,1) = []; % remove first frame
    preTime(1) = [];
    preRaw = double(preRaw);
    disp('  Resampling');
    preRaw = resampledata(preRaw,info.framerate,info.freqout,10^-5);
    preTime = resampledata(preTime,info.framerate,info.freqout,10^-5);
    
    disp('Saving pre-probe data');
    
    save(saveFilePre,'preRaw','preTime');
    
    clear preRaw preTime
    
    disp('Get post-probe raw');
    [postRaw, remainingData] = loadTiffRaw(postFileName{1},numLED);
    postTime = 0:size(postRaw,4)-1;
    postTime = postTime./info.framerate;
    postRaw(:,:,:,1) = [];
    postTime(1) = [];
    postRaw = double(postRaw);
    postRaw = resampledata(postRaw,info.framerate,info.freqout,10^-5);
    postTime = resampledata(postTime,info.framerate,info.freqout,10^-5);
    for file = 2:numel(postFileName)
        [postRawFile, remainingData] = loadTiffRaw(postFileName{file},numLED,remainingData);
        postTimeFile = 0:size(postRawFile,4)-1;
        postTimeFile = postTimeFile./info.framerate;
        postRawFile = double(postRawFile);
        postRawFile = resampledata(postRawFile,info.framerate,info.freqout,10^-5);
        postTimeFile = resampledata(postTimeFile,info.framerate,info.freqout,10^-5);
        
        postTimeFile = postTimeFile + postTime(end) + 1/info.framerate;
        
        % concatenate
        postRaw = cat(4,postRaw,postRawFile);
        postTime = [postTime postTimeFile];
        clear postRawFile postTimeFile
    end
    fs = info.freqout;
    
    disp('Saving post-probe data');
    
    save(saveFilePost,'postRaw','postTime','fs','-v7.3');
    
    clear postRaw postTime
    
end
