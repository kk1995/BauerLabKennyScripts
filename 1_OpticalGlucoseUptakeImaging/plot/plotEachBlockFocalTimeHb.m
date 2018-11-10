recDate = '180813';
% mouse = 'NewProbeM3W5';
% mouse = 'NewProbeM4W5';
mouse = 'ProbeW3M1';
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

%% find the ROI
TOI = 9:11;

%% get the data to plot

postHbFocal = [];
for time = 1:numel(TOI)
    postHbFocal = cat(5,postHbFocal,postHbAligned{TOI(time)});
end
postHbFocal = mean(postHbFocal,5);

%% plot

cMap = blueWhiteRed(100);
for condition = 1:3
    
    if condition == 3
        species = 1:2;
    else
        species = condition;
    end
    
    figure('Position',[50 100 1300 700]);
    for i = 1:size(postHbFocal,4)
        subplot(5,10,i);
        imAlpha = xform_isbrain;
        imagesc(squeeze(sum(postHbFocal(:,:,species,i),3)),'AlphaData',imAlpha,[-0.005 0.005]);
        set(gca,'color',0.5*[1 1 1]);
        colormap(cMap);
        title(num2str(i));
        if i == 50
            axPos = get(gca,'position');
            colorbar;
            set(gca,'Position',axPos);
        end
    end
end