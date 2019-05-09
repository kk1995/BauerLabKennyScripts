function analyzePower(excelFile,rows,varargin)
%analyzeLag Analyze lag and save the results
%   Inputs:
%       parameters = filtering and other analysis parameters
%           .lowpass = low pass filter thr (if empty, no low pass)
%           .highpass = high pass filter thr (if empty, no high pass)

if numel(varargin) > 0
    parameters = varargin{1};
else
    parameters.lowpass = 0.08; %1/30 Hz
    parameters.highpass = 0.01;
    parameters.useGsr = false;
end

freqStr = [num2str(parameters.highpass),'-',num2str(parameters.lowpass)];
freqStr(strfind(freqStr,'.')) = 'p';
freqStr = string(freqStr);

if parameters.lowpass == 0.08 && parameters.highpass == 0.01
    cLimHbT = [-11.3 -10.2];
    cLimFluor = [-4.5 -3.0];
end
if parameters.lowpass == 4 && parameters.highpass == 0.5
    cLimHbT = [-14 -13];
    cLimFluor = [-6.8 -5.8];
end
if parameters.lowpass == 4 && parameters.highpass == 1
    cLimHbT = [-14.3 -13.3];
    cLimFluor = [-6.8 -5.8];
end

nfft = 512;

useGsr = parameters.useGsr;

if useGsr
    gsrStr = "-GSR";
else
    gsrStr = "-noGSR";
end

if useGsr
    cLimHbT = cLimHbT - 0.3;
    cLimFluor = cLimFluor - 0.3;
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

saveFileLoc = fileparts(saveFileLocs(1));
[~,excelFileName,~] = fileparts(excelFile);
% psdFile = fullfile(saveFileLoc,...
%     strcat(string(excelFileName),"-rows",num2str(min(rows)),...
%     "~",num2str(max(rows)),"-psdHbTG6-",freqStr,".mat"));
psdFile = fullfile(saveFileLoc,...
    strcat(string(excelFileName),"-rows",num2str(min(rows)),...
    "~",num2str(max(rows)),"-psdHbTG6",gsrStr,".mat"));

spectraHbT = [];
spectraFluor = [];
mask = [];

if exist(psdFile)
    load(psdFile);
else
    for trialInd = 1:trialNum
        disp(['Trial # ' num2str(trialInd)]);
        
        psdFileTrial = fullfile(saveFileLocs(trialInd),...
            strcat(saveFileDataNames(trialInd),"-psdHbTG6",gsrStr,".mat"));
        
        if exist(psdFileTrial)
            load(psdFileTrial);
        else
            maskTrial = load(maskFiles(trialInd));
            maskTrial = maskTrial.xform_isbrain;
            
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
            
            if useGsr
                % gsr
                xform_datahb = mouse.process.gsr(xform_datahb,maskTrial);
                xform_datafluorCorr = mouse.process.gsr(xform_datafluorCorr,maskTrial);
            end
            xform_datafluorCorr = squeeze(xform_datafluorCorr);
            xform_datahbT = squeeze(sum(xform_datahb,3));
            
            [spectraHbTTrial,~] = pwelch(reshape(xform_datahbT,[],size(xform_datahbT,3))',[],[],nfft,fs);
            spectraHbTTrial = reshape(spectraHbTTrial',128,128,[]);
            
            [spectraFluorTrial,freq] = pwelch(reshape(xform_datafluorCorr,[],size(xform_datafluorCorr,3))',[],[],nfft,fs);
            spectraFluorTrial = reshape(spectraFluorTrial',128,128,[]);
            
            spectraHbTTrial = real(spectraHbTTrial);
            spectraFluorTrial = real(spectraFluorTrial);
            % save psd data
            save(psdFileTrial,'maskTrial','spectraHbTTrial','spectraFluorTrial','nfft','fs','freq');
        end
                
        % make plot image
        hbtPower = mean(spectraHbTTrial(:,:,freq > parameters.highpass & freq < parameters.lowpass),3);
        fluorPower = mean(spectraFluorTrial(:,:,freq > parameters.highpass & freq < parameters.lowpass),3);
        
        % plot power
        psdFig = figure('Position',[100 100 900 400]);
        p = panel();
        p.pack();
        p(1).pack(1,2);
        p(1,1,1).select(); imagesc(log10(hbtPower),'AlphaData',maskTrial,cLimHbT); axis(gca,'square');
        xlim([1 size(hbtPower,1)]); ylim([1 size(hbtPower,2)]);
        set(gca,'ydir','reverse'); colorbar; colormap('jet');
        set(gca,'XTick',[]); set(gca,'YTick',[]); title('HbT power');
        p(1,1,2).select(); imagesc(log10(fluorPower),'AlphaData',maskTrial,cLimFluor); axis(gca,'square');
        xlim([1 size(fluorPower,1)]); ylim([1 size(fluorPower,2)]);
        set(gca,'ydir','reverse'); colorbar; colormap('jet');
        set(gca,'XTick',[]); set(gca,'YTick',[]); title('Fluor power');
        
        % save lag figure
        psdFigFile = fullfile(saveFileLocs(trialInd),...
            strcat(saveFileDataNames(trialInd),"-psdHbTG6-",freqStr,gsrStr,".fig"));
        savefig(psdFig,psdFigFile);
        close(psdFig);
        
        mask = cat(3,mask,maskTrial);
        spectraHbT = cat(4,spectraHbT,spectraHbTTrial);
        spectraFluor = cat(4,spectraFluor,spectraFluorTrial);
    end
    
    spectraHbT = mean(spectraHbT,4);
    spectraFluor = mean(spectraFluor,4);
    
    % save lag data
    save(psdFile,'spectraHbT','spectraFluor','mask','nfft','fs','freq');
end

%% plot average across trials

load('L:\ProcessedData\noVasculatureMask.mat');
wlData = load('L:\ProcessedData\wl.mat');
load('D:\ProcessedData\zachInfarctROI.mat');

hbtPower = squeeze(mean(spectraHbT(:,:,freq > parameters.highpass & freq < parameters.lowpass,:),3));
fluorPower = squeeze(mean(spectraFluor(:,:,freq > parameters.highpass & freq < parameters.lowpass,:),3));

saveFileLoc = fileparts(saveFileLocs(1));
[~,excelFileName,~] = fileparts(excelFile);
alphaData = nanmean(mask,3);
alphaData = alphaData >= 0.9;

alphaData = alphaData & (leftMask | rightMask);

% roi time course
% psdFig = figure('Position',[100 100 900 400]);
psdFig = figure('Position',[100 100 400 650]);
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
imagesc(log10(hbtPower),'AlphaData',alphaData,cLimHbT); axis(gca,'square');
xlim([1 size(hbtPower,1)]); ylim([1 size(hbtPower,2)]);
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
imagesc(log10(fluorPower),'AlphaData',alphaData,cLimFluor); axis(gca,'square');
xlim([1 size(fluorPower,1)]); ylim([1 size(fluorPower,2)]);
set(gca,'ydir','reverse'); colorbar; colormap('jet');
set(gca,'XTick',[]); set(gca,'YTick',[]);
P = mask2poly(infarctroi);
plot(P.X,P.Y,'k','LineWidth',3);
hold off;

% save lag figure
psdFigFile = fullfile(saveFileLoc,...
    strcat(string(excelFileName),"-rows",num2str(min(rows)),...
    "~",num2str(max(rows)),"-psdHbTG6-",freqStr,gsrStr,".fig"));
savefig(psdFig,psdFigFile);
close(psdFig);

end

