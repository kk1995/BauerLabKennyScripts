% this script is a wrapper around gcampImaging.m function that shows how
% the function should be used. As shown, you state which tiff file to run,
% then get system and session information either via the functions
% sysInfo.m and session2procInfo.m or manual addition. Run the
% gcampImaging.m function afterwards and you are good to go!

%% import packages

import mouse.*

systemInfo = mouse.expSpecific.sysInfo('EastOIS1');
sessionInfo = mouse.expSpecific.sesInfo('none');
sessionInfo.hbSpecies = 1:4;
sessionInfo.probeSpecies = [];
sessionInfo.framerate = 29.76;
sessionInfo.lowpass = sessionInfo.framerate./2-0.1;
sessionInfo.freqout = sessionInfo.framerate;

darkFrameInd = [];

%% initialize

fileDir = "\\10.39.168.176\RawData_East3410\171128";
figureDir = "D:\figures";
fileList = dir(fileDir); fileList(1:2) = [];
saveDir = "D:\data\171128";
saveMaskFile = 'D:\data\171128_mask.mat';

fileMouse = [ones(1,6) 2*ones(1,9) 3*ones(1,9)];

%% make wl images
disp('getting wl images');

if ~exist(saveMaskFile)
    for mouseInd = unique(fileMouse)
        fileInd = find(fileMouse == mouseInd,1,'first');
        fileName = string(fullfile(fileList(fileInd).folder,fileList(fileInd).name));
        speciesNum = systemInfo.numLEDs;
        raw = read.readRaw(fileName,speciesNum,systemInfo.readFcn);
        %% get WL image, landmarks, and mask
        rgbOrder = systemInfo.rgb;
        wl = preprocess.getWL(raw,darkFrameInd,rgbOrder);
        [isbrain{mouseInd}, affineMarkers{mouseInd}] = preprocess.getLandmarksAndMask(wl);
    end
    save(saveMaskFile,'isbrain','affineMarkers');
else
    load(saveMaskFile);
end

%% process and save for each mouse and each run
disp('process and save');

for mouseInd = unique(fileMouse)
    disp(['mouse #' num2str(mouseInd)]);
    for run = find(fileMouse==mouseInd)
        disp(['  run #' num2str(run)]);
        
        %% state the tif file
        
        fileName = string(fullfile(fileList(run).folder,fileList(run).name));
        saveFileName = fullfile(saveDir,strcat(fileList(run).name(1:end-4),"-processed-newDPF.mat"));
        
        
        %% get raw
        
        speciesNum = systemInfo.numLEDs;
        raw = read.readRaw(fileName,speciesNum,systemInfo.readFcn);
        time = 1:size(raw,4); time = time + 1; time = time./sessionInfo.framerate;
        
        %% preprocess
        
        [time,data] = fluor.preprocess(time,raw,systemInfo,sessionInfo,affineMarkers{mouseInd},'darkFrameInd',darkFrameInd);
        xform_isbrain = preprocess.affineTransform(isbrain{mouseInd},affineMarkers{mouseInd});
        
        %% process
        
        [xform_hb,xform_gcamp,xform_gcampCorr] = fluor.process(data,systemInfo,sessionInfo,xform_isbrain);
        
        save(saveFileName,'time','xform_hb','xform_gcamp','xform_gcampCorr','isbrain','xform_isbrain','affineMarkers','-v7.3');
    end
end

%% get average data

disp('load and get avg data');

for mouseInd = unique(fileMouse)
    dataAvg = [];
    stimResponse = [];
    roi = [];
    disp(['mouse #' num2str(mouseInd)]);
    
    runs = find(fileMouse==mouseInd);
    figure1Name = fullfile(figureDir,strcat(fileList(runs(1)).name(1:end-10),"-blockAvg-newDPF.fig"));
    figure2Name = fullfile(figureDir,strcat(fileList(runs(1)).name(1:end-10),"-stimResponse-newDPF.fig"));
    for run = runs
        disp(['  run #' num2str(run)]);
        
        saveFileName = fullfile(saveDir,strcat(fileList(run).name(1:end-4),"-processed-newDPF.mat"));
        
        load(saveFileName);
        
        xform_hb = mouse.preprocess.gsr(xform_hb,xform_isbrain);
        
        xform_hb = lowpass(xform_hb,0.49,sessionInfo.framerate);
        xform_hb = highpass(xform_hb,0.009,sessionInfo.framerate);
        
        %% get block avg
        freqOut = 8;
        xform_hbAvg = mouse.preprocess.blockAvg(xform_hb,time,60,60*freqOut);
        blockTime = linspace(0,60,60*8+1); blockTime(end) = [];
        
        stimTime = (blockTime > 5 & blockTime <= 15);
        xform_hbStim = nanmean(xform_hbAvg(:,:,:,stimTime),4);
        stimResponseRun = xform_hbStim;
        
        %% get roi response
        
        % find the center coordinate of activation
        roiMap = abs(xform_hbStim(:,:,1));
%         roiMapSub = zeros(size(roiMap)); roiMapSub(30:110,1:50) = roiMap(30:110,1:50);
%         centerCoor = find(roiMapSub == max(roiMapSub(:)));
%         centerCoor = [mod(centerCoor-1,size(roiMap,1))+1, floor(centerCoor/size(roiMap,1))];
        centerCoor = [65 29];
        
        % find coordinates above the threshold
        coor = mouse.plot.circleCoor(centerCoor,20);
        coor = coor(1,:)+size(xform_hb,2)*coor(2,:);
        inCoor = false(size(xform_hb,2));
        inCoor(coor) = true;
        threshold = 0.75*prctile(roiMap(coor),95);
        
        roiCandidates = roiMap >= threshold;
        roiCandidates(~inCoor) = false;
        
        % choose largest cluster
        clusters = bwconncomp(roiCandidates,4);
        clusterSizes = nan(clusters.NumObjects,1);
        for clusterInd = 1:clusters.NumObjects
            clusterSizes(clusterInd) = numel(clusters.PixelIdxList{clusterInd});
        end
        maxClusterSize = max(clusterSizes);
        roiRun = false(size(roiCandidates));
        roiRun(clusters.PixelIdxList{clusterSizes==maxClusterSize}) = true;
        
        xform_hbRoiAvgRun = reshape(xform_hbAvg,size(xform_hbAvg,1)*size(xform_hbAvg,2),size(xform_hbAvg,3),[]);
        xform_hbRoiAvgRun = squeeze(nanmean(xform_hbRoiAvgRun(roiRun,:,:),1)); % 2 x 60
        
        xform_hbRoiAvgBaseline = nanmean(xform_hbRoiAvgRun(:,1:floor(5*freqOut)),2);
        
        xform_hbRoiAvgRun = xform_hbRoiAvgRun - repmat(xform_hbRoiAvgBaseline,1,size(xform_hbRoiAvgRun,2));
        dataAvgRun = xform_hbRoiAvgRun;
        dataAvg = cat(3,dataAvg,dataAvgRun);
        stimResponse = cat(4,stimResponse,stimResponseRun);
        roi = cat(3,roi,roiRun);
    end
    
    %% plot roi response
    plotData = nanmean(dataAvg,3);
    
    f1 = figure;
    p1 = plot(blockTime,plotData(1,:),'r'); hold on;
    p2 = plot(blockTime,plotData(2,:),'b');
    p3 = plot(blockTime,sum(plotData(1:2,:),1),'k');
    % ylim([-6E-7 1E-6]);
    ylim([-1E-6 1E-6]);
    yLim = ylim(gca);
    stimT = [5 15];
    for t = stimT
        plot([t t],yLim,'m');
    end
    legend([p1 p2 p3],["HbO","HbR","HbT"]);
    
    savefig(f1,figure1Name);
    
    %% plot stim response
    
    plotData = nanmean(stimResponse,4);
    
    speciesInd = {[1],[2],[1,2],[4]};
    titleArray = ["HbO","HbR","HbT","fluor corrected"];
    % cLim = [-0.5 0.5; -0.5 0.5; -0.5 0.5; -3E3 3E3]./1E6;
    % cLim = [-5 5; -5 5; -5 5; -2E4 2E4]./1E6;
    cLim = [-0.5 0.5; -0.5 0.5; -0.5 0.5; -5E3 5E3]./1E6;
    % cLim = [-0.3 0.3; -0.3 0.3; -0.3 0.3; -5E3 5E3]./1E6;
    f2 = figure;
    for i = 1:3
        subplot(2,2,i);
        imagesc(sum(plotData(:,:,speciesInd{i}),3),'AlphaData',xform_isbrain>0,cLim(i,:));
        colormap('jet'); axis(gca,'square'); xticklabels([]); yticklabels([]);
        colorbar;
        title(titleArray(i));
    end
    
    i = 4;
    s4 = subplot(2,2,i);
    imagesc(mean(roi,3)); colormap(s4, 'parula'); axis(gca,'square'); xticklabels([]); yticklabels([]); colorbar;
    
    savefig(f2,figure2Name);
    
    close(f1);
    close(f2);
end

