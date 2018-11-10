%% make the mouse avg data

% params
date = {'180713','180713','180716','180716','180716','180718'};
mouseList = {'NewProbeM3W5','NewProbeM4W5','NewProbeM1W6',...
    'NewProbeM2W6','NewProbeM3W6','NewProbeM1W5'};

% date = {'180813','180813','180813','180813'};
% mouseList = {'ProbeW3M1','ProbeW3M2','ProbeW3M3','ProbeW4M1'};
    
saveFolder = 'D:\data\glucoseProbe';
responseFileName = 'glucoseResponse.mat';
% responseFileName = 'noProbeResponse.mat';

avgResponseFileName = 'glucoseAvgResponse.mat';
% avgResponseFileName = 'noProbeAvgResponse.mat';

saveFilePrefix = 'glucose_';
% saveFilePrefix = 'noProbe_';

% check if the file already exists
if exist(fullfile(saveFolder,responseFileName),'file')
    disp('loading avg response');
    load(fullfile(saveFolder,responseFileName))
else % if file is not already made
    response = [];
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
        %   t_fluor
        
        xform_fluor = -logmean(xform_fluor);
        postFluorHbRemoved = postFluorHbRemoved - 1; % since it is centered at 1, fixing this.
        
        % get avg data in the mouse
        responseMouse = [];
        responseMouse = cat(3,responseMouse,xform_hb);
        responseMouse = cat(3,responseMouse,xform_fluor);
        responseMouse = cat(3,responseMouse,postFluorHbRemoved);
        time = t_fluor;
        response = cat(5,response,responseMouse);
    end
    % save avg response
    save(fullfile(saveFolder,responseFileName),'response','time','date','mouseList','-v7.3');
end

% output:
%   avgResponse = 5D matrix (128x128x3x60xmice)

%% get roi for barrel

load(fullfile(saveFolder,avgResponseFileName));

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
regionName = 'RS';

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

% roiInd = specificRoiInd;
roiInd = barrelRoiInd;
% saveFileName = regionName;
saveFileName = 'barrel';

% inputs:
%   avgResponse
%   roiInd

% get avg response across mice, and pixels vectorized
mouseAvgResponse = reshape(response,[128*128,size(response,3),...
    size(response,4),size(response,5)]);
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
fig = figure('Position',[100 100 500 400]);
% subplot(1,2,1);
plot(time,hbOResponse,'r'); hold on;
plot(time,hbRResponse,'b');
plot(time,hbTResponse,'m');
plot(time,gCaMPResponse,'g');
plot(time,gCaMPCorrResponse,'k'); hold off;
legend('HbO','HbR','HbT','GCaMP','GCaMPCorr');
xlabel('Time (s)');
ylabel('Ratio change');
title(saveFileName);

% % plot avg time course
% subplot(1,2,2);
% plot(time,gCaMPResponse,'g'); hold on;
% plot(time,gCaMPCorrResponse,'k'); hold off;
% legend('GCaMP','GCaMPCorr');
% xlabel('Time (s)');
% ylabel('Ratio change');
% title(saveFileName);

saveDir = 'D:\figures\glucoseUptakeImaging\avgTime';
savefig(fig,fullfile(saveDir,[saveFilePrefix saveFileName '_timeSeries']));