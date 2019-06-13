function getPowerMap(rows,useGSR)

excelFile = 'D:\data\Stroke Study 1 sorted.xlsx';

% rows = 1:14;
% rows = 15:28;
% rows = 29:42;
% rows = 43:56;

fMin = 0.4; fMax = 5;
sR = 16.8;
% useGSR = false;

recDates = [];
mouseNames = [];
for row = rows
    [~, ~, raw]=xlsread(excelFile,1, ['A',num2str(row),':B',num2str(row)]);
    recDates = [recDates string(raw{1})];
    mouseNames = [mouseNames string(raw{2})];
end

freqStr = [num2str(fMin),'-',num2str(fMax)];
freqStr(strfind(freqStr,'.')) = 'p';

saveFile = ['D:\data\zachRosenthal\powerMap-',...
    'freq',freqStr,'-',...
    'rows',num2str(rows(1)),'-',num2str(rows(end))];
if useGSR
    saveFile = [saveFile '-GSR'];
end
saveFile = [saveFile '.mat'];

%% actual analysis

if exist(saveFile)
    load(saveFile)
else
    powerData = [];
    
    for mouseInd = 1:numel(mouseNames)
        disp(['mouse # ' num2str(mouseInd)]);
        maskFile = strcat("K:\Proc2\",recDates(mouseInd),"\",recDates(mouseInd),"-",...
            mouseNames(mouseInd),"-LandmarksandMask.mat");
        
        % make str array of run files
        runNum = 3;
        dataFiles = repmat(strcat("K:\Proc2\",recDates(mouseInd),"\",recDates(mouseInd),"-",...
            mouseNames(mouseInd),"-dataGCaMP-fc"),runNum,1);
        for run = 1:runNum
            dataFiles(run) = strcat(dataFiles(run),num2str(run),".mat");
        end
        
        [mousePower,f] = getPowerMapPerMouse(dataFiles,[fMin fMax],sR);
        
        powerData = cat(4,powerData,mousePower);
    end
    
    save(saveFile,'f','powerData','rows');
end

%% plot

wlFile = 'L:\ProcessedData\wl.mat'; load(wlFile);
maskFile = 'L:\ProcessedData\noVasculatureMask.mat'; load(maskFile);
mask = leftMask | rightMask;
if useGSR
    refVal = [-8 -8.2 -6.7];
else
    refVal = [-7.5 -7.7 -6.1];
end

figure('Position',[100 100 360 900]);
titleStr = {'HbO','HbR','Fluor'};
plotData = nanmean(powerData,4);
for species = 1:3
    subplot('Position',[0.1 (3-species)*0.33+0.02 0.8 0.31]);
    image(xform_wl); hold on;
    imagesc(log10(plotData(:,:,species)),'AlphaData',mask,[refVal(species)-1 refVal(species)+1]);
    axis(gca,'square'); set(gca,'YTick',[]); set(gca,'XTick',[]);
    colormap('jet'); colorbar;
    title(titleStr{species});
end