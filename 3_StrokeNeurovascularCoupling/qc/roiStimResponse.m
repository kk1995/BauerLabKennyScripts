sR = 16.8;
blockLen = 20;
stimTime = [5 10];
roiFile = 'D:\data\zachRosenthal\_stim\ROI R 75.mat';
roiData = load(roiFile);
roi = roiData.roiR75;

% get list of mice
excelFile = 'D:\data\Stroke Study 1 sorted.xlsx';
rows = 1;
recDates = [];
mouseNames = [];
for row = rows
    [~, ~, raw]=xlsread(excelFile,1, ['A',num2str(row),':B',num2str(row)]);
    recDates = [recDates string(raw{1})];
    mouseNames = [mouseNames string(raw{2})];
end

roiResponse = [];
roiBlockResponse = [];
stimResponse = [];

for mouseInd = 1:numel(mouseNames)
    disp(['mouse # ' num2str(mouseInd)]);
    for run = 1:3
        disp(['run # ' num2str(run)]);
        fileName = strcat("K:\Proc2\",recDates(mouseInd),"\",recDates(mouseInd),"-",...
            mouseNames(mouseInd),"-dataGCaMP-stim",num2str(run),".mat");
        load(fileName);
        oxy = cat(3,oxy(:,:,1),oxy);
        deoxy = cat(3,deoxy(:,:,1),deoxy);
        gcamp6 = cat(3,gcamp6(:,:,1),gcamp6);
        gcamp6corr = cat(3,gcamp6corr(:,:,1),gcamp6corr);
        
        runData = cat(4,oxy,deoxy,gcamp6,gcamp6corr); % 128x128x5040x4
        % oxy, deoxy, gcamp6, gcamp6corr
        runData = permute(runData,[1,2,4,3]);
        
        blockData = reshape(runData,128,128,4,sR*blockLen,[]);
        blockData = nanmean(blockData,5);
        blockTime = 1:sR*blockLen; blockTime = blockTime./16.8;

        stimTimeInd = blockTime > 5 & blockTime < 10;
        stimResponseRun = nanmean(blockData(:,:,:,stimTimeInd),4);
        
        roiResponseRun = reshape(runData,128*128,4,[]);
        roiResponseRun = roiResponseRun(roi,:,:);
        roiResponseRun = squeeze(nanmean(roiResponseRun,1));
        
        roiBlockResponseRun = reshape(blockData,128*128,4,[]);
        roiBlockResponseRun = roiBlockResponseRun(roi,:,:);
        roiBlockResponseRun = squeeze(nanmean(roiBlockResponseRun,1));
        
        % save to larger matrix
        roiBlockResponse = cat(3,roiBlockResponse, roiBlockResponseRun);
        roiResponse = cat(3,roiResponse,roiResponseRun);
        stimResponse = cat(4,stimResponse,stimResponseRun);
    end
    
%     rowNum = size(roiResponse,3);
%     roiResponse(:,:,rowNum-2) = nanmean(roiResponse(:,:,rowNum-2:rowNum),3);
%     roiResponse = roiResponse(:,:,1:rowNum-2);
end

%% save

save('D:\data\zachRosenthal\_stim\roiRResponseMouse1.mat','roiResponse','roiBlockResponse','stimResponse');

%% plot

plotData = nanmean(roiBlockResponse,3);
plot(blockTime,plotData(1,:),'r');
hold on;
plot(blockTime,plotData(2,:),'b');
plot(blockTime,plotData(3,:),'g');
plot(blockTime,plotData(4,:),'k');

legend('hbo','hbr','g6','g6corrected')

%%
plotData = nanmean(stimResponse,4);
plotData(:,:,1:2) = plotData(:,:,1:2);
plotData(:,:,3) = sum(plotData(:,:,1:2),3);
figure;
subTitles = ["HbO","HbR","HbT","gcamp corr"];
cLim = [-5E-4 5E-4; -5E-4 5E-4; -5E-4 5E-4; -2E-3 2E-3];
for i = 1:4
subplot(2,2,i);
imagesc(plotData(:,:,i),cLim(i,:));
colormap('jet');
colorbar;
axis(gca,'square'); yticklabels([]); xticklabels([]);
title(subTitles(i));
end

