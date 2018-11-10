% gets the infarct and non-infarct region and collapses the spatial
% variable to just those two, then saves.
% usually run after running powerAnalysisStroke

dataDir = 'D:\data\zachRosenthal\';
contourFile = 'D:\data\zachRosenthal\contour.mat';
bloodMaskFile = 'D:\data\zachRosenthal\bloodMask.mat';
wlFile = 'D:\data\170126\170126-2528_baseline-LandmarksandMask.mat';
saveDir = 'D:\data\zachRosenthal\_summary';
saveFile = 'avgPower.mat';
speciesName = ["HbO","HbR","HbT","GCaMP"];

%%
load(wlFile); % xform_WL
load(contourFile); % contourMask
load(bloodMaskFile); % bloodMask
load('D:\data\atlas.mat');
mask = AtlasSeedsFilled>0;

%% get avg data

notContour = true(128);
notContour(contourMask) = false;
notContour(bloodMask) = false;
notContour(~mask) = false;

infarctData = cell(4,1);
nonInfarctData = cell(4,1);
for weekInd = 1:4
    avgDataWeek = [];
    if weekInd == 1
        week = 'baseline';
    elseif weekInd == 2
        week = 'week1';
    elseif weekInd == 3
        week = 'week4';
    else
        week = 'week8';
    end
    weekDir = [dataDir week '_power'];
    mouseFileList = dir(weekDir); mouseFileList(1:2) = [];
    
    for mouse = 1:numel(mouseFileList)
        disp(['  mouse # ' num2str(mouse)]);
        mouseFileDir = fullfile(weekDir,mouseFileList(mouse).name);
        load(mouseFileDir); % metaData, dataFreq, f
        
        fData = single(abs(dataFreq));
        avgDataWeek = cat(5,avgDataWeek,fData);
    end
    
    origSize = size(avgDataWeek);
    powerData = reshape(avgDataWeek,origSize(1)*origSize(2),origSize(3),origSize(4),[]);
    infarctDataT = powerData(contourMask,:,:,:);
    nonInfarctDataT = powerData(notContour,:,:,:);
    
    infarctData{weekInd} = squeeze(nanmean(infarctDataT,1));
    nonInfarctData{weekInd} = squeeze(nanmean(nonInfarctDataT,1));
end

save(fullfile(saveDir,saveFile),'infarctData','nonInfarctData','f');