% here we will look at how much fc there is between the left somatosensory
% cortex and the right somatosensory cortex.

% we load the fc data with R ss cortex as seed
dataFile = 'D:\data\zachRosenthal\_stim\baseline_R_ROI_FC_GSR.mat';
load(dataFile); % fcData (4x1 cell)

% now get the L ss cortex roi from the file Zach gave me.
rROIFile = 'D:\data\zachRosenthal\_stim\ROI R 75.mat';
load(rROIFile); % brings roiR75
roi = roiR75;

roiValue = nan(4,14,2);
% now for each week
for week = 1:4
    % and for each mouse
    for mouse = 1:size(fcData{week},5)
        % only at low frequency
        freqInd = 1;
        
        for specInd = 1:2
            
            % get the seed fc
            mouseFCData = squeeze(fcData{week}(:,:,freqInd,specInd,mouse));
            
            % get the R roi fc
            mouseFCDataROI = mouseFCData(roi);
            
            % average the R roi fc value
            mouseFCDataROI = nanmean(mouseFCDataROI);
            
            % save to some group variable
            roiValue(week,mouse,specInd) = mouseFCDataROI;
        end
    end
end

%% plot

% plot bar plot showing average value in each week
roiValueSpec = roiValue(:,:,1);
figure('Position',[100 100 400 500]);
plot([0 5],[0 0],'r--'); hold on;
weekValue = ones(4,14);
for i = 1:4
    weekValue(i,:) = i;
end
roiValueVect = roiValueSpec(:);
weekValue = weekValue(:);
legendStr = {'baseline','week 1','week 4','week 8'};
H = notBoxPlot(roiValueVect,weekValue); hold on;
set(gca,'fontsize',14);
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
set(gca,'TickLength',[0.02 0]);
pairs = [1 2;1 3;1 4];
for pairInd = 1:size(pairs,1)
    cond1 = pairs(pairInd,1);
    cond2 = pairs(pairInd,2);
    
    test1 = roiValue(cond1,:,1);
    test2 = roiValue(cond2,:,1);
    [~,pVal] = ttest2(test1,test2);
    sigstarP({pairs(pairInd,:)},pVal,0,12);
%     if pVal <= 1E-3
%         sigstar({pairs(pairInd,:)},1E-3);
%     elseif pVal <= 1E-2
%         sigstar({pairs(pairInd,:)},1E-2);
%     elseif pVal <= 0.05
%         sigstar({pairs(pairInd,:)},0.05);
%     else
%         sigstar({pairs(pairInd,:)},nan);
%     end
end
title('HbT');
xlim([0.5 4.5]);
ylim([-0.6 1.22]);
ylabel('correlation');
set(gca,'TickLength',[0 0]);
plot([0 5],[1 1],'b--'); hold off;


% gcamp
roiValueSpec = roiValue(:,:,2);
figure('Position',[100 100 400 500]);
plot([0 5],[0 0],'r--'); hold on;
weekValue = ones(4,14);
for i = 1:4
    weekValue(i,:) = i;
end
roiValueVect = roiValueSpec(:);
weekValue = weekValue(:);
legendStr = {'baseline','week 1','week 4','week 8'};
H = notBoxPlot(roiValueVect,weekValue); hold on;
set(gca,'fontsize',14);
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
set(gca,'TickLength',[0.02 0]);
pairs = [1 2;1 3;1 4];
for pairInd = 1:size(pairs,1)
    cond1 = pairs(pairInd,1);
    cond2 = pairs(pairInd,2);
    
    test1 = roiValue(cond1,:,2);
    test2 = roiValue(cond2,:,2);
    [~,pVal] = ttest2(test1,test2);
    sigstarP({pairs(pairInd,:)},pVal,0,12);
%     if pVal <= 1E-3
%         sigstar({pairs(pairInd,:)},1E-3);
%     elseif pVal <= 1E-2
%         sigstar({pairs(pairInd,:)},1E-2);
%     elseif pVal <= 0.05
%         sigstar({pairs(pairInd,:)},0.05);
%     else
%         sigstar({pairs(pairInd,:)},nan);
%     end
end
title('GCaMP');
xlim([0.5 4.5]);
ylim([-0.6 1.22]);
ylabel('correlation');
set(gca,'TickLength',[0 0]);
plot([0 5],[1 1],'b--'); hold off;