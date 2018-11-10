%% find good folders
D = dir('D:\data\zachRosenthal'); D(1:2) = [];
goodFolder = false(numel(D),1);
for dirInd = 1:numel(D)
    if contains(D(dirInd).name,'lag_dot')
        goodFolder(dirInd) = true;
    end
end

D = D(goodFolder);

%% change name in each folder

for dirInd = 1:numel(D)
    currentFolder = fullfile(D(dirInd).folder,D(dirInd).name);
    fileList = dir(currentFolder);
    fileList(1:2) = [];
    
    for fileInd = 1:numel(fileList)
        if contains(fileList(fileInd).name,'lag_gs')
            % change file name
            oldName = fileList(fileInd).name;
            newName = ['lag_dot_' oldName(8:end)];
            oldDir = fullfile(currentFolder,oldName);
            
            % deal with spaces
            newName(strfind(newName,' ')) = '_';
            dos(['rename "' oldDir '" "' newName '"']); % (1)
        end
    end
end