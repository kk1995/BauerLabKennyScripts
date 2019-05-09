% plots FC relative to region

excelFile = fullfile('D:\data','zach_gcamp_stroke_fc_trials.xlsx');
rowList{1} = 2:43;
rowList{2} = 44:83;
rowList{3} = 84:125;
rowList{4} = 126:167;

sR = 16.8;
saveFolder = "L:\ProcessedData\3_NeurovascularCoupling";

%%

% fMin = 0.01;
% fMax = 0.08;

fMin = 0.5;
fMax = 4;

fMinStr = num2str(fMin);
fMinStr(strfind(fMinStr,'.')) = 'p';
fMaxStr = num2str(fMax);
fMaxStr(strfind(fMaxStr,'.')) = 'p';

%%

hbFC = cell(4,1);
fluorFC = cell(4,1);
mask = cell(4,1);

for groupInd = 1:4
    
    % make data file list
    dataFileList = [];
    for row = rowList{groupInd}
        [~, ~, raw]=xlsread(excelFile,1, ['A',num2str(row),':K',num2str(row)]);
        mouseName = raw{2};
        dataDir = raw{5};
        dataFile = [mouseName '-' fMinStr '-' fMaxStr '-roi-fc.mat'];
        dataFileList = [dataFileList string(fullfile(dataDir,dataFile))];
    end
    dataFileList = unique(dataFileList);
    
    % concatenate multiple mouse lag data
    rowInd = 0;
    
    for dataFile = dataFileList
        rowInd = rowInd + 1;
        disp(['File # ' num2str(rowInd) '/' num2str(numel(dataFileList))]);
        
        try
            mouseData = load(dataFile);
            
            hbFC{groupInd} = cat(5,hbFC{groupInd},mouseData.hbFC);
            fluorFC{groupInd} = cat(5,fluorFC{groupInd},mouseData.fluorFC);
            mask{groupInd} = cat(3,mask{groupInd},mean(mouseData.mask,3) > 0);
        catch
        end
    end
end

%% extract roi info

seedInd = [2 1];

load('L:\ProcessedData\gcampStimROI.mat'); %stimROIAll
stimROIAll = logical(stimROIAll);
roi = squeeze(stimROIAll(:,:,1,1));

hbFCROI = cell(4,1);
fluorFCROI = cell(4,1);
for groupInd = 1:4
    groupFC = reshape(squeeze(hbFC{groupInd}(:,:,seedInd(1),seedInd(2),:)),128^2,[]);
    hbFCROI{groupInd} = nanmean(groupFC(roi,:),1);
    
    groupFC = reshape(squeeze(fluorFC{groupInd}(:,:,seedInd(1),seedInd(2),:)),128^2,[]);
    fluorFCROI{groupInd} = nanmean(groupFC(roi,:),1);
end

label = [];
x1 = []; for i = 1:4; x1 = [x1 hbFCROI{i}]; label = [label i*ones(size(hbFCROI{i}))]; end
x2 = []; for i = 1:4; x2 = [x2 fluorFCROI{i}]; end

% p value
[~,pValHb(1)] = ttest2(hbFCROI{1},hbFCROI{2});
[~,pValHb(2)] = ttest2(hbFCROI{1},hbFCROI{3});
[~,pValHb(3)] = ttest2(hbFCROI{1},hbFCROI{4});
[~,pValFluor(1)] = ttest2(fluorFCROI{1},fluorFCROI{2});
[~,pValFluor(2)] = ttest2(fluorFCROI{1},fluorFCROI{3});
[~,pValFluor(3)] = ttest2(fluorFCROI{1},fluorFCROI{4});

%% plot

fontSize = 18;

seedRoi = squeeze(stimROIAll(:,:,seedInd(1),seedInd(2)));

figure;
ax = gca;
wlData = load('L:\ProcessedData\wl.mat');
image(wlData.xform_wl,'AlphaData',wlData.xform_isbrain); hold on;
mouse.plot.plotContour(ax,roi,'g','-',4);
mouse.plot.plotContour(ax,seedRoi,'g','-',4);
set(ax,'Visible','off'); axis(ax,'square');

figure('Position',[100 100 1000 400]);
subplot('Position',[0.1 0.1 0.4 0.8]);
H = notBoxPlot(x1,label);
set([H(:).data],'MarkerSize',4,...
    'markerFaceColor',[1,1,1]*0.25,...
    'markerEdgeColor', 'none');
set(gca,'XTickLabel',{'baseline','week 1','week 4','week 8'});
set(gca,'FontSize',14);
ylabel('correlation, z(r)')
ylim([-1 1.8]);
sigstarExtended([1 2],pValHb(1),0,fontSize); sigstarExtended([1 3],pValHb(2),0,fontSize);
sigstarExtended([1 4],pValHb(3),0,fontSize);

subplot('Position',[0.6 0.1 0.4 0.8]);
H = notBoxPlot(x2,label);
set([H(:).data],'MarkerSize',4,...
    'markerFaceColor',[1,1,1]*0.25,...
    'markerEdgeColor', 'none');
set(gca,'XTickLabel',{'baseline','week 1','week 4','week 8'});
set(gca,'FontSize',14);
ylabel('correlation, z(r)')
ylim([-0.6 1.3]);
sigstarExtended([1 2],pValFluor(1),0,fontSize); sigstarExtended([1 3],pValFluor(2),0,fontSize);
sigstarExtended([1 4],pValFluor(3),0,fontSize);
