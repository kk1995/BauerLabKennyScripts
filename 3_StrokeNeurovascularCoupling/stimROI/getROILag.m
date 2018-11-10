function getROILag(varargin)

if numel(varargin) < 1
    rows = 1:56;
else
    rows = varargin{1};
end

% loads in the roi and plots

maskFile = 'D:\data\zachRosenthal\_meta\mask.mat';
saveFile = 'D:\data\zachRosenthal\_stim\variable_R_ROI_Lag';
load(maskFile); % maskData

%% load stim files
% load('D:\data\zachRosenthal\_stim\ROI R 75.mat');
% stimLocL{1} = roiR75;
% load('D:\data\zachRosenthal\_stim\ROI R 75 vs baseline wk1 after stroke.mat');
% stimLocL{2} = roiR75ofbaselineatwk1;
% load('D:\data\zachRosenthal\_stim\ROI R 75 wk4 after stroke.mat');
% stimLocL{3} = roiR75wk4;
% load('D:\data\zachRosenthal\_stim\ROI R 75 wk8.mat');
% stimLocL{4} = roiR75wk8;

load('D:\data\zachRosenthal\_stim\ROI L 75.mat');
stimLoc{1} = roiL75;
stimLoc{2} = roiL75;
stimLoc{3} = roiL75;
stimLoc{4} = roiL75;

%% get data dir
excelFile = 'D:\data\Stroke Study 1 sorted.xlsx';
filename = 'dataGCaMP-fc';
fileList = xls2dir(excelFile,rows,filename);

saveFile = [saveFile '_' num2str(min(rows)) '-' num2str(max(rows)) '.mat'];

%% lag params

sR = 16.81;
% tLim = [1 0.5];
tLim = [2 1];
edgeLen = 3;
corrThr = 0.3;
validInd = cell(2,1);
for t = 1:2
    validInd{t} = -round(sR*tLim(t)):round(sR*tLim(t));
end
%% get data and get lag
fRange = [0.009 0.5; 0.5 5]; % 1st col is minimum frequency

lagTime = cell(4,1);
lagAmp = cell(4,1);

stimWeekList = [];

for fileInd = 1:numel(fileList)
    row = rows(fileInd);
    t0 = tic;
    disp(['file # ' num2str(fileInd)]);
    if row <= 14
        week = 1;
    elseif row <= 28
        week = 2;
    elseif row <= 42
        week = 3;
    else
        week = 4;
    end
    
    runList = fileList{fileInd};
    fileLagTime = [];
    fileLagAmp = [];
    
    stimWeek = week;
    stimWeekList = [stimWeekList stimWeek];
    
    for run = 1:numel(runList)
        disp(['  run # ' num2str(run)]);
        runFile = runList(run);
        load(runFile);
        data = [];
        %         data = cat(3,data,reshape(oxy,[128,128,1,size(oxy,3)]));
        %         data = cat(3,data,reshape(deoxy,[128,128,1,size(oxy,3)]));
        data = cat(3,data,reshape(oxy,[128,128,1,size(oxy,3)])+reshape(deoxy,[128,128,1,size(oxy,3)]));
        data = cat(3,data,reshape(gcamp6corr,[128,128,1,size(oxy,3)]));
        
        mask = xform_mask;
        roi = stimLoc{stimWeek};
        roi = find(roi);
        
        runLagTime = []; runLagAmp = [];
        for species = 1:size(data,3)
            [speciesLagDataTime, speciesLagDataAmp] = ...
                regionalLag(squeeze(data(:,:,species,:)),mask,fRange,sR,roi,...
                validInd,edgeLen,corrThr);
            runLagTime = cat(4,runLagTime,speciesLagDataTime);
            runLagAmp = cat(4,runLagAmp,speciesLagDataAmp);
        end
        fileLagTime = cat(5,fileLagTime,runLagTime);
        fileLagAmp = cat(5,fileLagAmp,runLagAmp);
    end
    fileLagTime = nanmean(fileLagTime,5);
    fileLagAmp = nanmean(fileLagAmp,5);
    lagTime{week} = cat(5,lagTime{week},fileLagTime);
    lagAmp{week} = cat(5,lagAmp{week},fileLagAmp);
    disp(['lag took ' num2str(toc(t0)) ' seconds.']);
end

metaData = {'spatial','spatial','freq','species','mouse'};
%% save

save(saveFile,'lagTime','lagAmp','metaData','rows','stimWeekList','stimLoc');

end