% this script is a wrapper around gcampImaging.m function that shows how
% the function should be used. As shown, you state which tiff file to run,
% then get system and session information either via the functions
% sysInfo.m and session2procInfo.m or manual addition. Run the
% gcampImaging.m function afterwards and you are good to go!

%% import packages

import mouse.*

%% initialize
dataRoiAvg = [];
stimResponse = [];

filePrefix = "\\10.39.168.176\RawData_East3410\181004\181004-D16M2-stim";
saveFilePrefix = "D:\data\none\181004-D16M2-stim";
figFilePrefix = "D:\figures\171128-Mouse2-stim";

for run = 1:3
    disp(['run # ' num2str(run)]);
    fileName = strcat(filePrefix,num2str(run),".tif");
    saveFileName = strcat(saveFilePrefix,num2str(run),"-LEDIntensity.mat");
    maskFileName = 'D:\data\181004-D16M2-LandmarksandMask.mat';
    
    maskData = load(maskFileName);
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
    sessionInfo.detrendTemporally = false;
    sessionInfo.hbSpecies = 1:4;
    sessionInfo.probeSpecies = [];
    sessionInfo.framerate = 20;
    sessionInfo.freqout = 8;
    sessionInfo.lowpass = sessionInfo.freqout./2-0.1;
    
    darkFrameInd = [];

    %% get raw

    if exist(saveFileName)
        load(saveFileName);
        xform_isbrain = preprocess.affineTransform(isbrain,affineMarkers);
    else
        speciesNum = systemInfo.numLEDs+1;
        disp('loading files');
        [raw,time] = read.readRaw(fileName,speciesNum,systemInfo.readFcn,...
            sessionInfo.framerate,sessionInfo.freqout);
        raw = raw(:,:,1:4,:);
        
        isbrain = logical(maskData.isbrain);
        affineMarkers = maskData.I;
        
        %% preprocess
        disp('preprocess');
        [time,data] = fluor.preprocess(time,raw,systemInfo,sessionInfo,affineMarkers,'darkFrameInd',darkFrameInd);
        xform_isbrain = preprocess.affineTransform(isbrain,affineMarkers);
        
        data = logmean(data);
        
        save(saveFileName,'time','data','isbrain','affineMarkers','-v7.3');
    end
    %% get block avg
    disp('get block average');
    freqOut = sessionInfo.freqout;
    data = mouse.preprocess.blockAvg(data,time,60,60*freqOut);
    blockTime = linspace(0,60,60*freqOut+1); blockTime(end) = [];
    
    stimTime = (blockTime > 5 & blockTime <= 10);
    dataStim = nanmean(data(:,:,:,stimTime),4);
    stimResponseRun = dataStim;
    
    %% get fluor roi response
    centerCoor = [77 27];
    
    % find coordinates above the threshold
    coor = mouse.plot.circleCoor(centerCoor,10);
    coor = coor(1,:)+size(data,2)*coor(2,:);
    roi = false(size(data,1));
    roi(coor) = true;
    
    dataRoiAvgRun = reshape(data,size(data,1)*size(data,2),size(data,3),[]);
    dataRoiAvgRun = squeeze(nanmean(dataRoiAvgRun(roi,:,:),1)); % 2 x 60
    
    xform_hbRoiAvgBaseline = nanmean(dataRoiAvgRun(:,1:floor(5*freqOut)),2);
    
    dataRoiAvgRun = dataRoiAvgRun - repmat(xform_hbRoiAvgBaseline,1,size(dataRoiAvgRun,2));

    dataRoiAvg = cat(3,dataRoiAvg,dataRoiAvgRun);
    stimResponse = cat(4,stimResponse,stimResponseRun);
end

%% plot
plotData = nanmean(dataRoiAvg,3);
f1 = figure;
p1 = plot(blockTime,plotData(1,:),'b'); hold on;
p2 = plot(blockTime,plotData(2,:),'g');
p3 = plot(blockTime,plotData(3,:),'Color',[255,165,0]./255);
p4 = plot(blockTime,plotData(4,:),'r');
ylim([-5E-2 1E-1]);
yLim = ylim(gca);
stimT = [5 10];
for t = stimT
    plot([t t],yLim,'m');
end
legend([p1 p2 p3 p4],["blue","yellow","orange","red"]);

%% plot stim response

plotData = nanmean(stimResponse,4);
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
