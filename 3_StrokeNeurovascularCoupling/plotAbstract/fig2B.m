% plots activation response of bilateral roi

%% get data

saveFile = 'fig2DataEachMouseGSR.mat';
rootDir = 'D:\data\zachRosenthal\_stim';
weekChar = {'baseline','week1','week4','week8'};

if exist(saveFile)
    load(saveFile);
else
    plotData = nan(128,128,2,4,14);
    for week = 1:4
        dataDir = fullfile(rootDir,[weekChar{week} '_blockAvg_GSR']);
        fileList = dir(dataDir); fileList(1:2) = [];
        
        fileData = load(fullfile(dataDir,fileList(1).name));
        gcamp6corrBlock = nan([size(fileData.gcamp6corrBlock) numel(fileList)]);
        for fileInd = 1:numel(fileList)
            disp(['File #' num2str(fileInd)]);
            fileData = load(fullfile(dataDir,fileList(fileInd).name));
            % oxyBlock, deoxyBlock, gcamp6corrBlock
            gcamp6corrBlock(:,:,:,:,fileInd) = fileData.gcamp6corrBlock;
        end
        
        gcamp6corrBlock = permute(gcamp6corrBlock,[1 2 4 3 5]);
        % spatial x spatial x freq x time x mouse
        
        t = linspace(0,20,size(gcamp6corrBlock,4)+1); t(1) = [];
        tInd = (t >= 5 + 1/3 & t <= 10);
        
        gcamp6corrStimAvg = squeeze(nanmean(gcamp6corrBlock(:,:,:,tInd,:),4));
        gcamp6corrStimAvgNorm = gcamp6corrStimAvg;
        for mouse = 1:14
            for stimInd = 1:2
                x = squeeze(gcamp6corrStimAvg(:,:,stimInd,mouse));
                if stimInd == 1
                    subset = x(53:88,17:49);
                else
                    subset = x(53:88,80:110);
                end
                maxVal = max(subset(:));
                gcamp6corrStimAvgNorm(:,:,stimInd,mouse) = x./maxVal;
            end
        end
%         gcamp6corrStimAvg = nanmean(gcamp6corrStimAvg,4);
        
        plotData(:,:,:,week,:) = gcamp6corrStimAvg;
    end
    plotData = real(plotData);
    
    save(saveFile,'plotData');
end

% spatial x spatial x (L/R) x week x mouse

%% get L ROI activation data

lROIFile = 'D:\data\zachRosenthal\_stim\ROI R 75.mat';
load(lROIFile); % brings roiL75
lROI = roiR75;

lROIData = reshape(plotData,[size(plotData,1)*size(plotData,2) ...
    size(plotData,3) size(plotData,4) size(plotData,5)]);
lROIData = squeeze(nanmean(lROIData(lROI,1,:,:))); % 4 x 14

%% get R ROI activation data

rROIFile = 'D:\data\zachRosenthal\_stim\ROI L 75.mat';
load(rROIFile); % brings roiL75
rROI = roiL75;

rROIData = reshape(plotData,[size(plotData,1)*size(plotData,2) ...
    size(plotData,3) size(plotData,4) size(plotData,5)]);
rROIData = squeeze(nanmean(rROIData(rROI,2,:,:))); % 4 x 14

%% plot

legendStr = {'b','w1','w4','w8'};

f1 = figure('Position',[100 100 620 400]);
p = panel();
p.pack('h',{0.45 0.45 []});
p.margin = [5 10 0 10];
% p.margin = [0 0 0 10];
p(1).marginright = 25;

% Left
ax = p(1).select();
roiValueVect = lROIData(:);
weekValue = ones(4,14);
for i = 1:4
    weekValue(i,:) = i;
end
weekValue = weekValue(:);
legendStr = {'b','w1','w4','w8'};
H = notBoxPlot(roiValueVect,weekValue); hold on;
set(gca,'fontsize',16);
set([H(:).data],'MarkerSize',4,...
    'markerFaceColor',[1,1,1]*0.25,...
    'markerEdgeColor', 'none');
set([H(:).semPtch],...
    'FaceColor',[30 144 255]./256,...
    'EdgeColor','none');
set([H(:).sdPtch],...
    'FaceColor',[0 191 255]./256,...
    'EdgeColor','none');
set([H(:).mu],...
    'Color',[1,1,1]*0.75)
set(gca,'XTick',1:4,'XTickLabel',legendStr);
set(gca,'TickLength',[0.025 0]);
set(gca,'YAxisLocation','right');
xlim([0.5 4.5]);
ylim([-5E-4 3E-3]);

pairs = [1 2;1 3;1 4];
for pairInd = 1:size(pairs,1)
    cond1 = pairs(pairInd,1);
    cond2 = pairs(pairInd,2);
    
    test1 = lROIData(cond1,:);
    test2 = lROIData(cond2,:);
    [~,pVal] = ttest2(test1,test2);
    sigstarExtended({pairs(pairInd,:)},pVal,0,20);
end
set(gca,'YTick',linspace(-1E-3,3E-3,5));
th = title('R forepaw');
% axis(ax,'square');

% Right
ax = p(2).select();
roiValueVect = rROIData(:);
weekValue = ones(4,14);
for i = 1:4
    weekValue(i,:) = i;
end
weekValue = weekValue(:);
legendStr = {'b','w1','w4','w8'};
H = notBoxPlot(roiValueVect,weekValue); hold on;
set(gca,'fontsize',16);
set([H(:).data],'MarkerSize',4,...
    'markerFaceColor',[1,1,1]*0.25,...
    'markerEdgeColor', 'none');
set([H(:).semPtch],...
    'FaceColor',[194 24 7]./256,...
    'EdgeColor','none');
set([H(:).sdPtch],...
    'FaceColor',[255 36 0]./256,...
    'EdgeColor','none');
set([H(:).mu],...
    'Color',[1,1,1]*0.75)
set(gca,'XTick',1:4,'XTickLabel',legendStr);
set(gca,'TickLength',[0.025 0]);
set(gca,'YAxisLocation','right');
xlim([0.5 4.5]);
ylim([-5E-4 3E-3]);

pairs = [1 2;1 3;1 4];
for pairInd = 1:size(pairs,1)
    cond1 = pairs(pairInd,1);
    cond2 = pairs(pairInd,2);
    
    test1 = rROIData(cond1,:);
    test2 = rROIData(cond2,:);
    [~,pVal] = ttest2(test1,test2);
    sigstarExtended({pairs(pairInd,:)},pVal,0,20);
end
set(gca,'YTick',linspace(-1E-3,3E-3,5));
th = title('L forepaw');

% axis(ax,'square');