function plotResponse(excelFile,rows,varargin)
%plotStimResponse Plot stimulation response and save figures
%   Inputs:
%       blockDesign = struct explaining how the block is designed.
%           .off = how many seconds is it off (default = 5)
%           .on = how many seconds is it on (default = 5)
%           .off2 = how many seconds is it off again (default = 50)
%           .expectedLoc = [y x] describing where is response expected
%           (default = [82 100])
%       parameters = filtering and other analysis parameters
%           .lowpass = low pass filter thr (if empty, no low pass)
%           .highpass = high pass filter thr (if empty, no high pass)

if numel(varargin) > 0
    blockDesign = varargin{1};
else
    blockDesign.off = 5;
    blockDesign.on = 5;
    blockDesign.off2 = 50;
    blockDesign.expectedLoc = [82 100];
end

if numel(varargin) > 1
    parameters = varargin{2};
else
    parameters.lowpass = 0.03; %1/30 Hz
    parameters.highpass = [];
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
fluorFiles = [];
hbFiles = [];

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
notRoi = [];
roiData = [];
notRoiData = [];

for trialInd = 1:trialNum
    mask = load(maskFiles(trialInd));
    
    hbdata = load(hbFiles(trialInd));
    fluordata = load(fluorFiles(trialInd));
    try
        xform_datahb = hbdata.data_hb;
    catch
        xform_datahb = hbdata.xform_datahb;
    end
    try
        xform_datafluorCorr = fluordata.data_fluorCorr;
    catch
        xform_datafluorCorr = fluordata.xform_datafluorCorr;
    end
    
    fs = fluordata.sessionInfo.freqout;
    time = fluordata.rawTime;
    
    % gsr
    xform_datahb = preprocess.gsr(xform_datahb,mask.xform_isbrain);
    xform_datafluorCorr = preprocess.gsr(xform_datafluorCorr,mask.xform_isbrain);
    
    % filtering
    if ~isempty(parameters.highpass)
        xform_datafluorCorr = highpass(xform_datafluorCorr,parameters.highpass,fs);
    end
    if ~isempty(parameters.lowpass)
        xform_datafluorCorr = lowpass(xform_datafluorCorr,parameters.lowpass,fs);
    end
        
    totalData = cat(3,xform_datahb,xform_datafluorCorr);    
    
    blockDur = blockDesign.off + blockDesign.on + blockDesign.off2;
    [blockDataTrial, blockTime] = preprocess.blockAvg(totalData,time,blockDur,blockDur);
    
    % stim response
    stimTimeLim = [blockDesign.off+blockDesign.on-1 blockDesign.off+blockDesign.on+1];
    stimTimeInd = blockTime > stimTimeLim(1) & blockTime <= stimTimeLim(2);
    stimResponseTrial = mean(blockDataTrial(:,:,:,stimTimeInd),4);
    
    % find roi
    centerCoor = blockDesign.expectedLoc;
    roiMap = abs(stimResponseTrial(:,:,1));
    candidateCoor = mouse.plot.circleCoor(centerCoor,5);
    candidateCoor = candidateCoor(1,:) + size(roiMap,1)*candidateCoor(2,:);
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
    
    notRoiTrial = true(size(roiCandidates));
    notRoiTrial(clusters.PixelIdxList{clusterSizes==maxClusterSize}) = false;
    notRoiTrial(~mask.xform_isbrain) = false;
    
    % get roi response
    roiDataTrial = reshape(totalData,size(totalData,1)*size(totalData,2),size(totalData,3),[]);
    roiDataTrial = squeeze(mean(roiDataTrial(roiTrial,:,:),1)); % species x time
    
    notRoiDataTrial = reshape(totalData,size(totalData,1)*size(totalData,2),size(totalData,3),[]);
    notRoiDataTrial = squeeze(mean(notRoiDataTrial(notRoiTrial,:,:),1)); % species x time
    
    if size(roiDataTrial,2) == 1
        roiDataTrial = roiDataTrial';
    end
    if size(notRoiDataTrial,2) == 1
        notRoiDataTrial = notRoiDataTrial';
    end
    
    roiResponseFig = figure('Position',[200 200 900 500]);
    p = panel();
    p.pack({1/2 []}, {1/3 []});
    p(1,1).select(); imagesc(roiTrial); axis(gca,'square');
    xlim([1 size(roiTrial,1)]); ylim([1 size(roiTrial,2)]);
    set(gca,'ydir','reverse')
    set(gca,'XTick',[]); set(gca,'YTick',[]); title('ROI');
    p(1,2).select();
    plot(time,1E3*roiDataTrial(1,:),'r'); hold on;
    plot(time,1E3*roiDataTrial(2,:),'b');
    plot(time,1E3*sum(roiDataTrial(1:2,:),1),'k');
    plot(time,roiDataTrial(3,:),'m');
    legend('HbO (mM)','HbR (mM)','HbT (mM)','Fluor corr');
    
    p(2,1).select(); imagesc(notRoiTrial); axis(gca,'square');
    xlim([1 size(notRoiTrial,1)]); ylim([1 size(notRoiTrial,2)]);
    set(gca,'ydir','reverse')
    set(gca,'XTick',[]); set(gca,'YTick',[]); title('ROI');
    p(2,2).select();
    plot(time,1E3*notRoiDataTrial(1,:),'r'); hold on;
    plot(time,1E3*notRoiDataTrial(2,:),'b');
    plot(time,1E3*sum(notRoiDataTrial(1:2,:),1),'k');
    plot(time,notRoiDataTrial(3,:),'m');
    legend('HbO (mM)','HbR (mM)','HbT (mM)','Fluor corr');
    
    % save roi response
    roiResponseFile = fullfile(saveFileLocs(trialInd),...
        strcat(saveFileDataNames(trialInd),"-roiTimeCourse.fig"));
    savefig(roiResponseFig,roiResponseFile);
    close(roiResponseFig);
    
    % concat across trials
    stimResponse = cat(4,stimResponse,stimResponseTrial);
    roi = cat(3,roi,roiTrial);
    notRoi = cat(3,notRoi,notRoiTrial);
    roiData = cat(3,roiData,roiDataTrial);
    notRoiData = cat(3,notRoiData,notRoiDataTrial);
end
    
%% plot average across trials

saveFileLoc = fileparts(saveFileLocs(1));
[~,excelFileName,~] = fileparts(excelFile);

% roi time course
roiAvg = mean(roi,3);
notRoiAvg = mean(notRoi,3);
roiDataAvg = mean(roiData,3);
notRoiDataAvg = mean(notRoiData,3);

if size(roiDataAvg,2) == 1
    roiDataAvg = roiDataAvg';
end
if size(notRoiDataAvg,2) == 1
    notRoiDataAvg = notRoiDataAvg';
end

roiResponseFig = figure('Position',[200 200 900 500]);
p = panel();
p.pack({1/2 []}, {1/3 []});
p(1,1).select(); imagesc(roiAvg); axis(gca,'square');
xlim([1 size(roiAvg,1)]); ylim([1 size(roiAvg,2)]);
set(gca,'ydir','reverse')
set(gca,'XTick',[]); set(gca,'YTick',[]); title('ROI');
p(1,2).select();
plot(time,1E3*roiDataAvg(1,:),'r'); hold on;
plot(time,1E3*roiDataAvg(2,:),'b');
plot(time,1E3*sum(roiDataAvg(1:2,:),1),'k');
plot(time,roiDataAvg(3,:),'m');
legend('HbO (mM)','HbR (mM)','HbT (mM)','Fluor corr');

p(2,1).select(); imagesc(notRoiAvg); axis(gca,'square');
xlim([1 size(notRoiAvg,1)]); ylim([1 size(notRoiAvg,2)]);
set(gca,'ydir','reverse')
set(gca,'XTick',[]); set(gca,'YTick',[]); title('ROI');
p(2,2).select();
plot(time,1E3*notRoiDataAvg(1,:),'r'); hold on;
plot(time,1E3*notRoiDataAvg(2,:),'b');
plot(time,1E3*sum(notRoiDataAvg(1:2,:),1),'k');
plot(time,notRoiDataAvg(3,:),'m');
legend('HbO (mM)','HbR (mM)','HbT (mM)','Fluor corr');

% save roi response
roiResponseFile = fullfile(saveFileLoc,...
   strcat(string(excelFileName),"-rows",num2str(min(rows)),...
    "~",num2str(max(rows)),"-roiTimeCourse.fig"));
savefig(roiResponseFig,roiResponseFile);
close(roiResponseFig);

end

