% fileInd = 15:28;
fileInd = [1:14 29:56];
fileNumel = numel(fileInd);
excelFile = fullfile('D:\data','Stroke Study 1 sorted.xlsx');
contourFile = 'D:\data\zachRosenthal\contour.mat';
saveDir = 'D:\data\zachRosenthal\_infarct\latest';
load(contourFile);

sR = 16.81;
fRange = [0.009 0.5; 0.5 5];
tBoundary = [7 2];
useGsr = false;
corrThr = 0.3;

% run save infarct data for each file
for mouse = 1:fileNumel
    tMouse = tic;
    disp(['File # ' num2str(mouse) '/' num2str(fileNumel)]);
    
    if fileInd(mouse) <= 14
        week = 'baseline';
    elseif fileInd(mouse) <= 28
        week = 'week1';
    elseif fileInd(mouse) <= 42
        week = 'week4';
    else
        week = 'week8';
    end
    
    [~, ~, raw]=xlsread(excelFile,1, ['A',num2str(fileInd(mouse)),':F',num2str(fileInd(mouse))]);
    mouseName = raw{2};
    dataDir = raw{3};
    dataDate = num2str(raw{1});
    
    % make str array of run files
    runDir = [];
    for run = 1:3
        fileName = [dataDate '-' mouseName '-dataGCaMP-fc' num2str(run) '.mat'];
        runDir = [runDir; string(fullfile(dataDir,dataDate,fileName))];
    end
    
    
    for run = 1:numel(runDir)
        disp(['  Run # ' num2str(run)]);
        
        % load data
        load(runDir(run),'oxy','deoxy','gcamp6corr','xform_mask');
        maskRun = logical(xform_mask);
        
        % make data variable
        hbO = reshape(oxy,128,128,1,[]); clear oxy;
        hbR = reshape(deoxy,128,128,1,[]); clear deoxy;
        dataRun = cat(3,hbO,hbR);
        hbT = hbO+hbR;
        dataRun = cat(3,dataRun,hbT); clear hbO; clear hbR; clear hbT;
        gcamp = reshape(gcamp6corr,128,128,1,[]); clear gcamp6corr;
        dataRun = cat(3,dataRun,gcamp); clear gcamp;
        fNum = size(fRange,1);
        gs = cell(fNum,1); rawL = cell(fNum,1); rawR = cell(fNum,1);
        covResultBilat = cell(fNum,1); covResultGs = cell(fNum,1); lagTimeBilat = cell(fNum,1);
        contourMaskMirror = fliplr(contourMask);
        dataSize = size(dataRun);
        for freqInd = 1:fNum
            filteredData = filterData(dataRun,fRange(freqInd,1),fRange(freqInd,2),sR);
            [gs{freqInd}, rawL{freqInd}, rawR{freqInd}] = infarctData(filteredData,maskRun,contourMask);
            
            filteredData = reshape(filteredData,prod(dataSize(1:2)),dataSize(3),dataSize(4));
            filteredData(~contourMask(:) & ~contourMaskMirror(:),:,:) = nan;
            filteredData = reshape(filteredData,dataSize);
            
            % bilateral lag
            [lagTimeBilatFreq, ~,covResultBilatFreq] = bilateralLagFile(filteredData,sR,[],tBoundary(freqInd),useGsr,maskRun,corrThr);
            lagTimeBilatFreq = reshape(lagTimeBilatFreq,size(lagTimeBilatFreq,1)*size(lagTimeBilatFreq,2),...
                size(lagTimeBilatFreq,3),size(lagTimeBilatFreq,4));
            filteredData = reshape(filteredData,prod(dataSize(1:2)),dataSize(3),dataSize(4));
            filteredData(~contourMask(:),:,:) = nan;
            filteredData = reshape(filteredData,dataSize);
            
            % global signal lag
            [~, ~,covResultGsFreq] = gsLagFile(filteredData,sR,maskRun,[],tBoundary(freqInd),corrThr);
            
            % get rid of nan covResults
            covResultBilat{freqInd} = covResultBilatFreq{1}(:,:,~isnan(covResultBilatFreq{1}(1,1,:)));
            covResultGs{freqInd} = covResultGsFreq{1}(:,:,~isnan(covResultGsFreq{1}(1,1,:)));
            lagTimeBilat{freqInd} = lagTimeBilatFreq(~isnan(covResultGsFreq{1}(1,1,:)),:,:);
        end
        
        % save
        saveFile = [week '-' mouseName '-run' num2str(run) '-infarctData.mat'];
        save(fullfile(saveDir,saveFile),'gs','rawL','rawR','covResultBilat','covResultGs','fRange','lagTimeBilat');
    end
    
    tMouse = toc(tMouse);
    disp(['  Mouse # ' num2str(mouse) ' took ' num2str(tMouse) ' seconds.']);
end
