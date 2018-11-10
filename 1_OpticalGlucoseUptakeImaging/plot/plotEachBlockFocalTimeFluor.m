% date = '180713'; mouse = 'NewProbeM3W5';
% date = '180713'; mouse = 'NewProbeM4W5';
date = '180813'; mouse = 'ProbeW3M1';
modification = 'GSR';
dataDir = ['D:\data\' date];
vidDir = 'C:\Repositories\GitHub\BauerLab\figures';
timeBounds = [0.5:59.5; 1.5:60.5];

%% load

load(fullfile(dataDir,[date '-' mouse '-fluorHbRemoved.mat']));


%% get first 5 seconds of data

preFluorCell = catByTime(preFluorHbRemoved,preT,timeBounds);
preFluorFractionCell = catByTime(preFluorFraction,preT,timeBounds);
postFluorCell = catByTime(postFluorHbRemoved,postT,timeBounds);
postFluorFractionCell = catByTime(postFluorFraction,postT,timeBounds);

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


% preFluorFracFirst5SecondsAvg = [];
% for i = 1:5
%     preFluorFracFirst5SecondsAvg = cat(4,preFluorFracFirst5SecondsAvg,preFluorFractionCell{i});
% end
% preFluorFracFirst5SecondsAvg = mean(preFluorFracFirst5SecondsAvg,4);
% 
% postFluorFracFirst5Seconds = [];
% for i = 1:5
%     postFluorFracFirst5Seconds = cat(4,postFluorFracFirst5Seconds,postFluorFractionCell{i});
% end
% postFluorFracFirst5SecondsAvg = mean(postFluorFracFirst5Seconds,4);

%% remove first 5 seconds avg from rest of data

preAligned = cell(60,1);
postAligned = cell(60,1);
% preFracAligned = cell(60,1);
% postFracAligned = cell(60,1);
for i = 1:60
    preAligned{i} = preFluorCell{i} - repmat(preFluorFirst5SecondsAvg,[1 1 1 size(preFluorCell{i},4)]);
    postAligned{i} = postFluorCell{i} - repmat(postFluorFirst5SecondsAvg,[1 1 1 size(postFluorCell{i},4)]);
    
%     preFracAligned{i} = preFluorFractionCell{i} - repmat(preFluorFracFirst5SecondsAvg,[1 1 1 size(preFluorFractionCell{i},4)]);
%     postFracAligned{i} = postFluorFractionCell{i} - repmat(postFluorFracFirst5SecondsAvg,[1 1 1 size(postFluorFractionCell{i},4)]);
end

%% find the ROI
TOI = 9:11;

%% get the data to plot

postFocal = [];
for time = 1:numel(TOI)
    postFocal = cat(5,postFocal,postAligned{TOI(time)});
end
postFocal = mean(postFocal,5);

postFocalFrac = [];
for time = 1:numel(TOI)
    postFocalFrac = cat(5,postFocalFrac,postFluorFractionCell{TOI(time)});
end
postFocalFrac = mean(postFocalFrac,5);
%% plot

cMap = blueWhiteRed(100);
    
figure('Position',[50 100 1300 700]);
for i = 1:size(postFocal,4)
    subplot(5,10,i);
    imAlpha = xform_isbrain;
    imagesc(squeeze(sum(postFocal(:,:,1,i),3)),'AlphaData',imAlpha,[-0.2 0.2]);
    set(gca,'color',0.5*[1 1 1]);
    colormap(cMap);
    title(num2str(i));
    if i == 50
        axPos = get(gca,'position');
        colorbar;
        set(gca,'Position',axPos);
    end
end

figure('Position',[50 100 1300 700]);
for i = 1:size(postFocalFrac,4)
    subplot(5,10,i);
    imAlpha = xform_isbrain;
    imagesc(squeeze(sum(postFocalFrac(:,:,1,i),3)),'AlphaData',imAlpha,[0.95 1.05]);
    set(gca,'color',0.5*[1 1 1]);
    colormap(cMap);
    title(num2str(i));
    if i == 50
        axPos = get(gca,'position');
        colorbar;
        set(gca,'Position',axPos);
    end
end