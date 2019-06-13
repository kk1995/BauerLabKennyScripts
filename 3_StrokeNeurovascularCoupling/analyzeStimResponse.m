function analyzeStimResponse(excelFile,rows,varargin)
%analyzeStimResponse Analyze lag relative to seed and save the results
%   Inputs:
%       excelFile = directory to excel file to be read
%       rows = which rows in excel file will be read
%       seed (optional) = 2 x 1 vector
%       parameters (optional) = filtering and other analysis parameters
%           .lowpass = low pass filter thr (if empty, no low pass)
%           .highpass = high pass filter thr (if empty, no high pass)
%           .blockLen
%           .baselineEnd = in seconds, where the baseline ends
%           .stimEnd = in seconds, where the stim ends
%           .useGSR = boolean for using GSR
% assumes that the frame rate for the trials is the same

if numel(varargin) > 0
    seed = varargin{1};
else
    seed = [63 30];
end

if numel(varargin) > 1
    parameters = varargin{2};
else
    parameters.lowpass = 10;
    parameters.highpass = 0.01;
    parameters.blockLen = 20;
    parameters.baselineEnd = 5;
    parameters.stimEnd = 10;
    parameters.roiThr = 0.75;
    parameters.useGSR = true;
end

freqStr = [num2str(parameters.highpass),'-',num2str(parameters.lowpass)];
freqStr(strfind(freqStr,'.')) = 'p';
freqStr = string(freqStr);

postFix = strcat(freqStr, '-[', num2str(seed(1)), '-', num2str(seed(2)), ']');

if parameters.useGSR
    postFix = strcat(postFix,'-GSR');
end


roiThr = parameters.roiThr;

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

saveFileLoc = fileparts(saveFileLocs(1));
[~,excelFileName,~] = fileparts(excelFile);
analyzedFile = fullfile(saveFileLoc,...
    strcat(string(excelFileName),"-rows",num2str(min(rows)),...
    "~",num2str(max(rows)),"-stimResponse-",postFix,".mat"));

mask = [];
roiTrials = [];
response = [];

if exist(analyzedFile)
    load(analyzedFile);
else
    for trialInd = 1:trialNum
        disp(['Trial # ' num2str(trialInd)]);
        
        analyzedTrialFile = fullfile(saveFileLocs(trialInd),...
            strcat(saveFileDataNames(trialInd),"-stimResponse-",postFix,".mat"));
        
        if exist(analyzedTrialFile)
            disp('using premade file');
            load(analyzedTrialFile);
        else
            % get brain mask data
            maskTrial = load(maskFiles(trialInd));
            maskTrial = maskTrial.xform_isbrain;
            
            % get data to analyze
            hbdata = load(hbFiles(trialInd));
            fluordata = load(fluorFiles(trialInd));
            time = hbdata.rawTime; time = time - time(1) + (time(2) - time(1)); % shift time for dark frames
            fs = hbdata.fs;
            try
                xform_datahb = hbdata.data_hb;
            catch
                xform_datahb = hbdata.xform_datahb;
            end
            try
                xform_datafluorCorr = fluordata.data_fluorCorr;
            catch
                xform_datafluor = fluordata.xform_datafluor;
                xform_datafluorCorr = fluordata.xform_datafluorCorr;
            end
            
            data = cat(3,xform_datahb,xform_datafluor,xform_datafluorCorr);
            
            % filtering
            if ~isempty(parameters.highpass)
                data = highpass(data,parameters.highpass,fs);
            end
            if ~isempty(parameters.lowpass)
                if parameters.lowpass*2 < fs
                    data = lowpass(data,parameters.lowpass,fs);
                end
            end
            
            % gsr
            if parameters.useGSR
                data = mouse.process.gsr(data,maskTrial);
            end
            
            % get block avg
            [data, blockTime] = mouse.expSpecific.blockAvg(data,...
                time,parameters.blockLen,parameters.blockLen*fs);
            
            % remove baseline
            baselineInd = 1:floor(parameters.baselineEnd*fs);
            dataBaseline = nanmean(data(:,:,:,baselineInd),4);
            data = bsxfun(@minus,data,dataBaseline);
            
            % find roi
            
            % remove edges
            roiCh = 4;
            peakInd = round(parameters.stimEnd*fs);
            peakResponse = squeeze(data(:,:,roiCh,peakInd));
            peakResponse(peakResponse < 0) = nan;
            
            if ~exist('validROI')
                disp('draw a contour of valid region for the roi to be in');
                polyInput = (peakResponse - min(peakResponse(:)))...
                    ./range(peakResponse(:));
                polyFig = figure;
                validROI = roipoly(polyInput);
                close(polyFig);
            end
            roi = mouse.expSpecific.getROI(peakResponse,seed,...
                roiThr,128,validROI);
            
            % get roi average response
            ySize = size(data,1); xSize = size(data,2);
            data = reshape(data,ySize*xSize,size(data,3),[]);
            dataROIResponse = squeeze(nanmean(data(roi,:,:),1));
            
            % save lag data
            save(analyzedTrialFile,'blockTime','roi','validROI','dataROIResponse',...
                'maskTrial','-v7.3');
        end
        
        % make plots
        trialFigFile = fullfile(saveFileLocs(trialInd),...
            strcat(saveFileDataNames(trialInd),"-stimResponse-",postFix,".fig"));
        trialFig = figure('Position',[100 100 1200 400]);
        subplot('Position',[0.05 0.1 0.3 0.8]);
        imagesc(roi + validROI,[0 2]); axis(gca,'square');
        set(gca,'XTick',[]); set(gca,'YTick',[]);
        subplot('Position',[0.4 0.1 0.5 0.7]);
        plot(blockTime,1E3*dataROIResponse(1,:),'r','LineWidth',2); hold on;
        plot(blockTime,1E3*dataROIResponse(2,:),'b','LineWidth',2);
        plot(blockTime,1E3*sum(dataROIResponse(1:2,:),1),'k','LineWidth',2);
        plot(blockTime,dataROIResponse(3,:),'g','LineWidth',2);
        plot(blockTime,dataROIResponse(4,:),'m','LineWidth',2);
        legend({'HbO','HbR','HbT','Fluor','Fluor corr'});
%         subplot('Position',[0.4 0.1 0.5 0.3]);
%         plot(blockTime,xform_datafluorCorrROIResponse,'m','LineWidth',2);
%         legend({'Fluor corrected'});
        savefig(trialFig,trialFigFile);
        close(trialFig);
        
        % concatenate over trials
        response = cat(3,response,dataROIResponse);
        roiTrials = cat(3,roiTrials,roi);
        mask = cat(3,mask,maskTrial);
    end
    
    % save lag data
    save(analyzedFile,'blockTime','mask','roiTrials','response',...
        '-v7.3');
end

wlFile = 'L:\ProcessedData\wl.mat';
load(wlFile);

alpha = mean(roiTrials,3) > 0;

response(isnan(response)) = 0;
response = nanmean(response,3);

% make plots
saveFileLoc = fileparts(saveFileLocs(1));
[~,excelFileName,~] = fileparts(excelFile);

figFile = fullfile(saveFileLoc,...
    strcat(string(excelFileName),"-rows",num2str(min(rows)),...
    "~",num2str(max(rows)),"-stimResponse-",postFix,".fig"));
fig1 = figure('Position',[100 100 900 400]);
% subplot('Position',[0.05 0.1 0.3 0.8]);
% imagesc(100*mean(roiTrials,3),'AlphaData',alpha,[0 100]); axis(gca,'square');
% set(gca,'XTick',[]); set(gca,'YTick',[]);
subplot('Position',[0.4 0.2 0.5 0.7]);
plot(blockTime,1E3*response(1,:),'r','LineWidth',2); hold on;
plot(blockTime,1E3*response(2,:),'b','LineWidth',2);
plot(blockTime,1E3*sum(response(1:2,:),1),'k','LineWidth',2);
plot(blockTime,response(3,:),'g','LineWidth',2);
plot(blockTime,response(4,:),'m','LineWidth',2);
legend({'HbO','HbR','HbT','Fluor','Fluor corr'});
xlabel('time (s)');
ylabel('concentration (mM, ratiometric)');
% legend({'HbO','HbR','HbT','Fluor'});
set(gca,'FontSize',18);
savefig(fig1,figFile);
close(fig1);

end

