excelFile = 'D:\data\Stroke Study 1 sorted.xlsx';
saveFile = 'D:\data\zachRosenthal\power_fc_baseline.mat';
rows = 1:14;
recDates = [];
mouseNames = [];
for row = rows
    [~, ~, raw]=xlsread(excelFile,1, ['A',num2str(row),':B',num2str(row)]);
    recDates = [recDates string(raw{1})];
    mouseNames = [mouseNames string(raw{2})];
end
sR = 16.8;

%% actual analysis

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
    
    [f,mousePower] = getBrainPowerPerMouse(dataFiles,maskFile,sR);
    
    powerData = cat(3,powerData,mousePower);
end

save(saveFile,'f','powerData','rows');


%% plot1

figure;
plot(f(1:2000),bsxfun(@times,mean(powerData(:,1:2000,:),3),f(1:2000))'); legend('HbO','HbR','G6Corr'); title('fft power * frequency')

%% plot2

validFInd = 11:2500;

% plot 1/f with these
plotF = f(validFInd);
plotData = mean(powerData(:,validFInd,:),3);
baselineData = 1./plotF;

% find where f ~ 1
f1Ind = find(min(abs(plotF-1)) == abs(plotF-1));
plotData = bsxfun(@rdivide,plotData,plotData(:,f1Ind));

figure;
plot(plotF,baselineData,'k'); hold on;
plot(plotF,plotData); legend('baseline','HbO','HbR','G6Corr');
title('1/f baseline vs fft power');

figure;
loglog(plotF,baselineData,'k'); hold on;
loglog(plotF,plotData); legend('baseline','HbO','HbR','G6Corr');
xlim([min(plotF) max(plotF)]);
title('1/f baseline vs fft power, log scale');