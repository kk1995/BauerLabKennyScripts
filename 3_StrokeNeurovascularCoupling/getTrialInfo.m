function trialInfo = getTrialInfo(varargin)

if numel(varargin) > 0
    excelFile = varargin{1};
else
    excelFile = "D:\data\zach_gcamp_stroke_fc_trials.xlsx";
end

if numel(varargin) > 1
    rows = varargin{2};
else
    rows = 2:43;
end

[~,~,excelData] = xlsread(excelFile,1,['A' num2str(rows(1)) ':' xlscol(7) num2str(max(rows))]);

for i = 1:numel(rows)
    saveDir = string(excelData{i,5});
    trialInfo(i).hbFile = fullfile(saveDir,strcat(excelData{i,7},'-datahb.mat'));
    trialInfo(i).fluorFile = fullfile(saveDir,strcat(excelData{i,7},'-dataFluor.mat'));
    trialInfo(i).maskFile = fullfile(saveDir,strcat(excelData{i,6},'-LandmarksandMask.mat'));
    trialInfo(i).saveDir = saveDir;
end
end