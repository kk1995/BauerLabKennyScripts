% compares gcampCorr and gcamp correlation with hbT

% get list of mice
excelFile = 'D:\data\Stroke Study 1 sorted.xlsx';
rows = 1:14;
recDates = [];
mouseNames = [];
for row = rows
    [~, ~, raw]=xlsread(excelFile,1, ['A',num2str(row),':B',num2str(row)]);
    recDates = [recDates string(raw{1})];
    mouseNames = [mouseNames string(raw{2})];
end

gCorrMean = [];
gCorrMedian = [];
gCorrCorrMean = [];
gCorrCorrMedian = [];
for mouseInd = 1:numel(mouseNames)
    disp(['mouse # ' num2str(mouseInd)]);
    maskFileName = strcat("D:\data\",recDates(mouseInd),"\",recDates(mouseInd),"-",...
        mouseNames(mouseInd),"-LandmarksandMask.mat");
    maskData = load(maskFileName);
    mask = maskData.xform_mask > 0;
    mask = mask(:);
    validPixNum = sum(mask);
    for run = 1:3
        fileName = strcat("D:\data\",recDates(mouseInd),"\",recDates(mouseInd),"-",...
            mouseNames(mouseInd),"-dataGCaMP-fc",num2str(run),".mat");
        load(fileName);
        hbT = oxy + deoxy;
        hbTVect = reshape(hbT,128*128,[]); hbTVect = hbTVect(mask,:);
        gcamp6Vect = reshape(gcamp6,128*128,[]); gcamp6Vect = gcamp6Vect(mask,:);
        gcamp6corrVect = reshape(gcamp6corr,128*128,[]); gcamp6corrVect = gcamp6corrVect(mask,:);
        gCorr = nan(validPixNum,1); for i = 1:validPixNum; gCorr(i) = corr(hbTVect(i,:)',gcamp6Vect(i,:)'); end
        gCorrCorr = nan(validPixNum,1); for i = 1:validPixNum; gCorrCorr(i) = corr(hbTVect(i,:)',gcamp6corrVect(i,:)'); end
        
        % save to larger matrix
        gCorrMean = [gCorrMean mean(gCorr)]; gCorrMedian = [gCorrMedian median(gCorr)];
        gCorrCorrMean = [gCorrCorrMean mean(gCorrCorr)]; gCorrCorrMedian = [gCorrCorrMedian median(gCorrCorr)];
    end
    gCorrMean(end-2) = mean(gCorrMean(end-2:end)); gCorrMean(end-1:end) = [];
    gCorrMedian(end-2) = mean(gCorrMedian(end-2:end)); gCorrMedian(end-1:end) = [];
    gCorrCorrMean(end-2) = mean(gCorrCorrMean(end-2:end)); gCorrCorrMean(end-1:end) = [];
    gCorrCorrMedian(end-2) = mean(gCorrCorrMedian(end-2:end)); gCorrCorrMedian(end-1:end) = [];
end

%% plot

labels = ["g6-HbT mean","g6c-HbT mean","g6-HbT med","g6c-HbT med"];
groups = [ones(1,numel(gCorrMean)) 2*ones(1,numel(gCorrCorrMean)) ...
    3*ones(1,numel(gCorrMedian)) 4*ones(1,numel(gCorrCorrMedian))];
notBoxPlot(abs([gCorrMean gCorrCorrMean gCorrMedian gCorrCorrMedian]),groups);
xticklabels(labels);

%%

save('D:\data\zachRosenthal\_summary\corrMat.mat','gCorrMean','gCorrCorrMean','gCorrMedian','gCorrCorrMedian');