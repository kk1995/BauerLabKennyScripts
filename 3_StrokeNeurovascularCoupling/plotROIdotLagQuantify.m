% plots lag relative to region

excelFile = fullfile('D:\data','zach_gcamp_stroke_fc_trials.xlsx');
rowList{1} = 2:43;
rowList{2} = 44:83;
rowList{3} = 84:125;
rowList{4} = 126:167;

sR = 16.8;
saveFolder = "L:\ProcessedData\3_NeurovascularCoupling";

%%

fMin = 0.01;
fMax = 0.08;

fMinStr = num2str(fMin);
fMinStr(strfind(fMinStr,'.')) = 'p';
fMaxStr = num2str(fMax);
fMaxStr(strfind(fMaxStr,'.')) = 'p';


%%

lagTime = cell(4,1);
lagAmp = cell(4,1);

for groupInd = 1:4
    
    % make data file list
    dataFileList = [];
    for row = rowList{groupInd}
        [~, ~, raw]=xlsread(excelFile,1, ['A',num2str(row),':K',num2str(row)]);
        mouseName = raw{2};
        dataDir = raw{5};
        dataFile = [raw{7} '-dotLagHbTG6-' fMinStr '-' fMaxStr '.mat'];
        dataFileList = [dataFileList string(fullfile(dataDir,dataFile))];
    end
    dataFileList = unique(dataFileList);
    
    % concatenate multiple mouse lag data
    rowInd = 0;
    dataFile = dataFileList(1);
    dashInd = strfind(dataFile,'-');
    prevMouseName = dataFile{1}; prevMouseName = prevMouseName(dashInd(1)+1:dashInd(2)-1);
    lagTimeMouse = [];
    lagAmpMouse = [];
    
    for dataFile = dataFileList
        rowInd = rowInd + 1;
        disp(['File # ' num2str(rowInd) '/' num2str(numel(dataFileList))]);
        
        dashInd = strfind(dataFile,'-');
        mouseName = dataFile{1}; mouseName = mouseName(dashInd(1)+1:dashInd(2)-1);
        
        if ~contains(prevMouseName,mouseName)
            lagTime{groupInd} = cat(3,lagTime{groupInd},nanmean(lagTimeMouse,3));
            x = atanh(nanmean(lagAmpMouse,3)); x(isinf(x)) = nan;
            lagAmp{groupInd} = cat(3,lagAmp{groupInd},x);
            lagTimeMouse = [];
            lagAmpMouse = [];
        else
            try
                trialData = load(dataFile);
                lagTimeMouse = cat(3,trialData.lagTimeTrial);
                lagAmpMouse = cat(3,trialData.lagAmpTrial);
            catch
            end
        end
        prevMouseName = mouseName;
    end
    
    lagTime{groupInd} = cat(3,lagTime{groupInd},nanmean(lagTimeMouse,3));
    x = atanh(nanmean(lagAmpMouse,3)); x(isinf(x)) = nan;
    lagAmp{groupInd} = cat(3,lagAmp{groupInd},x);
    
end

%% extract roi info

load('L:\ProcessedData\gcampStimROI.mat'); %stimROIAll
stimROIAll = logical(stimROIAll);
roi = squeeze(stimROIAll(:,:,1,1));

lagTimeROI = cell(4,1);
lagAmpROI = cell(4,1);
for groupInd = 1:4
    x = reshape(lagTime{groupInd},128^2,[]);
    lagTimeROI{groupInd} = nanmean(x(roi,:),1);
    
    x = reshape(lagAmp{groupInd},128^2,[]);
    lagAmpROI{groupInd} = nanmean(x(roi,:),1);
end

label = [];
x1 = []; for i = 1:4; x1 = [x1 lagTimeROI{i}]; label = [label i*ones(size(lagTimeROI{i}))]; end
x2 = []; for i = 1:4; x2 = [x2 lagAmpROI{i}]; end

% p value
[~,pValT(1)] = ttest2(lagTimeROI{1},lagTimeROI{2});
[~,pValT(2)] = ttest2(lagTimeROI{1},lagTimeROI{3});
[~,pValT(3)] = ttest2(lagTimeROI{1},lagTimeROI{4});
[~,pValA(1)] = ttest2(lagAmpROI{1},lagAmpROI{2});
[~,pValA(2)] = ttest2(lagAmpROI{1},lagAmpROI{3});
[~,pValA(3)] = ttest2(lagAmpROI{1},lagAmpROI{4});

%% plot

fontSize = 18;

figure;
ax = gca;
wlData = load('L:\ProcessedData\wl.mat');
image(wlData.xform_wl,'AlphaData',wlData.xform_isbrain); hold on;
mouse.plot.plotContour(ax,roi,'g','-',4);
set(ax,'Visible','off'); axis(ax,'square');

figure('Position',[100 100 1000 400]);
subplot('Position',[0.1 0.1 0.4 0.8]);
H = notBoxPlot(x1,label);
set([H(:).data],'MarkerSize',4,...
    'markerFaceColor',[1,1,1]*0.25,...
    'markerEdgeColor', 'none');
set(gca,'XTickLabel',{'baseline','week 1','week 4','week 8'});
set(gca,'FontSize',14);
ylabel('lag time, seconds')
sigstarExtended([1 2],pValT(1),0,fontSize); sigstarExtended([1 3],pValT(2),0,fontSize);
sigstarExtended([1 4],pValT(3),0,fontSize);

subplot('Position',[0.6 0.1 0.4 0.8]);
H = notBoxPlot(x2,label);
set([H(:).data],'MarkerSize',4,...
    'markerFaceColor',[1,1,1]*0.25,...
    'markerEdgeColor', 'none');
set(gca,'XTickLabel',{'baseline','week 1','week 4','week 8'});
set(gca,'FontSize',14);
ylabel('cross-correlation, z(r)')
sigstarExtended([1 2],pValA(1),0,fontSize); sigstarExtended([1 3],pValA(2),0,fontSize);
sigstarExtended([1 4],pValA(3),0,fontSize);