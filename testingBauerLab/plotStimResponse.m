function plotStimResponse(excelFile,rows,varargin)
%plotStimResponse Plot stimulation response and save figures
%   Inputs:
%       blockDesign = struct explaining how the block is designed.
%           .off = how many seconds is it off (default = 5)
%           .on = how many seconds is it on (default = 5)
%           .off2 = how many seconds is it off again (default = 50)
%           .expectedLoc = [y x] describing where is response expected
%           (default = [82 100])

if numel(varargin) > 0
    blockDesign = varargin{1};
else
    blockDesign.off = 5;
    blockDesign.on = 5;
    blockDesign.off2 = 50;
    blockDesign.expectedLoc = [82 100];
end

%% import packages

import mouse.*

%% read the excel file to get the list of file names

trialInfo = expSpecific.extractExcel(excelFile,rows);

saveFileLocs = trialInfo.saveFolder;
saveFileMaskNames = trialInfo.saveFilePrefixMask;
saveFileDataNames = trialInfo.saveFilePrefixData;

trialNum = numel(saveFileLocs);

%% get list of processed files

maskFiles = [];
hbFiles = [];
fluorFiles = [];

for trialInd = 1:trialNum
    maskFile = string(fullfile(saveFileLocs(trialInd),...
        strcat(saveFileMaskNames(trialInd),"-LandmarksandMask.mat")));
    maskFiles = [maskFiles maskFile];
    
    hbFile = string(fullfile(saveFileLocs(trialInd),...
        strcat(saveFileDataNames(trialInd),"-datahb.mat")));
    hbFiles = [hbFiles hbFile];
    
    fluorFile = string(fullfile(saveFileLocs(trialInd),...
        strcat(saveFileDataNames(trialInd),"-dataFluor.mat")));
    fluorFiles = [fluorFiles fluorFile];
end

%% load each file and find block response

stimResponse = [];
roi = [];
roiData = [];
blockData = [];

for trialInd = 1:trialNum
    hbdata = load(hbFiles(trialInd));
    mask = load(maskFiles(trialInd));
    
    try
        xform_datahb = hbdata.data_hb;
    catch
        xform_datahb = hbdata.xform_datahb;
    end
    
    fluordata = load(fluorFiles(trialInd));
    try
        xform_datafluorCorr = fluordata.data_fluorCorr;
        xform_datafluor = fluordata.data_fluor;
    catch
        xform_datafluorCorr = fluordata.xform_datafluorCorr;
        xform_datafluor = fluordata.xform_datafluor;
    end
    
    % gsr
    xform_datahb = preprocess.gsr(xform_datahb,mask.xform_isbrain);
    %     vasculature = false(size(mask.xform_isbrain));
    %     vasculature(60:65,64:65) = true;
    %     xform_datahb = preprocess.rsr(xform_datahb,mask.xform_isbrain,vasculature);
    
    if isempty(xform_datafluorCorr)
        totalData = xform_datahb;
    else
        xform_datafluor = preprocess.gsr(xform_datafluor,mask.xform_isbrain);
        xform_datafluorCorr = preprocess.gsr(xform_datafluorCorr,mask.xform_isbrain);
        totalData = cat(3,xform_datahb,xform_datafluor,xform_datafluorCorr);
    end
    
    time = hbdata.rawTime;
    fs = hbdata.reader.FreqOut;
    
    blockDur = blockDesign.off + blockDesign.on + blockDesign.off2;
    
    [blockDataTrial, blockTime] = preprocess.blockAvg(totalData,time,blockDur,blockDur);
    
    blockData = cat(5,blockData,blockDataTrial);
    
    % stim response
    stimTimeLim = [blockDesign.off+blockDesign.on-1 blockDesign.off+blockDesign.on+1];
    stimTimeInd = blockTime > stimTimeLim(1) & blockTime <= stimTimeLim(2);
    stimResponseTrial = mean(blockDataTrial(:,:,:,stimTimeInd),4);
    
    species2Plot = size(stimResponseTrial,3) + 1;
    
    stimResponseFig = figure('Position',[200 200 200*species2Plot 300]);
    subplot(1,species2Plot,1); imagesc(1E3*stimResponseTrial(:,:,1),[-1E-3 1E-3]);
    colormap('jet'); colorbar; axis(gca,'square');
    set(gca,'XTick',[]); set(gca,'YTick',[]); title('HbO');
    subplot(1,species2Plot,2); imagesc(1E3*stimResponseTrial(:,:,2),[-1E-3 1E-3]);
    colormap('jet'); colorbar; axis(gca,'square');
    set(gca,'XTick',[]); set(gca,'YTick',[]); title('HbR');
    subplot(1,species2Plot,3); imagesc(1E3*sum(stimResponseTrial(:,:,1:2),3),[-1E-3 1E-3]);
    colormap('jet'); colorbar; axis(gca,'square');
    set(gca,'XTick',[]); set(gca,'YTick',[]); title('HbT');
    
    if species2Plot > 3
        subplot(1,species2Plot,4); imagesc(sum(stimResponseTrial(:,:,3),3),[-1E-2 1E-2]);
        colormap('jet'); colorbar; axis(gca,'square');
        set(gca,'XTick',[]); set(gca,'YTick',[]); title('Fluor');
        subplot(1,species2Plot,5); imagesc(sum(stimResponseTrial(:,:,4),3),[-1E-2 1E-2]);
        colormap('jet'); colorbar; axis(gca,'square');
        set(gca,'XTick',[]); set(gca,'YTick',[]); title('Fluor corr');
    end
    
    % save stim response
    stimResponseFile = fullfile(saveFileLocs(trialInd),...
        strcat(saveFileDataNames(trialInd),"-stimResponse.fig"));
    savefig(stimResponseFig,stimResponseFile);
    close(stimResponseFig);
    
    % find roi
%     centerCoor = blockDesign.expectedLoc;
%     roiMap = abs(stimResponseTrial(:,:,1));
%     coor = mouse.plot.circleCoor(centerCoor,5);
%     coor = coor(1,:)+size(roiMap,2)*coor(2,:);
%     roiTrial = false(128);
%     roiTrial(coor) = true;
    
    centerCoor = blockDesign.expectedLoc;
    roiMap = abs(stimResponseTrial(:,:,1));
    candidateCoor = mouse.plot.circleCoor(centerCoor,5);
    candidateCoor = candidateCoor(1,:) + size(roiMap,1)*(candidateCoor(2,:)-1);
    roiMapSub = zeros(size(roiMap)); roiMapSub(candidateCoor) = roiMap(candidateCoor);
    centerCoor = find(roiMapSub == max(roiMapSub(:)));
    centerCoor = [mod(centerCoor-1,size(roiMap,1))+1, floor(centerCoor/size(roiMap,1))];
    
    coor = mouse.plot.circleCoor(centerCoor,10);
    coor(:,coor(1,:) < 1) = [];
    coor(:,coor(2,:) < 1) = [];
    coor = coor(1,:)+size(roiMap,2)*coor(2,:);
    inCoor = false(size(roiMap,2));
    inCoor(coor) = true;
    
    threshold = 0.75*prctile(roiMap(coor),95);
    
    roiCandidates = roiMap >= threshold;
    roiCandidates(~inCoor) = false;
    
    clusters = bwconncomp(roiCandidates,4);
    clusterSizes = nan(clusters.NumObjects,1);
    for clusterInd = 1:clusters.NumObjects
        clusterSizes(clusterInd) = numel(clusters.PixelIdxList{clusterInd});
    end
    maxClusterSize = max(clusterSizes);
    roiTrial = false(size(roiCandidates));
    roiTrial(clusters.PixelIdxList{clusterSizes==maxClusterSize}) = true;
    
    % get roi response
    [blockDataTrial, blockTime] = preprocess.blockAvg(totalData,time,blockDur,blockDur*fs);
    
    roiDataTrial = reshape(blockDataTrial,size(blockDataTrial,1)*size(blockDataTrial,2),size(blockDataTrial,3),[]);
    roiDataTrial = squeeze(nanmean(roiDataTrial(roiTrial,:,:),1)); % species x time
    baselineInd = blockTime < blockDesign.off;
    roiDataBaseline = nanmean(roiDataTrial(:,baselineInd),2);
    roiDataTrial = roiDataTrial - repmat(roiDataBaseline,1,size(roiDataTrial,2));
    
    roiResponseFig = figure('Position',[200 200 900 500]);
    p = panel();
    p.pack('h', {1/3 []});
    p(1).select(); imagesc(roiTrial); axis(gca,'square');
    xlim([1 size(roiTrial,1)]); ylim([1 size(roiTrial,2)]);
    set(gca,'ydir','reverse')
    set(gca,'XTick',[]); set(gca,'YTick',[]); title('ROI');
    p(2).select();
    plot(blockTime,1E3*roiDataTrial(1,:),'r'); hold on;
    plot(blockTime,1E3*roiDataTrial(2,:),'b');
    plot(blockTime,1E3*sum(roiDataTrial(1:2,:),1),'k');
    if species2Plot > 3
        plot(blockTime,sum(roiDataTrial(3,:),1),'g');
        plot(blockTime,sum(roiDataTrial(4,:),1),'m');
        legend('HbO','HbR','HbT','Fluor','Fluor corr');
    else
        legend('HbO','HbR','HbT');
    end
    
    % save roi response
    roiResponseFile = fullfile(saveFileLocs(trialInd),...
        strcat(saveFileDataNames(trialInd),"-roiBlockTimeCourse.fig"));
    savefig(roiResponseFig,roiResponseFile);
    close(roiResponseFig);
    
    % concat across trials
    stimResponse = cat(4,stimResponse,stimResponseTrial);
    roi = cat(3,roi,roiTrial);
    roiData = cat(3,roiData,roiDataTrial);
end
    
%% plot average across trials

% stim response
stimResponseAvg = mean(stimResponse,4);

stimResponseFig = figure('Position',[200 200 200*species2Plot 300]);
subplot(1,species2Plot,1); imagesc(1E3*stimResponseAvg(:,:,1),[-1E-3 1E-3]);
colormap('jet'); colorbar; axis(gca,'square');
set(gca,'XTick',[]); set(gca,'YTick',[]); title('HbO');
subplot(1,species2Plot,2); imagesc(1E3*stimResponseAvg(:,:,2),[-1E-3 1E-3]);
colormap('jet'); colorbar; axis(gca,'square');
set(gca,'XTick',[]); set(gca,'YTick',[]); title('HbR');
subplot(1,species2Plot,3); imagesc(1E3*sum(stimResponseAvg(:,:,1:2),3),[-1E-3 1E-3]);
colormap('jet'); colorbar; axis(gca,'square');
set(gca,'XTick',[]); set(gca,'YTick',[]); title('HbT');
if species2Plot > 3
    subplot(1,species2Plot,4); imagesc(sum(stimResponseAvg(:,:,3),3),[-1E-2 1E-2]);
    colormap('jet'); colorbar; axis(gca,'square');
    set(gca,'XTick',[]); set(gca,'YTick',[]); title('Fluor corr');
    subplot(1,species2Plot,5); imagesc(sum(stimResponseAvg(:,:,4),3),[-1E-2 1E-2]);
    colormap('jet'); colorbar; axis(gca,'square');
    set(gca,'XTick',[]); set(gca,'YTick',[]); title('Fluor corr');
end

% save stim response
saveFileLoc = fileparts(saveFileLocs(1));
[~,excelFileName,~] = fileparts(excelFile);
stimResponseFile = fullfile(saveFileLoc,...
    strcat(string(excelFileName),"-rows",num2str(min(rows)),...
    "~",num2str(max(rows)),"-stimResponse.fig"));
savefig(stimResponseFig,stimResponseFile);
close(stimResponseFig);

% roi time course
roiAvg = mean(roi,3);
roiDataAvg = mean(roiData,3);
baselineInd = blockTime < blockDesign.off;
roiDataBaseline = mean(roiDataAvg(:,baselineInd),2);
roiDataAvg = roiDataAvg - repmat(roiDataBaseline,1,size(roiDataAvg,2));

roiResponseFig = figure('Position',[200 200 900 500]);
p = panel();
p.pack('h', {1/3 []});
p(1).select(); imagesc(roiAvg); axis(gca,'square');
xlim([1 size(roiAvg,1)]); ylim([1 size(roiAvg,2)]);
set(gca,'ydir','reverse')
set(gca,'XTick',[]); set(gca,'YTick',[]); title('ROI');
p(2).select();
plot(blockTime,1E3*roiDataAvg(1,:),'r'); hold on;
plot(blockTime,1E3*roiDataAvg(2,:),'b');
plot(blockTime,1E3*sum(roiDataAvg(1:2,:),1),'k'); legend('HbO','HbR','HbT');
if species2Plot > 3
    plot(blockTime,sum(roiDataAvg(3,:),1),'g');
    plot(blockTime,sum(roiDataAvg(4,:),1),'m');
    legend('HbO','HbR','HbT','Fluor','Fluor corr');
else
    legend('HbO','HbR','HbT');
end

% save roi response
roiResponseFile = fullfile(saveFileLoc,...
   strcat(string(excelFileName),"-rows",num2str(min(rows)),...
    "~",num2str(max(rows)),"-roiTimeCourse.fig"));
savefig(roiResponseFig,roiResponseFile);
close(roiResponseFig);

% plot each time point
blockDataAvg = mean(blockData,5);
f1 = figure('Position',[200 200 1000 ceil(blockDur/10)*150]);
for i = 1:blockDur
    subplot(ceil(blockDur/10),10,i);
    imagesc(squeeze(blockDataAvg(:,:,1,i)),[-1E-6 1E-6]); colormap('jet');
    axis(gca,'square'); set(gca,'XTick',[]); set(gca,'YTick',[]);
    if i == blockDur
        colorbar;
    end
end
blockAvgFile = fullfile(saveFileLoc,...
   strcat(string(excelFileName),"-rows",num2str(min(rows)),...
    "~",num2str(max(rows)),"-blockAvgHbO.fig"));

savefig(f1,blockAvgFile);
close(f1);

f1 = figure('Position',[200 200 1000 ceil(blockDur/10)*150]);
for i = 1:blockDur
    subplot(ceil(blockDur/10),10,i);
    imagesc(squeeze(blockDataAvg(:,:,4,i)),[-0.5E-2 0.5E-2]); colormap('jet');
    axis(gca,'square'); set(gca,'XTick',[]); set(gca,'YTick',[]);
    if i == blockDur
        colorbar;
    end
end
blockAvgFile = fullfile(saveFileLoc,...
   strcat(string(excelFileName),"-rows",num2str(min(rows)),...
    "~",num2str(max(rows)),"-blockAvgFluorCorr.fig"));

savefig(f1,blockAvgFile);
close(f1);

end