% plots FC relative to region

fMin = 0.01;
fMax = 0.08;

dataDir = "L:\ProcessedData";

excelFile = fullfile('D:\data','zach_gcamp_stroke_fc_trials.xlsx');
rowList{1} = 2:43;
rowList{2} = 44:83;
rowList{3} = 84:125;
rowList{4} = 126:167;

sR = 16.8;

%%

[~,prefix] = fileparts(excelFile);

freqStr = [num2str(fMin),'-',num2str(fMax)];
freqStr(strfind(freqStr,'.')) = 'p';

%% extract roi info and plot

roiInd = [1 4]; % roi we care about that seed maps to
fontSize = 18;
corrLim = [-0.8 1];

load('L:\ProcessedData\gcampStimROI.mat'); %stimROIAll
stimROIAll = logical(stimROIAll);
seed = squeeze(stimROIAll(:,:,2,1));
roi = squeeze(stimROIAll(:,:,roiInd(1),roiInd(2)));

hbFCROI = cell(4,1);
fluorFCROI = cell(4,1);
for groupInd = 1:4
    fcFileName = [prefix '-rows' num2str(rowList{groupInd}(1)) '~' num2str(rowList{groupInd}(end)) ...
        '-roiFC-' freqStr '.mat'];
    load(fullfile(dataDir,fcFileName));
    groupFC = hbFC(roiInd(1),roiInd(2),:); groupFC = squeeze(groupFC)';
    hbFCROI{groupInd} = groupFC;
    
    groupFC = fluorFC(roiInd(1),roiInd(2),:); groupFC = squeeze(groupFC)';
    fluorFCROI{groupInd} = groupFC;
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

% plot

close all;

figure;
ax = gca;
wlData = load('L:\ProcessedData\wl.mat');
image(wlData.xform_wl,'AlphaData',wlData.xform_isbrain); hold on;
mouse.plot.plotContour(ax,seed,'g','-',4);
mouse.plot.plotContour(ax,roi,'g','-',4);
set(ax,'Visible','off'); axis(ax,'square');

figure('Position',[100 100 1000 400]);
subplot('Position',[0.1 0.1 0.4 0.8]);
H = notBoxPlot(x1,label);
set([H(:).data],'MarkerSize',4,...
    'markerFaceColor',[1,1,1]*0.25,...
    'markerEdgeColor', 'none');
set(gca,'XTickLabel',{'baseline','week 1','week 4','week 8'});
set(gca,'FontSize',18);
ylabel('correlation, z(r)')
ylim(corrLim);
sigstarExtended([1 2],pValHb(1),0,fontSize); sigstarExtended([1 3],pValHb(2),0,fontSize);
sigstarExtended([1 4],pValHb(3),0,fontSize);

subplot('Position',[0.6 0.1 0.4 0.8]);
H = notBoxPlot(x2,label);
set([H(:).data],'MarkerSize',4,...
    'markerFaceColor',[1,1,1]*0.25,...
    'markerEdgeColor', 'none');
set(gca,'XTickLabel',{'baseline','week 1','week 4','week 8'});
set(gca,'FontSize',18);
ylabel('correlation, z(r)')
ylim(corrLim);
sigstarExtended([1 2],pValFluor(1),0,fontSize); sigstarExtended([1 3],pValFluor(2),0,fontSize);
sigstarExtended([1 4],pValFluor(3),0,fontSize);
