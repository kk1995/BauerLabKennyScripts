recDate = '180813';
% mouse = 'NewProbeM3W5';
% mouse = 'NewProbeM4W5';
mouse = 'ProbeW3M1';
modification = 'GSR';
dataDir = ['D:\data\' recDate];
rawDir = fullfile(dataDir,[recDate '-' mouse '-fluorHbRemoved.mat']);
timeBounds = [0.5:59.5;1.5:60.5];

%% load

load(rawDir);
%% remove exponential decay

% postFluorDecayRmv = nan(size(postFluorHbRemoved));
% for y = 1:128
%     disp(num2str(y));
%     parfor x = 1:128
%         if xform_isbrain(y,x) > 0
% %             f = fit(postT',squeeze(postFluor(y,x,:)),'exp2');
% %             decayFit = f.a*exp(f.b*postT') + f.c*exp(f.d*postT');
% %             postFluorDecayRmv(y,x,:) = squeeze(postFluor(y,x,:)) - decayFit;
%             postFluorDecayRmv(y,x,:) = highpass(squeeze(postFluorHbRemoved(y,x,:)),0.05,1);
%         end
%     end
% end

preFluor = preFluorHbRemoved;
postFluor = postFluorHbRemoved;

%% convert to cell array (grouping)

preFluorCell = catByTime(preFluor,preT,timeBounds);
postFluorCell = catByTime(postFluor,postT,timeBounds);

%% get first 5 seconds of data

preFluorFirst5Seconds = [];
for i = 1:5
    preFluorFirst5Seconds = cat(4,preFluorFirst5Seconds,preFluorCell{i});
end
preFluorFirst5SecondsAvg = mean(preFluorFirst5Seconds,4);

postFluorFirst5Seconds = [];
for i = 1:5
    postFluorFirst5Seconds = cat(4,postFluorFirst5Seconds,postFluorCell{i});
end
postFluorFirst5SecondsAvg = mean(postFluorFirst5Seconds,4);

%% remove first 5 seconds avg from rest of data

preFluorAligned = cell(60,1);
postFluorAligned = cell(60,1);
for i = 1:60
    preFluorAligned{i} = preFluorCell{i} - repmat(preFluorFirst5SecondsAvg,[1 1 1 size(preFluorCell{i},4)]);
    postFluorAligned{i} = postFluorCell{i} - repmat(postFluorFirst5SecondsAvg,[1 1 1 size(postFluorCell{i},4)]);
end

%% get the data to plot

preFluorAvg = [];
for time = 1:60
    preFluorAvg = cat(3,preFluorAvg,mean(squeeze(preFluorAligned{time}),3));
end

postFluorAvg = [];
for time = 1:60
    postFluorAvg = cat(3,postFluorAvg,mean(squeeze(postFluorAligned{time}),3));
end


%% find the ROI
% TOI = 14:16;
TOI = 9:11;
InitROIY = 60:128;
InitROIX = 65:128;

ySize = size(postFluorAvg,1);
xSize = size(postFluorAvg,2);

maxHbO = squeeze(max(max(postFluorAvg(InitROIY,InitROIX,TOI),[],1),[],2));

thrHbO = maxHbO*0.5;

% thrInd = zeros(numel(InitROIY),numel(InitROIX),numel(thrHbO));
thrInd = zeros(ySize,xSize,numel(thrHbO));
for i = 1:numel(thrHbO)
%     thrInd(:,:,i) = postHbOAvg(:,:,TOI(i)) > thrHbO(i)*ones(128,128);
    thrInd(InitROIY,InitROIX,i) = postFluorAvg(InitROIY,InitROIX,TOI(i)) > thrHbO(i)*ones(numel(InitROIY),numel(InitROIX));
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

preFluorAvgROI = reshape(preFluorAvg,size(preFluorAvg,1)*size(preFluorAvg,2),size(preFluorAvg,3));

preFluorAvgROI = preFluorAvgROI(biggestGroupInd,:);

figure;
plot(mean(preFluorAvgROI,1)); hold off;
title('Avg activity pre-probe barrel');

postFluorAvgROI = reshape(postFluorAvg,size(postFluorAvg,1)*size(postFluorAvg,2),size(postFluorAvg,3));

postFluorAvgROI = postFluorAvgROI(biggestGroupInd,:);

figure;
plot(mean(postFluorAvgROI,1));
title('Avg activity post-probe barrel');