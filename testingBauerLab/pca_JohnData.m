% this script is a wrapper around gcampImaging.m function that shows how
% the function should be used. As shown, you state which tiff file to run,
% then get system and session information either via the functions
% sysInfo.m and session2procInfo.m or manual addition. Run the
% gcampImaging.m function afterwards and you are good to go!

%% import packages

import mouse.*

%% initialize
ratioDataRoiAvg = [];
stimRatioResponse = [];

filePrefix = "\\10.39.168.176\RawData_East3410\181004\181004-D16M2-stim";
saveFilePrefix = "D:\data\none\181004-D16M2-stim";
figFilePrefix = "D:\figures\181004-D16M2-stim";

goodRuns{1} = [2 4];
goodRuns{2} = 1;
goodRuns{3} = [1 4];

totalRatioData = [];
totalData = [];
totalTime = [];
readInfo.speciesNum = speciesNum;

for run = 1:3
    disp(['run # ' num2str(run)]);
    fileName = strcat(filePrefix,num2str(run),".tif");
    savePreprocFileName = strcat(saveFilePrefix,num2str(run),"-preprocessed.mat");
    saveProcessedFileName = strcat(saveFilePrefix,num2str(run),"-processed.mat");
    maskFileName = 'D:\data\none\181004-D16M2-LandmarksandMask.mat';
    
    %% get system or session information.
    
    % use the pre-existing system and session information by selecting the type
    % of system and the type of session. If the system or session you are using
    % do not fit the existing choices, you can either add new system and
    % session types or add them manually.
    % for systemInfo, you need rgb and LEDFiles
    % for sessionInfo, you need framerate, freqout, lowpass, and highpass
    
    % systemType = 'fcOIS1', 'fcOIS2', 'fcOIS2_Fluor' or 'EastOIS1_Fluor'
    systemInfo = mouse.expSpecific.sysInfo('EastOIS1');
    
    % sessionType = 'fc' or 'stim'
    sessionInfo = mouse.expSpecific.sesInfo('none');
    sessionInfo.detrendSpatially = false;
    sessionInfo.detrendTemporally = true;
    sessionInfo.hbSpecies = 1:4;
    sessionInfo.probeSpecies = [];
    sessionInfo.framerate = 20;
    sessionInfo.freqout = 8;
    sessionInfo.lowpass = sessionInfo.freqout./2-0.1;
    
    darkFrameInd = [];

    %% get raw

    if exist(savePreprocFileName)
        load(savePreprocFileName);
        maskData = load(maskFileName);
        
        xform_isbrain = preprocess.affineTransform(isbrain,affineMarkers);
    else
        speciesNum = systemInfo.numLEDs+1;
        disp('loading files');
        [raw, rawTime] = read.readRaw(fileName,systemInfo.readFcn,readInfo,...
        systemInfo.invalidFrameInd,timeFrameNum,sessionInfo.framerate,sessionInfo.freqout);
        raw = raw(:,:,1:4,:);
        
        if exist(maskFileName)
            maskData = load(maskFileName);
        else
            rgbOrder = systemInfo.rgb;
            wl = preprocess.getWL(raw,darkFrameInd,rgbOrder);
            [isbrain, I] = preprocess.getLandmarksAndMask(wl);
            maskData.isbrain = isbrain;
            maskData.I = I;
            
            save(maskFileName,'isbrain','I','-v7.3');
        end
        isbrain = logical(maskData.isbrain);
        affineMarkers = maskData.I;
        
        %% preprocess
        disp('preprocess');
        [time,data] = fluor.preprocess(time,raw,systemInfo,sessionInfo,affineMarkers,'darkFrameInd',darkFrameInd);
        xform_isbrain = preprocess.affineTransform(isbrain,affineMarkers);
        
        save(savePreprocFileName,'time','data','isbrain','affineMarkers','-v7.3');
    end
    
    ratioData = logmean(data);
        
    if exist(saveProcessedFileName)
        load(saveProcessedFileName)
    else
        
        %% process
        disp('process');
        [xform_hb,xform_gcamp,xform_gcampCorr] = fluor.process(data,systemInfo,sessionInfo,xform_isbrain);
        
        save(saveProcessedFileName,'xform_hb','xform_gcamp',...
            'xform_gcampCorr','-v7.3');
    end
    
    %% only keep good blocks
    freqOut = sessionInfo.freqout;
    
    newData = [];
    newRatioData = [];
    newTime = [];
    
    goodBlocks = goodRuns{run};
    for goodBlock = 1:numel(goodBlocks)
        blockFrames = ((goodBlocks(goodBlock)-1)*60*freqOut+1):...
            goodBlocks(goodBlock)*60*freqOut;
        newRatioData = cat(4,newRatioData,ratioData(:,:,:,blockFrames));
        newData = cat(4,newData,xform_hb(:,:,:,blockFrames));
        newTime = [newTime time(blockFrames)];
    end
    
    totalData = cat(4,totalData,newData);
    totalRatioData = cat(4,totalRatioData,newRatioData);
    totalTime = [totalTime newTime];
    
end

%% pca

disp('pca');

pcaInputHbO = squeeze(totalData(:,:,1,:));
pcaInputHbO = reshape(pcaInputHbO,size(totalData,1)*size(totalData,2),[]);
pcaInputHbO = pcaInputHbO';

pcaInputHbR = squeeze(totalData(:,:,2,:));
pcaInputHbR = reshape(pcaInputHbR,size(totalData,1)*size(totalData,2),[]);
pcaInputHbR = pcaInputHbR';

pcaInput = reshape(totalData,size(totalData,1)*size(totalData,2)*size(totalData,3),[]);
pcaInput = pcaInput';

[coeff, score, latent, tsquared, explained, mu] = pca(pcaInput);

%% get block avg
disp('get block average');

blockRatioData = mouse.preprocess.blockAvg(totalRatioData,totalTime,60,60*freqOut);
blockData = mouse.preprocess.blockAvg(totalData,totalTime,60,60*freqOut);
blockTime = linspace(0,60,60*freqOut+1); blockTime(end) = [];

stimTime = (mod(blockTime,60) > 5 & mod(blockTime,60) <= 10);
notStimTime = (mod(blockTime,60) > 0 & mod(blockTime,60) < 5);

stimResponse = nanmean(blockData(:,:,:,stimTime),4);
stimRatioResponse = nanmean(blockRatioData(:,:,:,stimTime),4);

%% get fluor roi response
centerCoor = [77 27];

% find coordinates above the threshold
coor = mouse.plot.circleCoor(centerCoor,10);
coor = coor(1,:)+size(blockRatioData,2)*coor(2,:);
roi = false(size(blockRatioData,1));
roi(coor) = true;

ratioDataRoiAvg = reshape(blockRatioData,size(blockRatioData,1)*size(blockRatioData,2),size(blockRatioData,3),[]);
ratioDataRoiAvg = squeeze(nanmean(ratioDataRoiAvg(roi,:,:),1)); % 2 x 60

ratioDataRoiAvgBaseline = nanmean(ratioDataRoiAvg(:,notStimTime),2);

ratioDataRoiAvg = ratioDataRoiAvg - repmat(ratioDataRoiAvgBaseline,1,size(ratioDataRoiAvg,2));

dataRoiAvg = reshape(blockData,size(blockData,1)*size(blockData,2),size(blockData,3),[]);
dataRoiAvg = squeeze(nanmean(dataRoiAvg(roi,:,:),1)); % 2 x 60

dataRoiAvgBaseline = nanmean(dataRoiAvg(:,notStimTime),2);

dataRoiAvg = dataRoiAvg - repmat(dataRoiAvgBaseline,1,size(dataRoiAvg,2));

%% plot
plotData = nanmean(ratioDataRoiAvg,3);
f1 = figure;
p1 = plot(blockTime,plotData(1,:),'b'); hold on;
p2 = plot(blockTime,plotData(2,:),'g');
p3 = plot(blockTime,plotData(3,:),'Color',[255,165,0]./255);
p4 = plot(blockTime,plotData(4,:),'r');
ylim([-5E-2 1E-1]);
yLim = ylim(gca);
% stimT = [5 10 65 70 125 130 185 190 245 250];
stimT = [5 10];
for t = stimT
    plot([t t],yLim,'m');
end
legend([p1 p2 p3 p4],["blue","yellow","orange","red"]);

plotData = nanmean(dataRoiAvg,3);
f1 = figure;
p1 = plot(blockTime,plotData(1,:),'r'); hold on;
p2 = plot(blockTime,plotData(2,:),'b');
p3 = plot(blockTime,sum(plotData,1),'k');
ylim([-3E-6 6E-6]);
yLim = ylim(gca);
% stimT = [5 10 65 70 125 130 185 190 245 250];
stimT = [5 10];
for t = stimT
    plot([t t],yLim,'m');
end
legend([p1 p2 p3],["hbO","hbR","hbT"]);

%% plot stim response

plotData = nanmean(stimRatioResponse,4);
speciesInd = {[1],[2],[3],[4]};
titleArray = ["blue","yellow","orange","red"];
% cLim = [-3 3; -3 3; -3 3; -3 3]./1E2;
cLim = [-2 2; -2 2; -2 2; -2 2]./1E2;
f2 = figure;
for i = 1:4
    subplot(3,2,i);
    imagesc(sum(plotData(:,:,speciesInd{i}),3),'AlphaData',xform_isbrain>0,cLim(i,:));
    colormap('jet'); axis(gca,'square'); xticklabels([]); yticklabels([]);
    colorbar;
    title(titleArray(i));
end

i = 5;
s4 = subplot(3,2,i);
imagesc(roi); colormap(s4, 'parula'); axis(gca,'square'); xticklabels([]); yticklabels([]); colorbar;


plotData = nanmean(stimResponse,4);
speciesInd = {[1],[2],[1 2]};
titleArray = ["hbO","hbR","hbT"];
% cLim = [-3 3; -3 3; -3 3; -3 3]./1E2;
cLim = [-2 2; -2 2; -2 2; -2 2]./1E6;
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
imagesc(roi); colormap(s4, 'parula'); axis(gca,'square'); xticklabels([]); yticklabels([]); colorbar;