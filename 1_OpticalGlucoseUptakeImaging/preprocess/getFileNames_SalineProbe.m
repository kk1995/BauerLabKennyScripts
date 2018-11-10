function [preFileName,postFileName] = getFileNames_SalineProbe(databaseFile,recDate,mouse)
%getFileNames_Probe Get file names for probe data
%   Detailed explanation goes here
    % read from database
    [~, ~, raw]=xlsread(databaseFile,1);
    
    % find the correct row
    correctDate = false(size(raw,1),1);
    correctMouse = correctDate;
    for row = 1:size(raw,1)
        if strcmp(recDate,num2str(raw{row,1}))
            correctDate(row) = true;
        end
        if strcmp(mouse,raw{row,2})
            correctMouse(row) = true;
        end
    end
    fileRow = correctDate & correctMouse;
    raw = raw(fileRow,:);
    % get relevant values from database
    rawdatadir=raw{3};
    saveloc=raw{4};
    system=raw{5};
    sessionType = eval(raw{6});
    preSuffix = raw{11}; % separated by commas
    postSuffix = raw{12}; % separated by commas
    
    rawSubDir = fullfile(rawdatadir,recDate);
    filePreFix = [recDate '-' mouse '-'];
    
    % get the multiple file suffix (remove the commas and separate)
    preSuffixComma = strfind(preSuffix,',');
    postSuffixComma = strfind(postSuffix,',');
    preFileNum = numel(preSuffixComma)+1;
    postFileNum = numel(postSuffixComma)+1;
    
    preSuffixCell = cell(preFileNum,1);
    for file = 1:preFileNum
        if file==1
            startInd = 1;
        else
            startInd = preSuffixComma(file-1)+1;
        end
        if file==preFileNum
            endInd = numel(preSuffix);
        else
            endInd = preSuffixComma(file)-1;
        end
        preSuffixCell{file} = preSuffix(startInd:endInd);
    end
    
    postSuffixCell = cell(postFileNum,1);
    for file = 1:postFileNum
        if file==1
            startInd = 1;
        else
            startInd = postSuffixComma(file-1)+1;
        end
        if file==postFileNum
            endInd = numel(postSuffix);
        else
            endInd = postSuffixComma(file)-1;
        end
        postSuffixCell{file} = postSuffix(startInd:endInd);
    end
    
    % get the actual files
    preFileName = cell(preFileNum,1);
    for file = 1:preFileNum
        preFileName{file} = fullfile(rawSubDir,[filePreFix preSuffixCell{file} '.tif']);
    end
    postFileName = cell(postFileNum,1);
    for file = 1:postFileNum
        postFileName{file} = fullfile(rawSubDir,[filePreFix postSuffixCell{file} '.tif']);
    end
end

