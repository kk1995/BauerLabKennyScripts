% here we will look at how much fc there is between the left somatosensory
% cortex and the right somatosensory cortex.

% we load the fc data with L ss cortex as seed
dataFile = 'D:\data\zachRosenthal\_stim\baseline_ROI_Lag.mat';
load(dataFile);
lagAmp1 = lagAmp;
lagTime1 = lagTime;
dataFile = 'D:\data\zachRosenthal\_stim\week8_ROI_Lag.mat';
load(dataFile);
lagAmp(1:2) = lagAmp1(1:2);
lagTime(1:2) = lagTime1(1:2);

% now get the R ss cortex roi from the file Zach gave me.
rROIFile = 'D:\data\zachRosenthal\_stim\ROI L 75.mat';
load(rROIFile); % brings roiL75
roi = roiL75;

roiValue = nan(4,14,2);
% now for each week
for week = 1:4
    % and for each mouse
    for mouse = 1:size(lagAmp{week},5)
        % only at low frequency
        freqInd = 1;
        
        for specInd = 1:2
            
            % get the seed fc
            mouseLagData = squeeze(lagAmp{week}(:,:,freqInd,specInd,mouse));
            
            % get the R roi fc
            mouseLagDataROI = mouseLagData(roi);
            
            % average the R roi fc value
            mouseLagDataROI = nanmean(mouseLagDataROI);
            
            % save to some group variable
            roiValue(week,mouse,specInd) = mouseLagDataROI;
        end
    end
end

%% plot

% plot bar plot showing average value in each week
roiValueSpec = roiValue(:,:,1);
% figure('Position',[100 100 720 500]);
figure('Position',[100 100 600 700]);
p = panel();
p.pack('h',{0.45 0.45 []});
p.margin = [3 10 3 10];
ax = p(1).select();
plot([0 5],[0 0],'r--'); hold on;
plot([0 5],[1 1],'b--'); hold on;
weekValue = ones(4,14);
for i = 1:4
    weekValue(i,:) = i;
end
roiValueVect = roiValueSpec(:);
weekValue = weekValue(:);
legendStr = {'b','w1','w4','w8'};
H = notBoxPlot(roiValueVect,weekValue);
set(gca,'fontsize',18);
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
    sigstarExtended({pairs(pairInd,:)},pVal,0,30);
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
th = title('HbT');
set(th,'FontSize',24);
xlim([0.5 4.5]);
ylim([0.4 1.22]);
set(gca,'Ytick',[]);
hold off;
set(gca,'TickLength',[0.025 0]);
set(gca,'YAxisLocation','right');


% gcamp
roiValueSpec = roiValue(:,:,2);
ax = p(2).select();
plot([0 5],[0 0],'r--'); hold on;
plot([0 5],[1 1],'b--'); hold on;
weekValue = ones(4,14);
for i = 1:4
    weekValue(i,:) = i;
end
roiValueVect = roiValueSpec(:);
weekValue = weekValue(:);
legendStr = {'b','w1','w4','w8'};
H = notBoxPlot(roiValueVect,weekValue);
set(gca,'fontsize',18);
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
    sigstarExtended({pairs(pairInd,:)},pVal,0,30);
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
th = title('GCaMP');
set(th,'FontSize',24);
xlim([0.5 4.5]);
ylim([0.4 1.22]);
% ylabel('correlation');
hold off;
set(gca,'TickLength',[0.025 0]);
set(gca,'YAxisLocation','right');
