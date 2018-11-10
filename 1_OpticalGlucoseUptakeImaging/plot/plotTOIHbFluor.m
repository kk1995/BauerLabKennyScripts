%% param

timeBounds = [0.5:59.5;1.5:60.5];
baselineInd = 1:5;
radius = 4;

date = '180713';
dataDir = ['D:\data\' date];
mouse = 'NewProbeM3W5';
% mouse = 'ProbeW3M1';

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

aboveThr = mean(stimResponse(InitROIY,InitROIX,toi),3) > thrHbO;
thrInd(InitROIY,InitROIX) = aboveThr;

% for i = 1:numel(thrHbO)
% %     thrInd(:,:,i) = postHbOAvg(:,:,TOI(i)) > thrHbO(i)*ones(128,128);
%     thrInd(InitROIY,InitROIX,i) = stimResponse(InitROIY,InitROIX,toi(i)) > thrHbO(i)*ones(numel(InitROIY),numel(InitROIX));
% end
% thrInd = mean(thrInd,3);
% thrInd = thrInd >= 2/3;

groupObjects = bwconncomp(thrInd);
groupSizes = nan(numel(groupObjects.PixelIdxList),1);
for i = 1:numel(groupObjects.PixelIdxList)
    groupSizes(i) = numel(groupObjects.PixelIdxList{i});
end

roiInd = groupObjects.PixelIdxList{max(groupSizes) == groupSizes};


%% plot
saveFile = fullfile(dataDir,[date '-' mouse '-AvgTimeCourseHb.mat']);

speciesNum =size(data,3);

if (exist(saveFile) == 0)
    imageData = nan(128,128,3,size(timeBounds,2));
    for species = 1:2
    disp(['Species # ' num2str(species)]);
        for y = 1:128
            if mod(y,16) == 1
                disp(['  ' num2str(y)]);
            end
            for x = 1:128
                if mask(y+(x-1)*128)
                    output = getAvgTimeCourse(data(y,x,species,:),time,timeBounds,baselineInd);
                    imageData(y,x,species,:) = output;
                end
            end
        end
    end
    disp('Species # 3');
    for y = 1:128
        if mod(y,16) == 1
            disp(['  ' num2str(y)]);
        end
        for x = 1:128
            if mask(y+(x-1)*128)
                output = getAvgTimeCourse(sum(data(y,x,1:2,:),3),time,timeBounds,baselineInd);
                imageData(y,x,3,:) = output;
            end
        end
    end
    save(saveFile,'imageData');
else
    load(saveFile);
end

figure('Position',[100 100 350 900]);
for species = 1:3
    subplot(3,1,species);
    alpha = double(mask);
    imagesc(squeeze(mean(imageData(:,:,species,toi),4)),'AlphaData',alpha,[-0.002 0.002]);
    colormap('jet');
    set(gca,'Visible','off');
%     if species == 3
%         sPos = get(gca,'position');
        colorbar;
%         set(gca,'Position',sPos);
%     end
end

plotScores = reshape(data,[size(data,1)*size(data,2) size(data,3) size(data,4)]);
plotScores = plotScores(roiInd,:,:);

figure('Position',[100 100 600 500]);
for species = 1:3
    if species == 3
        speciesInd = 1:2;
    else
        speciesInd = species;
    end
    output = getAvgTimeCourse(sum(plotScores(:,speciesInd,:),2),time,timeBounds,baselineInd);
    plot(output);
    hold on;
end
legend('HbO','HbR','HbT');

figure('Position',[100 100 600 500]);
x = zeros(128);
x(logical(mask)) = 1;
x(roiInd) = 2;
imagesc(x);

%% fluor
data = xform_fluor;
time = t_fluor;
mask = xform_isbrain;

%% plot
saveFile = fullfile(dataDir,[date '-' mouse '-AvgTimeCourseFluor.mat']);
toi = 9:11; % the time that we care about (seconds)

% normalize data
data = data./repmat(mean(data,4),[1 1 1 size(data,4)]);

if (exist(saveFile) == 0)
    imageData = nan(128,128,1,size(timeBounds,2));
    disp('Species # 1');
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
output = getAvgTimeCourse(plotScores(:,1,:),time,timeBounds,baselineInd);
plot(output);

% plot time course (not averaged)
figure('Position',[100 100 600 500]);
output = squeeze(mean(plotScores(:,1,:),1));
plot(time,output);
% 
% %% fluor detrended
% data = xform_fluorRatio;
% time = t_fluor;
% mask = xform_isbrain;

% %% plot
% saveFile = fullfile(dataDir,[date '-' mouse '-AvgTimeCourseFluorRatio.mat']);
% toi = 9:11; % the time that we care about (seconds)
% 
% if (exist(saveFile) == 0)
%     imageData = nan(128,128,1,size(timeBounds,2));
%     disp('Species # 1');
%     for y = 1:128
%         if mod(y,16) == 1
%             disp(['  ' num2str(y)]);
%         end
%         for x = 1:128
%             if mask(y+(x-1)*128)
%                 output = getAvgTimeCourse(data(y,x,1,:),time,timeBounds,baselineInd);
%                 imageData(y,x,1,:) = output;
%             end
%         end
%     end
%     save(saveFile,'imageData');
% else
%     load(saveFile);
% end
% 
% figure('Position',[100 100 600 500]);
% alpha = double(mask);
% imagesc(squeeze(mean(imageData(:,:,1,toi),4)),'AlphaData',alpha,[-0.02 0.02]);
% colormap('jet');
% set(gca,'Visible','off');
% colorbar;
% 
% plotScores = reshape(data,[size(data,1)*size(data,2) size(data,3) size(data,4)]);
% plotScores = plotScores(roiInd,:,:);
% 
% figure('Position',[100 100 600 500]);
% output = getAvgTimeCourse(plotScores(:,1,:),time,timeBounds,baselineInd);
% plot(output);
% 
% % plot time course (not averaged)
% figure('Position',[100 100 600 500]);
% output = squeeze(mean(plotScores(:,1,:),1));
% plot(time,output);