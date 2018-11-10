% loads in the roi and plots

maskFile = 'D:\data\zachRosenthal\_meta\mask.mat';
% saveFile = 'D:\data\zachRosenthal\_stim\baseline_ROI_FC_GSR.mat';
% saveFile = 'D:\data\zachRosenthal\_stim\baseline_R_ROI_FC_GSR.mat';
% saveFile = 'D:\data\zachRosenthal\_stim\week8_ROI_FC_GSR.mat';
saveFile = 'D:\data\zachRosenthal\_stim\variable_ROI_FC_GSR.mat';

% stimWeek = 1; % which time ind to use for stimulation roi

load(maskFile); % maskData

%% load stim files
load('D:\data\zachRosenthal\_stim\ROI R 75.mat');
stimLoc{1} = roiR75;
load('D:\data\zachRosenthal\_stim\ROI R 75 vs baseline wk1 after stroke.mat');
stimLoc{2} = roiR75ofbaselineatwk1;
load('D:\data\zachRosenthal\_stim\ROI R 75 wk4 after stroke.mat');
stimLoc{3} = roiR75wk4;
load('D:\data\zachRosenthal\_stim\ROI R 75 wk8.mat');
stimLoc{4} = roiR75wk8;

% load('D:\data\zachRosenthal\_stim\ROI L 75.mat');
% stimLoc{1} = roiL75;
% stimLoc{2} = roiL75;
% stimLoc{3} = roiL75;
% stimLoc{4} = roiL75;

%% get data dir
excelFile = 'D:\data\Stroke Study 1 sorted.xlsx';
rows = 1:56;
filename = 'dataGCaMP-fc';
fileList = mouseAnalysis.expSpecific.xls2dir(excelFile,rows,filename);

%% get data and get FC
fRange = [0.009 0.5; 0.5 5]; % 1st col is minimum frequency
sR = 16.81;

fcData = cell(4,1);
stimROI = cell(numel(fileList),1);
for file = 1:numel(fileList)
    t0 = tic;
    disp(['file # ' num2str(file)]);
    if file <= 14
        week = 1;
    elseif file <= 28
        week = 2;
    elseif file <= 42
        week = 3;
    else
        week = 4;
    end
    
    runList = fileList{file};
    fileFCData = [];
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
        
        data = mouseAnalysis.preprocess.gsr(data,mask);
        
        stimWeek = week;
        roi = stimLoc{stimWeek};
        roi = find(roi);
        stimROI{file} = roi;
        
        runFCData = [];
        for species = 1:size(data,3)
            runFCData = cat(4,runFCData,mouseAnalysis.conn.regionalFC(squeeze(data(:,:,species,:)),fRange,sR,roi));
            % spatial x spatial x freq x species
        end
        fileFCData = cat(5,fileFCData,runFCData);
    end
    fileFCData = nanmean(fileFCData,5);
    fcData{week} = cat(5,fcData{week},fileFCData);
    disp(['fc took ' num2str(toc(t0)) ' seconds.']);
end

metaData = {'spatial','spatial','freq','species','mouse'};
%% save

save(saveFile,'fcData','metaData');