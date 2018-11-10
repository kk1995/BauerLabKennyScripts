%% make the mouse avg data

% params
% date = {'180713','180713','180716','180716','180716','180718'};
% mouseList = {'NewProbeM3W5','NewProbeM4W5','NewProbeM1W6',...
%     'NewProbeM2W6','NewProbeM3W6','NewProbeM1W5'};

date = {'180813','180813','180813','180813'};
mouseList = {'ProbeW3M1','ProbeW3M2','ProbeW3M3','ProbeW4M1'};
    
saveFolder = 'D:\data\glucoseProbe';
% responseFileName = 'glucoseAvgResponse.mat';
responseFileName = 'noProbeAvgResponse.mat';

% saveFilePrefix = 'glucose_';
saveFilePrefix = 'noProbe_';

% check if the file already exists
if exist(fullfile(saveFolder,avgResponseFileName),'file')
    disp('loading avg response');
    load(fullfile(saveFolder,avgResponseFileName))
else % if file is not already made
    avgResponse = [];
    for mouseInd = 1:numel(mouseList)
        %% load
        mouseDate = date{mouseInd};
        mouseID = mouseList{mouseInd};
        dataDir = ['D:\data\' mouseDate];
        load(fullfile(dataDir,[mouseDate '-' mouseID '-LandmarksandMask.mat']));
        load(fullfile(dataDir,[mouseDate '-' mouseID '-Post-GSR-Resampled.mat']));
        load(fullfile(dataDir,[mouseDate '-' mouseID '-fluorHbRemoved.mat']),...
            'postFluorHbRemoved');
        
        % outputs:
        %   xform_isbrain = 128x128 single
        %   xform_hb = 4D (128x128x2xtime)
        %   xform_hbCell = 60x1 cell (each cell = 128x128x2)
        %   xform_fluor = 4D (128x128x1xtime)
        %   xform_fluorCell = 60x1 cell (each cell = 128x128)
        %   postFluorHbRemoved = 4D
        
        % xform_fluorCell seems to be weird. So let's make it ourselves.
        timeBounds = [0.5:59.5;1.5:60.5];
        xform_fluorCell = catByTime(xform_fluor,t_fluor,timeBounds);
        xform_fluorCorrCell = catByTime(postFluorHbRemoved,t_fluor,timeBounds);
        for i = 1:numel(xform_fluorCell)
            xform_fluorCell{i} = mean(xform_fluorCell{i},4);
            xform_fluorCorrCell{i} = mean(xform_fluorCorrCell{i},4);
        end
        
        % make xform_fluorCell be percentage change
        meanFluor = [];
        for i = 1:5
            meanFluor = cat(3,meanFluor,xform_fluorCell{i});
        end
        meanFluor = mean(meanFluor,3);
        for i = 1:60
            xform_fluorCell{i} = xform_fluorCell{i}./meanFluor - 1;
        end
        
        % get avg data in the mouse
        stimResponse = [];
        for t = 1:60
            secondResponse = cat(3,xform_hbCell{t},xform_fluorCell{t},xform_fluorCorrCell{t});
            stimResponse = cat(4,stimResponse,secondResponse);
        end
        baseline = mean(stimResponse(:,:,:,1:5),4);
        stimResponse = stimResponse - repmat(baseline,[1 1 1 60]);
        
        avgResponse = cat(5,avgResponse,stimResponse);
    end
    % save avg response
    save(fullfile(saveFolder,avgResponseFileName),'avgResponse','date','mouseList');
end

% output:
%   avgResponse = 5D matrix (128x128x3x60xmice)

%% get roi for barrel
toi = 9:11;

InitROIY = 60:110;
InitROIX = 80:128;

ySize = size(avgResponse,1);
xSize = size(avgResponse,2);

% make a 2D matrix of stimulus response that will be used for thresholding
stimResponse = mean(avgResponse,5);
stimResponse = squeeze(mean(sum(stimResponse(:,:,1:2,toi),3),4));

maxHbT = squeeze(max(max(stimResponse(InitROIY,InitROIX),[],1),[],2));
thrHbT = maxHbT*0.5;

thrInd = zeros(ySize,xSize);

aboveThr = stimResponse(InitROIY,InitROIX) > thrHbT;
thrInd(InitROIY,InitROIX) = aboveThr;

groupObjects = bwconncomp(thrInd);
groupSizes = nan(numel(groupObjects.PixelIdxList),1);
for i = 1:numel(groupObjects.PixelIdxList)
    groupSizes(i) = numel(groupObjects.PixelIdxList{i});
end

barrelRoiInd = groupObjects.PixelIdxList{max(groupSizes) == groupSizes};

% output:
%   barrelRoiInd = vector of indices that correspond to location of pixels
%   that are in the roi

%% get roi for a region

atlasFileDir = 'D:\data\atlas.mat';
regionName = 'V1';

load(atlasFileDir,'AtlasSeeds','seednames');

% find seeds that are retrosplenial
specificSeed = false(numel(seednames),1);
for cellInd = 1:numel(seednames)
    if contains(seednames{cellInd},regionName)
        specificSeed(cellInd) = true;
    end
end
specificSeed = find(specificSeed);

% find the indices that are in that seed
specificRegion = false(128,128);
for seed = 1:numel(specificSeed)
    specificRegion(AtlasSeeds == specificSeed(seed)) = true;
end
specificRoiInd = find(specificRegion);

% output:
%   visualRoiInd = vector of indices that correspond to location of pixels
%   that are in the roi

%% get avg time course and plot

roiInd = specificRoiInd;
% roiInd = barrelRoiInd;
saveFileName = regionName;
% saveFileName = 'barrel';

% inputs:
%   avgResponse
%   roiInd

% get avg response across mice, and pixels vectorized
mouseAvgResponse = reshape(avgResponse,[128*128,size(avgResponse,3),...
    size(avgResponse,4),size(avgResponse,5)]);
mouseAvgResponse = mean(mouseAvgResponse,4);

% get avg response only in the roi
roiMouseAvgResponse = squeeze(nanmean(mouseAvgResponse(roiInd,:,:),1));

% get hb species and gcamp
hbOResponse = roiMouseAvgResponse(1,:);
hbRResponse = roiMouseAvgResponse(2,:);
hbTResponse = sum(roiMouseAvgResponse(1:2,:),1);
gCaMPResponse = roiMouseAvgResponse(3,:);
gCaMPCorrResponse = roiMouseAvgResponse(4,:);

% plot avg time course
fig = figure('Position',[100 100 1200 400]);
subplot(1,2,1);
time = 1:60;
plot(time,hbOResponse,'r'); hold on;
plot(time,hbRResponse,'b');
plot(time,hbTResponse,'m');
plot(time,gCaMPResponse,'g');
plot(time,gCaMPCorrResponse,'k'); hold off;
legend('HbO','HbR','HbT','GCaMP','GCaMPCorr');
xlabel('Time (s)');
ylabel('Ratio change');
title(saveFileName);

% plot avg time course
subplot(1,2,2);
time = 1:60;
plot(time,gCaMPResponse,'g'); hold on;
plot(time,gCaMPCorrResponse,'k'); hold off;
legend('GCaMP','GCaMPCorr');
xlabel('Time (s)');
ylabel('Ratio change');
title(saveFileName);

saveDir = 'D:\figures\glucoseUptakeImaging\avgTime';
savefig(fig,fullfile(saveDir,[saveFilePrefix saveFileName]));