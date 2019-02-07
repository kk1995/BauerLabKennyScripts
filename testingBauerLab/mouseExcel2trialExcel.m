function mouseExcel2trialExcel(excelFile,saveFile,varargin)
%mouseExcel2trialExcel 
%   Inputs:
%       excelFile = excel file that is being read.
%       saveFile = excel file that is being written.
%       info (optional) = parameters that are added to excel file
%           fs = sampling rate (default = 16.8)
%           procFs = sampling rate of processing data (default = 16.8)
%           sessionType = are you measuring 6-nbdg, gcamp6f, or just
%           hemodynamics (none)? (default = 'none')

if numel(varargin) > 0
    info = varargin{1};
else
    info.fs = 16.8;
    info.procFs = 16.8;
    info.sessionType = 'none';
end

% find the columns that are for date of recording, and mouse name
[~, ~, colLabels]=xlsread(excelFile,1, '1:1');
[~, ~, rowLabels]=xlsread(excelFile,1, 'A:A');

lastInd = 1;
for ind = 1:numel(colLabels)
    if ~isnan(colLabels{ind})
        lastInd = ind;
    end
end
colLabels = colLabels(1:lastInd);

lastInd = 1;
for ind = 1:numel(rowLabels)
    if ~isnan(rowLabels{ind})
        lastInd = ind;
    end
end
rowLabels = rowLabels(1:lastInd);
rowNum = numel(rowLabels);

rawDataLocCol = [];
for ind = 1:numel(colLabels)
    if contains(lower(colLabels{ind}),'raw data')
        rawDataLocCol = ind;
        break;
    end
end

recDatesCol = [];
for ind = 1:numel(colLabels)
    if contains(lower(colLabels{ind}),'date')
        recDatesCol = ind;
        break;
    end
end

mouseNamesCol = [];
for ind = 1:numel(colLabels)
    if contains(lower(colLabels{ind}),'mouse')
        mouseNamesCol = ind;
        break;
    end
end

systemCol = [];
for ind = 1:numel(colLabels)
    if contains(lower(colLabels{ind}),'system')
        systemCol = ind;
        break;
    end
end

sessionCol = [];
for ind = 1:numel(colLabels)
    if contains(lower(colLabels{ind}),'session')
        sessionCol = ind;
        break;
    end
end

goodRunsCol = [];
for ind = 1:numel(colLabels)
    if contains(lower(colLabels{ind}),'good runs')
        goodRunsCol = ind;
        break;
    end
end

saveLocCol = [];
for ind = 1:numel(colLabels)
    if contains(lower(colLabels{ind}),'save')
        saveLocCol = ind;
        break;
    end
end

fileNames = [];
systemsUsed = [];
sessionsUsed = [];
rawDataLocs = [];
recDates = [];
mouseNames = [];
saveFileLocs = [];
saveMaskFilePrefixes = [];
saveDataFilePrefixes = [];
fs = [];
procFs = [];

disp('reading from excel file that lists a mouse in each row');

[~,~,raw] = xlsread(excelFile,1,['A1:' xlscol(numel(colLabels)) num2str(rowNum)]);

for row = 2:rowNum
    recDate = raw(row,recDatesCol);
    mouseName = raw(row,mouseNamesCol);
    system = raw(row,systemCol);
    session = raw(row,sessionCol);
    saveLoc = raw(row,saveLocCol);
    goodRuns = raw(row,goodRunsCol);
    rawDataLoc = raw(row,rawDataLocCol);
    
    recDate = string(recDate{1});
    mouseName = string(mouseName{1});
    rawDataLoc = string(fullfile(rawDataLoc{1},recDate));
    system = string(system{1});
    session = char(session{1}); session = string(session(3:end-2));
    saveFileLoc = string(fullfile(saveLoc{1},recDate));
    saveFilePrefix = strcat(recDate,"-",mouseName,"-",session);
    goodRuns = textscan ( goodRuns{1}, '%f', 'delimiter', ',' ); goodRuns = goodRuns{1}';
    
    for run = goodRuns
        fileName = string(fullfile(strcat(recDate,"-",mouseName,"-",session,num2str(run),".tif")));
        
        rawDataLocs = [rawDataLocs rawDataLoc];
        recDates = [recDates recDate];
        mouseNames = [mouseNames mouseName];
        fileNames = [fileNames fileName];
        saveFileLocs = [saveFileLocs saveFileLoc];
        saveMaskFilePrefixes = [saveMaskFilePrefixes saveFilePrefix];
        saveDataFilePrefixes = [saveDataFilePrefixes strcat(saveFilePrefix,num2str(run))];
        systemsUsed = [systemsUsed system];
        sessionsUsed = [sessionsUsed string(info.sessionType)];
        fs = [fs; info.fs];
        procFs = [procFs; info.procFs];
    end
end

%% write to excel file

disp('writing to excel file that lists a trial in each row');

% write the first row
xlswrite(saveFile,{'Date','Mouse','Raw Data Loc','Raw File name',...
    'Save File Loc','Save Mask File Prefix', 'Save Data File Prefix',...
    'System','Session Type','Sampling Rate','Processing sampling rate'},1,'A1');

A = [];
for trial = 1:numel(fileNames)
    
    if mod(trial+1,ceil((numel(fileNames)+1)/8)) == 0
        disp(['trial # ' num2str(trial+1) '/' num2str(numel(fileNames)+1)]);
    end
    A = [A; {str2double(recDates(trial)), char(mouseNames(trial)), ...
        char(rawDataLocs(trial)), char(fileNames(trial)), ...
        char(saveFileLocs(trial)), char(saveMaskFilePrefixes(trial)), ...
        char(saveDataFilePrefixes(trial)), char(systemsUsed(trial)), ...
        char(sessionsUsed(trial)), fs(trial), procFs(trial)}];
end
xlswrite(saveFile,A,1,'A2');


end

