function pcaAndPlotMulti(excelFile,rows,varargin)
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

%% load each file and find block response

coeffDist = [];
mask = [];
roi = [];
roiData = [];
score = [];

for trialInd = 1:trialNum
    disp(['Trial # ' num2str(trialInd) '/' num2str(trialNum)]);
    
    saveFileLoc = saveFileLocs(trialInd);
    saveFileMaskName = saveFileMaskNames(trialInd);
    saveFileDataName = saveFileDataNames(trialInd);
    
    maskFile = string(fullfile(saveFileLoc,...
        strcat(saveFileMaskName,"-LandmarksandMask.mat")));
    
    fluorFile = string(fullfile(saveFileLoc,...
        strcat(saveFileDataName,"-dataFluor.mat")));
    
    pcaFile = fullfile(saveFileLoc,...
        strcat(saveFileDataName,"-pcaResult.mat"));
    
    load(maskFile);
    maskTrial = xform_isbrain;
    
    fluordata = load(fluorFile);
    try
        xform_datafluorCorr = fluordata.data_fluorCorr;
    catch
        xform_datafluorCorr = fluordata.xform_datafluorCorr;
    end
    
    time = fluordata.rawTime;
    fs = fluordata.sessionInfo.freqout;
    
    % filtering
    if ~isempty(parameters.highpass)
        xform_datafluorCorr = highpass(xform_datafluorCorr,parameters.highpass,fs);
    end
    if ~isempty(parameters.lowpass)
        xform_datafluorCorr = lowpass(xform_datafluorCorr,parameters.lowpass,fs);
    end
    
    totalData = xform_datafluorCorr;
    
    if exist(pcaFile)
        disp('pca file already exists');
        pcaTrialData = load(pcaFile);
        coeffTrial = pcaTrialData.coeff;
        coeffDistTrial = pcaTrialData.coeffDist;
        scoreTrial = pcaTrialData.score;
    else
        disp('running pca and saving results');
        tic;
        [coeffTrial, coeffDistTrial, scoreTrial] = pcaAndPlot(totalData,maskTrial,pcaFile);
        disp(['took ' num2str(toc) 'seconds']);
    end
    
    % pca figure
    disp('pca figure');
    pcCoeffFig = figure('Position',[200 200 800 250]);
    for pcInd = 1:3
        subplot(1,3,pcInd);
        brainDist = reshape(coeffDistTrial(:,pcInd),size(maskTrial,2),size(maskTrial,1));
        imagesc(brainDist); axis(gca,'square');
        set(gca,'XTick',[]); set(gca,'YTick',[]); colorbar;
        title(['PC #' num2str(pcInd)]);
    end
    
    % pca recon data
    centerCoor = blockDesign.expectedLoc;
    candidateCoor = mouse.plot.circleCoor(centerCoor,5);
    candidateCoor = candidateCoor(1,:) + 128*(candidateCoor(2,:)-1);
    
    roiTrial = false(128);
    roiTrial(candidateCoor) = true;
    
    disp('pca figure');
    pcCoeffFig2 = figure('Position',[200 200 800 600]);
    p = panel();
    p.pack({1},{1/3 []});
    p(1,1).select();
    imagesc(roiTrial); axis(gca,'square'); xlim([1 128]); ylim([1 128]);
    set(gca,'XTick',[]); set(gca,'YTick',[]); set(gca,'ydir','reverse')
    p(1,2).pack({1/3 1/3 []});
    roiDataTrials = [];
    for pcInd = 1:3
        p(1,2,pcInd).select();
        pcData = nan(128*128,size(scoreTrial,1));
        pcData(maskTrial(:),:) = coeffTrial(:,pcInd)*scoreTrial(:,pcInd)';
        
        roiDataTrial = pcData(roiTrial,:);
        roiDataTrial = mean(roiDataTrial,1);
        plot(time,roiDataTrial);
        title(['PC #' num2str(pcInd)]);
        roiDataTrials = [roiDataTrials; roiDataTrial];
    end
    
    % save roi response
    pcCoeffFigFile = fullfile(saveFileLoc,...
        strcat(saveFileDataName,"-pcCoeff.fig"));
    savefig(pcCoeffFig,pcCoeffFigFile);
    close(pcCoeffFig);
    
    pcCoeffFigFile2 = fullfile(saveFileLoc,...
        strcat(saveFileDataName,"-pcRoiTimeCourse.fig"));
    savefig(pcCoeffFig2,pcCoeffFigFile2);
    close(pcCoeffFig2);
    
    % concat across trials
    mask = cat(3,mask,maskTrial);
    coeffDist = cat(3,coeffDist,coeffDistTrial);
    roiData = cat(3,roiData,roiDataTrials);
    roi = cat(3,roi,roiTrial);
end

%% plot average across trials

saveFileLoc = fileparts(saveFileLocs(1));
[~,excelFileName,~] = fileparts(excelFile);

% pca figure
coeffDistAvg = nanmean(coeffDist,3);
maskAvg = nanmean(mask,3);
pcCoeffFig = figure('Position',[200 200 800 250]);
for pcInd = 1:3
    subplot(1,3,pcInd);
    brainDist = reshape(coeffDistAvg(:,pcInd),size(xform_isbrain,2),size(xform_isbrain,1));
    imagesc(brainDist,'AlphaData',maskAvg); axis(gca,'square'); colorbar;
    title(['PC #' num2str(pcInd)]);
end

pcCoeffFig2 = figure('Position',[200 200 800 600]);
roiAvg = nanmean(roi,3);
roiDataAvg = mean(roiData,3);
p = panel();
p.pack({1},{1/3 []});
p(1,1).select();
imagesc(roiAvg); axis(gca,'square'); xlim([1 128]); ylim([1 128]);
set(gca,'XTick',[]); set(gca,'YTick',[]); set(gca,'ydir','reverse')
p(1,2).pack({1/3 1/3 []});
for pcInd = 1:3
    p(1,2,pcInd).select();
    pcData = nan(128*128,size(scoreTrial,1));
    plot(time,roiDataAvg(pcInd,:));
    set(gca,'XTick',[]); set(gca,'YTick',[]); colorbar;
    title(['PC #' num2str(pcInd)]);
end

% save roi response
pcCoeffFigFile = fullfile(saveFileLoc,...
    strcat(string(excelFileName),"-rows",num2str(min(rows)),...
    "~",num2str(max(rows)),"-pcCoeff.fig"));
savefig(pcCoeffFig,pcCoeffFigFile);
close(pcCoeffFig);

pcCoeffFigFile2 = fullfile(saveFileLoc,...
    strcat(string(excelFileName),"-rows",num2str(min(rows)),...
    "~",num2str(max(rows)),"-pcRoiTimeCourse.fig"));
savefig(pcCoeffFig2,pcCoeffFigFile2);
close(pcCoeffFig2);

end

