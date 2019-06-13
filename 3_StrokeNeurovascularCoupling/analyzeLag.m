function analyzeLag(excelFile,rows,varargin)
%analyzeLag Analyze dot lag and save the results
%   Inputs:
%       parameters = filtering and other analysis parameters
%           .lowpass = low pass filter thr (if empty, no low pass)
%           .highpass = high pass filter thr (if empty, no high pass)

if numel(varargin) > 0
    parameters = varargin{1};
else
    parameters.lowpass = 0.08; %1/30 Hz
    parameters.highpass = 0.01;
    parameters.startTime = 0;
    parameters.useGSR = false;
end

if parameters.startTime == 0
    freqStr = [num2str(parameters.highpass),'-',num2str(parameters.lowpass)];
else
    freqStr = [num2str(parameters.highpass),'-',num2str(parameters.lowpass),'-startT-',num2str(parameters.startTime)];
end
freqStr(strfind(freqStr,'.')) = 'p';
freqStr = string(freqStr);

postFix = freqStr;
if parameters.useGSR
    postFix = strcat("GSR-",freqStr);
end

if contains(excelFile,'stim')
    tLim = [-1.5 1.5];
else
    tLim = [-1 1];
end

rLim = [0 1.5];
tLim = [0 2];

edgeLen = 3;
% tZone = 2;
tZone = 4;
corrThr = 0.3;

%% import packages

import mouse.*

%% read the excel file to get the list of file names

runsInfo = parseTiffRuns(excelFile,rows);
if isempty(runsInfo)
    runsInfo = parseDatRuns(excelFile,rows);
end
runNum = numel(runsInfo);

%% load each file and find block response

saveFileLoc = fileparts(runsInfo(1).saveFolder);
[~,excelFileName,~] = fileparts(excelFile);
lagFile = fullfile(saveFileLoc,...
    strcat(string(excelFileName),"-rows",num2str(min(rows)),...
    "~",num2str(max(rows)),"-dotLagHbTG6-",postFix,".mat"));
lagFigFile = fullfile(saveFileLoc,...
    strcat(string(excelFileName),"-rows",num2str(min(rows)),...
    "~",num2str(max(rows)),"-dotLagHbTG6-",postFix,".fig"));

lagTime = [];
lagAmp = [];
mask = [];

if exist(lagFile)
    load(lagFile);
else
    for trialInd = 1:runNum
        disp(['Trial # ' num2str(trialInd)]);
        
        dotLagFile = strcat(runsInfo(trialInd).saveFilePrefix,"-dotLagHbTG6-",postFix,".mat");
        dotLagFigFile = strcat(runsInfo(trialInd).saveFilePrefix,"-dotLagHbTG6-",postFix,".fig");
        
        maskTrial = load(runsInfo(trialInd).saveMaskFile);
        maskTrial = maskTrial.xform_isbrain;
        if exist(dotLagFile)
            load(dotLagFile);
        else
            
            hbdata = load(runsInfo(trialInd).saveHbFile);
            fluordata = load(runsInfo(trialInd).saveFluorFile);
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
            
            fluor = mouse.freq.resampledata(xform_datafluorCorr,fluordata.fluorTime,hbdata.hbTime);
            xform_datafluorCorr = fluor;
            time = hbdata.hbTime;
            fs = 1/(time(2)-time(1));
            
            % filtering
            if ~isempty(parameters.highpass)
                xform_datahb = highpass(xform_datahb,parameters.highpass,fs);
            end
            if ~isempty(parameters.lowpass) && parameters.lowpass < fs/2
                xform_datahb = lowpass(xform_datahb,parameters.lowpass,fs);
            end
            
            if ~isempty(parameters.highpass)
                xform_datafluorCorr = highpass(xform_datafluorCorr,parameters.highpass,fs);
            end
            if ~isempty(parameters.lowpass) && parameters.lowpass < fs/2
                xform_datafluorCorr = lowpass(xform_datafluorCorr,parameters.lowpass,fs);
            end
            
            %gsr
            if parameters.useGSR
                xform_datahb = mouse.process.gsr(xform_datahb,maskTrial);
                xform_datafluorCorr = mouse.process.gsr(xform_datafluorCorr,maskTrial);
            end
            
            data1 = squeeze(sum(xform_datahb,3));
            data1 = data1(:,:,time >= parameters.startTime);
            data2 = squeeze(xform_datafluorCorr);
            data2 = data2(:,:,time >= parameters.startTime);
            [lagTimeTrial,lagAmpTrial,covResult] = mouse.conn.dotLag(data1,data2,edgeLen,round(tZone*fs),corrThr);
            lagTimeTrial = lagTimeTrial./fs;
            
            % save lag data
            save(dotLagFile,'lagTimeTrial','lagAmpTrial','tZone','corrThr','edgeLen','covResult');
        end
        
        % plot lag
        dotLagFig = figure('Position',[100 100 900 400]);
        p = panel();
        p.pack();
        p(1).pack(1,2);
        p(1,1,1).select(); imagesc(lagTimeTrial,'AlphaData',maskTrial,tLim); axis(gca,'square');
        xlim([1 size(lagTimeTrial,1)]); ylim([1 size(lagTimeTrial,2)]);
        set(gca,'ydir','reverse'); colorbar; colormap('jet');
        set(gca,'XTick',[]); set(gca,'YTick',[]); title('Lag Time (s)');
        p(1,1,2).select(); imagesc(lagAmpTrial,'AlphaData',maskTrial,rLim); axis(gca,'square');
        xlim([1 size(lagAmpTrial,1)]); ylim([1 size(lagAmpTrial,2)]);
        set(gca,'ydir','reverse'); colorbar; colormap('jet');
        set(gca,'XTick',[]); set(gca,'YTick',[]); title('Lag Amp');
        
        % save lag figure
        savefig(dotLagFig,dotLagFigFile);
        close(dotLagFig);
        
        lagTime = cat(3,lagTime,lagTimeTrial);
        lagAmp = cat(3,lagAmp,lagAmpTrial);
        mask = cat(3,mask,maskTrial);
    end
    % save lag data
    save(lagFile,'lagTime','lagAmp','mask','tZone','corrThr','edgeLen');
end

%% plot average across trials

lagAmp = atanh(lagAmp); lagAmp = real(lagAmp);

load('L:\ProcessedData\noVasculatureMask.mat');
wlData = load('L:\ProcessedData\wl.mat');
load('D:\ProcessedData\zachInfarctROI.mat');

alphaData = nanmean(mask,3);
alphaData = alphaData >= 0.5;

alphaData = alphaData & (leftMask | rightMask);

% roi time course
dotLagFig = figure('Position',[100 100 400 650]);
p = panel();
p.margintop = 10;
p.marginright = 10;
p.pack();
p(1).pack(2,1);
p(1,1,1).select();
set(gca,'Color','k');
set(gca,'FontSize',16);
image(wlData.xform_wl,'AlphaData',wlData.xform_isbrain);
hold on;
goodPix = sum(lagAmp > 0.5943,3)./sum(mask,3) >= 0;
% goodPix = sum(lagAmp > 0.5943,3)./sum(mask,3) > 0.5;
imagesc(nanmean(lagTime,3),'AlphaData',alphaData & goodPix,tLim); axis(gca,'square');
xlim([1 size(lagTime,1)]); ylim([1 size(lagTime,2)]);
set(gca,'ydir','reverse'); colorbar; colormap('jet');
set(gca,'XTick',[]); set(gca,'YTick',[]);
P = mask2poly(infarctroi);
plot(P.X,P.Y,'k','LineWidth',3);
hold off;

p(1,2,1).select();
set(gca,'Color','k');
set(gca,'FontSize',16);
image(wlData.xform_wl,'AlphaData',wlData.xform_isbrain);
hold on;
imagesc(nanmean(lagAmp,3),'AlphaData',alphaData,rLim); axis(gca,'square');
xlim([1 size(lagAmp,1)]); ylim([1 size(lagAmp,2)]);
set(gca,'ydir','reverse'); colorbar; colormap('jet');
set(gca,'XTick',[]); set(gca,'YTick',[]);
P = mask2poly(infarctroi);
plot(P.X,P.Y,'k','LineWidth',3);
hold off;

% save lag figure
savefig(dotLagFig,lagFigFile);
close(dotLagFig);

end

