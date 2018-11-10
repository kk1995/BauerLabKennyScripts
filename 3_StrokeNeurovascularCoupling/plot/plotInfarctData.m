dataDir = 'D:\data\zachRosenthal\_infarct\latest';
sR = 16.81;
speciesName = ["HbO","HbR","HbT","GCaMP"];
D = dir(dataDir); D(1:2) = [];
correctDate = false(numel(D),1);
for i = 1:numel(D)
    if contains(D(i).name,'week1')
        correctDate(i) = true;
    end
end
D = D(correctDate);
corrThr = 0.3;

mouseFileList = cell(14,1);
for file = 1:numel(D)
    run = mod(file-1,3)+1;
    mouse = ceil(file/3);
    mouseFileList{mouse} = [mouseFileList{mouse} string(fullfile(dataDir,D(file).name))];
end

%%

% for mouse = 1:numel(mouseFileList)
for mouse = 3
    runFileList = mouseFileList{mouse};
    rawL = []; rawR = []; gs = []; covBilat = []; covGs = [];
    for run = 1:numel(runFileList)
        loadedData = load(runFileList(run));
        rawL = cat(3,rawL,squeeze(nanmean(loadedData.rawL{1},1)));
        rawR = cat(3,rawR,squeeze(nanmean(loadedData.rawR{1},1)));
        gs = cat(3,gs,squeeze(loadedData.gs{1}));
        covBilat = cat(4,covBilat,loadedData.covResultBilat{1});
        covGs = cat(4,covGs,loadedData.covResultGs{1});
    end
    % bilat
    speciesNum = size(rawL,1);
    runNum = size(rawL,3);
%     for species = 1:speciesNum
    for species = 3
        figure('Position',[100 100 800 600]);
        for run = 1:runNum
            subplot(runNum,2,1+(run-1)*2);
            time = 1:size(rawL,2); time = time./sR;
            plot(time,squeeze(rawL(species,:,run))); hold on;
            plot(time,squeeze(rawR(species,:,run))); hold off;
            if run == 1; legend('infarct','mirror'); end
            xlim([50 80]);
            
            subplot(runNum,2,2+(run-1)*2);
            lagDataNum = size(covBilat,2);
            lagTime = 1:lagDataNum; lagTime = lagTime - round(lagDataNum/2);
            lagTime = lagTime./sR;
            plotCov = squeeze(covBilat(species,:,:,run))';
            % find where peak is at
            peakVal = max(plotCov,[],2);
            plotCov(isnan(peakVal),:) = [];
            peakVal(isnan(peakVal),:) = [];
            
            peakInd = nan(size(peakVal));
            goodPix = true(size(peakVal));
            for pix = 1:size(plotCov,1)
                peakInd(pix) = find(peakVal(pix) == plotCov(pix,:));
                if peakVal(pix) < corrThr
                    goodPix(pix) = false;
                end
            end
            peakTime = lagTime(peakInd(goodPix));
            peakTime = nanmean(peakTime);
            plotCov = plotCov(goodPix,:);
            
            plot(lagTime,plotCov); xlim([-5 5]); hold on;
            yLim = ylim;
            plot([0 0],yLim,'k');
            plot(linspace(peakTime,peakTime,10),linspace(yLim(1),yLim(2),10),'k--'); hold off;
            xlabel('Lag time (s)');
            text(2.5,yLim(2)-0.1,num2str(peakTime));
        end
        mtit([char(speciesName(species)) ' bilateral']);
        
        figure('Position',[1000 100 800 600]);
        for run = 1:runNum
            subplot(runNum,2,1+(run-1)*2);
            time = 1:size(rawL,2); time = time./sR;
            plot(time,squeeze(rawL(species,:,run))); hold on;
            plot(time,squeeze(gs(species,:,run))); hold off;
            if run == 1; legend('infarct','gs'); end
            xlim([50 80]);
            
            subplot(runNum,2,2+(run-1)*2);
            lagDataNum = size(covBilat,2);
            lagTime = 1:lagDataNum; lagTime = lagTime - round(lagDataNum/2);
            lagTime = lagTime./sR;
            plotCov = squeeze(covGs(species,:,:,run))';
            % find where peak is at
            peakVal = max(plotCov,[],2);
            
            peakInd = nan(size(peakVal));
            for pix = 1:size(plotCov,1)
                peakInd(pix) = find(peakVal(pix) == plotCov(pix,:));
            end
            
            peakTime = lagTime(peakInd);
            peakTime = nanmean(peakTime);
            
            plot(lagTime,plotCov); xlim([-5 5]); hold on;
            yLim = ylim;
            plot([0 0],yLim,'k');
            plot(linspace(peakTime,peakTime,10),linspace(yLim(1),yLim(2),10),'k--'); hold off;
            xlabel('Lag time (s)');
            text(2.5,yLim(2)-0.1,num2str(peakTime));
        end
        mtit([char(speciesName(species)) ' gs']);
    end
end