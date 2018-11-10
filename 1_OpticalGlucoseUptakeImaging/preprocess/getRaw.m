% saves raw data at lower frequency for me to work with
% usually runs saveHbAndFluor afterwards

%% params
databaseFile = 'D:\data\SalineProbe.xlsx';
% databaseFile = 'D:\data\NewProbeSample.xlsx';
excelInd = 10;  % rows from Excel Database
saveDir = 'D:\data';
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
    
    saveFilePre = fullfile(saveDirMouse,[recDate '-' mouse '-Raw-Pre.mat']);
    saveFilePost = fullfile(saveDirMouse,[recDate '-' mouse '-Raw-Post']);
    
    %% get Hb
    disp('  pre-probe raw');
    
    % find relevant files
%     [preFileName,postFileName] = getFileNames_Probe(rawdatadir,recDate,mouse); % this depends on which probe data you look at
    [preFileName,postFileName] = getFileNames_SalineProbe(databaseFile,recDate,mouse); % this depends on which probe data you look at
    
    info = mouseAnalysis.expSpecific.session2procInfo(sessionType); % getting meta info from session type
    
    fs = info.framerate;
    
    if numel(preFileName) > 1
        error('expected only one pre-probe file. Since this is a new case, change the following code accordingly.');
    else
        preRaw = mouseAnalysis.expSpecific.loadTiffRaw(preFileName{1},numLED);
        preTime = 0:size(preRaw,4)-1;
        preTime = preTime./fs;
        
        if info.baseline
            baseline = nanmean(nanmean(preRaw(:,:,:,1:40),4),3);
            preRawCorr = preRaw - repmat(baseline,1,1,size(preRaw,3),size(preRaw,4));
            preRawCorr(:,:,:,1:50) = [];
            preRaw = preRawCorr;
            preTime(1:50) = [];
        else
            preRaw(:,:,:,1) = []; % remove first frame
            preTime(1) = [];
        end
        
        preRaw = double(preRaw);
        
        
        
        save(saveFilePre,'preRaw','preTime','fs','-v7.3');
    end
    
    clear preRaw preTime
    
    disp('  post-probe raw');
    remainingData = [];
    postTimeEnd = 0;
    for file = 1:numel(postFileName)
        disp(['    File # ' num2str(file)]);
        [postRawFile, remainingData] = ...
            mouseAnalysis.expSpecific.loadTiffRaw(postFileName{file},numLED,remainingData);
        postTimeFile = 0:size(postRawFile,4)-1;
        postTimeFile = postTimeFile./info.framerate;
        
        if info.baseline
            if file==1
                baseline = nanmean(nanmean(postRawFile(:,:,:,1:40),4),3);
            end
            postRawCorr = postRawFile - repmat(baseline,1,1,size(postRawFile,3),size(postRawFile,4));
            
            if file == 1
                postRawCorr(:,:,:,1:50) = [];
                postTimeFile(1:50) = [];
            end
            postRawFile = postRawCorr;
            
        else
            if file==1
                postRawFile(:,:,:,1) = [];
                postTimeFile(1) = [];
            end
        end
        
        postRawFile = double(postRawFile);
        
        postTimeFile = postTimeFile + postTimeEnd + 1/fs;
        postTimeEnd = postTimeFile(end);
        save([saveFilePost '-' num2str(file) '.mat'],'postRawFile','postTimeFile','fs','-v7.3');
        
        clear postRawFile postTimeFile
    end
end
