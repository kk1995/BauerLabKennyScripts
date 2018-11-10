recDate = '180713';
mouse = 'NewProbeM3W5';
% mouse = 'NewProbeM4W5';
% mouse = 'NewProbeM1W6';
% mouse = 'ProbeW4M1';
modification = 'GSR';
dataDir = ['D:\data\' recDate];
vidDir = 'C:\Repositories\GitHub\BauerLab\figures';

%% load

load(fullfile(dataDir,[recDate '-' mouse '-Pre-' modification '.mat']));

preHb = datahbCell;

load(fullfile(dataDir,[recDate '-' mouse '-Post-' modification '.mat']));

postHb = datahbCell;

%% get first 5 seconds of data

preHbFirst5Seconds = [];
for i = 1:5
    preHbFirst5Seconds = cat(4,preHbFirst5Seconds,preHb{i});
end
preHbFirst5SecondsAvg = mean(preHbFirst5Seconds,4);

postHbFirst5Seconds = [];
for i = 1:5
    postHbFirst5Seconds = cat(4,postHbFirst5Seconds,postHb{i});
end
postHbFirst5SecondsAvg = mean(postHbFirst5Seconds,4);

%% remove first 5 seconds avg from rest of data

preHbAligned = cell(60,1);
postHbAligned = cell(60,1);
for i = 1:60
    preHbAligned{i} = preHb{i} - repmat(preHbFirst5SecondsAvg,[1 1 1 size(preHb{i},4)]);
    postHbAligned{i} = postHb{i} - repmat(postHbFirst5SecondsAvg,[1 1 1 size(postHb{i},4)]);
end

%% get the data to plot

preHbOAvg = [];
preHbRAvg = [];
preHbTAvg = [];
for time = 1:60
    preHbOAvg = cat(3,preHbOAvg,mean(squeeze(preHbAligned{time}(:,:,1,:)),3));
    preHbRAvg = cat(3,preHbRAvg,mean(squeeze(preHbAligned{time}(:,:,2,:)),3));
    preHbTAvg = cat(3,preHbTAvg,mean(squeeze(sum(preHbAligned{time},3)),3));
end

postHbOAvg = [];
postHbRAvg = [];
postHbTAvg = [];
for time = 1:60
    postHbOAvg = cat(3,postHbOAvg,mean(squeeze(postHbAligned{time}(:,:,1,:)),3));
    postHbRAvg = cat(3,postHbRAvg,mean(squeeze(postHbAligned{time}(:,:,2,:)),3));
    postHbTAvg = cat(3,postHbTAvg,mean(squeeze(sum(postHbAligned{time},3)),3));
end


%% find the ROI
% TOI = 14:16;
TOI = 9:11;
InitROIY = 60:128;
InitROIX = 75:128;

ySize = size(postHbOAvg,1);
xSize = size(postHbOAvg,2);

maxHbO = squeeze(max(max(postHbOAvg(InitROIY,InitROIX,TOI),[],1),[],2));

thrHbO = maxHbO*0.5;

% thrInd = zeros(numel(InitROIY),numel(InitROIX),numel(thrHbO));
thrInd = zeros(ySize,xSize,numel(thrHbO));
for i = 1:numel(thrHbO)
%     thrInd(:,:,i) = postHbOAvg(:,:,TOI(i)) > thrHbO(i)*ones(128,128);
    thrInd(InitROIY,InitROIX,i) = postHbOAvg(InitROIY,InitROIX,TOI(i)) > thrHbO(i)*ones(numel(InitROIY),numel(InitROIX));
end
thrInd = mean(thrInd,3);
thrInd = thrInd == 1;

groupObjects = bwconncomp(thrInd);
groupSizes = nan(numel(groupObjects.PixelIdxList),1);
for i = 1:numel(groupObjects.PixelIdxList)
    groupSizes(i) = numel(groupObjects.PixelIdxList{i});
end

biggestGroupInd = groupObjects.PixelIdxList{max(groupSizes) == groupSizes};

%% plot

preHbOAvgROI = reshape(preHbOAvg,size(preHbOAvg,1)*size(preHbOAvg,2),size(preHbOAvg,3));
preHbRAvgROI = reshape(preHbRAvg,size(preHbRAvg,1)*size(preHbRAvg,2),size(preHbRAvg,3));
preHbTAvgROI = reshape(preHbTAvg,size(preHbTAvg,1)*size(preHbTAvg,2),size(preHbTAvg,3));

preHbOAvgROI = preHbOAvgROI(biggestGroupInd,:);
preHbRAvgROI = preHbRAvgROI(biggestGroupInd,:);
preHbTAvgROI = preHbTAvgROI(biggestGroupInd,:);

figure;
plot(mean(preHbOAvgROI,1)); hold on; plot(mean(preHbRAvgROI,1)); plot(mean(preHbTAvgROI,1)); hold off;
legend('HbO','HbR','HbT');
title('Avg activity pre-probe barrel');

postHbOAvgROI = reshape(postHbOAvg,size(postHbOAvg,1)*size(postHbOAvg,2),size(postHbOAvg,3));
postHbRAvgROI = reshape(postHbRAvg,size(postHbRAvg,1)*size(postHbRAvg,2),size(postHbRAvg,3));
postHbTAvgROI = reshape(postHbTAvg,size(postHbTAvg,1)*size(postHbTAvg,2),size(postHbTAvg,3));

postHbOAvgROI = postHbOAvgROI(biggestGroupInd,:);
postHbRAvgROI = postHbRAvgROI(biggestGroupInd,:);
postHbTAvgROI = postHbTAvgROI(biggestGroupInd,:);

figure;
plot(mean(postHbOAvgROI,1)); hold on; plot(mean(postHbRAvgROI,1)); plot(mean(postHbTAvgROI,1)); hold off;
legend('HbO','HbR','HbT');
title('Avg activity post-probe barrel');

figure;
ROILoc = zeros(128,128);
ROILoc(logical(xform_isbrain(:))) = 1;
ROILoc(biggestGroupInd) = 2;
imagesc(ROILoc);