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
end

if parameters.startTime == 0
    freqStr = [num2str(parameters.highpass),'-',num2str(parameters.lowpass)];
else
    freqStr = [num2str(parameters.highpass),'-',num2str(parameters.lowpass),'-startT-',num2str(parameters.startTime)];
end
freqStr(strfind(freqStr,'.')) = 'p';
freqStr = string(freqStr);

if contains(excelFile,'stim')
    tLim = 1.5;
else
    tLim = 1;
end

edgeLen = 3;
tZone = 2;
corrThr = 0.3;

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
lagFile = fullfile(saveFileLoc,...
    strcat(string(excelFileName),"-rows",num2str(min(rows)),...
    "~",num2str(max(rows)),"-dotLagHbTG6-",freqStr,".mat"));

lagTime = [];
lagAmp = [];
mask = [];

if exist(lagFile)
    load(lagFile);
else
    for trialInd = 1:trialNum
        disp(['Trial # ' num2str(trialInd)]);
        
        dotLagFile = fullfile(saveFileLocs(trialInd),...
            strcat(saveFileDataNames(trialInd),"-dotLagHbTG6-",freqStr,".mat"));
        
        maskTrial = load(maskFiles(trialInd));
        maskTrial = maskTrial.xform_isbrain;
        
        if exist(dotLagFile)
            load(dotLagFile);
        else
            
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
            
            fs = fluordata.readerInfo.FreqOut;
            time = fluordata.rawTime;
            
            % filtering
            if ~isempty(parameters.highpass)
                xform_datahb = highpass(xform_datahb,parameters.highpass,fs);
            end
            if ~isempty(parameters.lowpass)
                xform_datahb = lowpass(xform_datahb,parameters.lowpass,fs);
            end
            
            if ~isempty(parameters.highpass)
                xform_datafluorCorr = highpass(xform_datafluorCorr,parameters.highpass,fs);
            end
            if ~isempty(parameters.lowpass)
                xform_datafluorCorr = lowpass(xform_datafluorCorr,parameters.lowpass,fs);
            end
            
            data1 = squeeze(sum(xform_datahb,3));
            data1 = data1(:,:,time >= parameters.startTime);
            data2 = squeeze(xform_datafluorCorr);
            data2 = data2(:,:,time >= parameters.startTime);
            [lagTimeTrial,lagAmpTrial,covResult] = mouse.conn.dotLag(data1,data2,edgeLen,round(tZone*fs),corrThr);
            lagTimeTrial = lagTimeTrial./fs;
            
            % save lag data
            save(dotLagFile,'lagTimeTrial','lagAmpTrial','tZone','corrThr','edgeLen');
        end
        
        % plot lag
        dotLagFig = figure('Position',[100 100 900 400]);
        p = panel();
        p.pack();
        p(1).pack(1,2);
        p(1,1,1).select(); imagesc(lagTimeTrial,'AlphaData',maskTrial,[0 tLim]); axis(gca,'square');
        xlim([1 size(lagTimeTrial,1)]); ylim([1 size(lagTimeTrial,2)]);
        set(gca,'ydir','reverse'); colorbar; colormap('jet');
        set(gca,'XTick',[]); set(gca,'YTick',[]); title('Lag Time (s)');
        p(1,1,2).select(); imagesc(lagAmpTrial,'AlphaData',maskTrial,[0.3 1]); axis(gca,'square');
        xlim([1 size(lagAmpTrial,1)]); ylim([1 size(lagAmpTrial,2)]);
        set(gca,'ydir','reverse'); colorbar; colormap('jet');
        set(gca,'XTick',[]); set(gca,'YTick',[]); title('Lag Amp');
        
        % save lag figure
        dotLagFigFile = fullfile(saveFileLocs(trialInd),...
            strcat(saveFileDataNames(trialInd),"-dotLagHbTG6-",freqStr,".fig"));
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

saveFileLoc = fileparts(saveFileLocs(1));
[~,excelFileName,~] = fileparts(excelFile);
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
goodPix = sum(lagAmp > 0.5943,3)./sum(mask,3) > 0.5;
imagesc(nanmean(lagTime,3),'AlphaData',alphaData & goodPix,[0 tLim]); axis(gca,'square');
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
imagesc(nanmean(lagAmp,3),'AlphaData',alphaData,[0.3 2]); axis(gca,'square');
xlim([1 size(lagAmp,1)]); ylim([1 size(lagAmp,2)]);
set(gca,'ydir','reverse'); colorbar; colormap('jet');
set(gca,'XTick',[]); set(gca,'YTick',[]);
P = mask2poly(infarctroi);
plot(P.X,P.Y,'k','LineWidth',3);
hold off;

% save lag figure
dotLagFigFile = fullfile(saveFileLoc,...
    strcat(string(excelFileName),"-rows",num2str(min(rows)),...
    "~",num2str(max(rows)),"-dotLagHbTG6-",freqStr,".fig"));
savefig(dotLagFig,dotLagFigFile);
close(dotLagFig);

end

