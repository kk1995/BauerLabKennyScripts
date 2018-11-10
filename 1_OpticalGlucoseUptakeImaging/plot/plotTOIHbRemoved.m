%% param

timeBounds = [0.5:59.5;1.5:60.5];
baselineInd = 1:5;
radius = 4;

date = '180713';
dataDir = ['D:\data\' date];
mouse = 'NewProbeM3W5';
% mouse = 'ProbeW4M1';

%% load

load(fullfile(dataDir,[date '-' mouse '-LandmarksandMask.mat']));
load(fullfile(dataDir,[date '-' mouse '-Post-GSR-Resampled.mat']));

%% hb
data = xform_hb;
dataCell = xform_hbCell;
time = t_hb;
mask = xform_isbrain;

%% find roi
stimResponse = [];
for t = 1:60
    secondResponse = sum(dataCell{t},3);
    stimResponse = cat(3,stimResponse,secondResponse);
end
stimResponse = abs(stimResponse);

toi = 9:11;
% InitROIY = 60:128;
% InitROIX = 65:128;

InitROIY = 60:110;
InitROIX = 80:128;


ySize = size(data,1);
xSize = size(data,2);

maxHbT = squeeze(max(max(stimResponse(InitROIY,InitROIX,toi),[],1),[],2));
maxHbT = mean(maxHbT);
thrHbO = maxHbT*0.5;

% thrInd = zeros(numel(InitROIY),numel(InitROIX),numel(thrHbO));
thrInd = zeros(ySize,xSize);

thrInd(InitROIY,InitROIX) = mean(stimResponse(InitROIY,InitROIX,toi),3) > thrHbO;

groupObjects = bwconncomp(thrInd);
groupSizes = nan(numel(groupObjects.PixelIdxList),1);
for i = 1:numel(groupObjects.PixelIdxList)
    groupSizes(i) = numel(groupObjects.PixelIdxList{i});
end

roiInd = groupObjects.PixelIdxList{max(groupSizes) == groupSizes};

figure('Position',[100 100 600 500]);
x = zeros(128);
x(logical(mask)) = 1;
x(roiInd) = 2;
imagesc(x);

%% load

load(fullfile(dataDir,[date '-' mouse '-fluorHbRemoved.mat']));
load(fullfile(dataDir,[date '-' mouse '-LandmarksandMask.mat']));

%% fluor hb removed
data = postFluorHbRemoved;
time = postT;
mask = xform_isbrain;

%% plot

saveFile = fullfile(dataDir,[date '-' mouse '-AvgTimeCourseFluorHbRemoved.mat']);

speciesNum =size(data,3);

if (exist(saveFile) == 0)
    imageData = nan(128,128,1,size(timeBounds,2));
    for y = 1:128
        if mod(y,16) == 1
            disp(['  ' num2str(y)]);
        end
        for x = 1:128
            if mask(y+(x-1)*128)
                output = getAvgTimeCourse(data(y,x,1,:),time,timeBounds,baselineInd);
                imageData(y,x,1,:) = output;
            end
        end
    end
    save(saveFile,'imageData');
else
    load(saveFile);
end

figure('Position',[100 100 600 500]);
alpha = double(mask);
imagesc(squeeze(mean(imageData(:,:,1,toi),4)),'AlphaData',alpha,[-0.02 0.02]);
colormap('jet');
set(gca,'Visible','off');
colorbar;

plotScores = reshape(data,[size(data,1)*size(data,2) size(data,3) size(data,4)]);
plotScores = plotScores(roiInd,:,:);

figure('Position',[100 100 600 500]);
output = getAvgTimeCourse(sum(plotScores(:,1,:),2),time,timeBounds,baselineInd);
plot(output);

% plot time course (not averaged)
figure('Position',[100 100 600 500]);
output = squeeze(mean(plotScores(:,1,:),1));
plot(time,output);