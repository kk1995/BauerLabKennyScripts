% plots avg stim response with roi contour


%% get data

saveFile = 'fig2DataNormGSR.mat';
rootDir = 'D:\data\zachRosenthal\_stim';
weekChar = {'baseline','week1','week4','week8'};

if exist(saveFile)
    load(saveFile);
else
    plotData = nan(128,128,2,4);
    for week = 1:4
        dataDir = fullfile(rootDir,[weekChar{week} '_blockAvg_GSR']);
        fileList = dir(dataDir); fileList(1:2) = [];
        
        fileData = load(fullfile(dataDir,fileList(1).name));
        gcamp6corrBlock = nan([size(fileData.gcamp6corrBlock) numel(fileList)]);
        for fileInd = 1:numel(fileList)
            disp(['File #' num2str(fileInd)]);
            fileData = load(fullfile(dataDir,fileList(fileInd).name));
            % oxyBlock, deoxyBlock, gcamp6corrBlock
            gcamp6corrBlock(:,:,:,:,fileInd) = fileData.gcamp6corrBlock;
        end
        
        gcamp6corrBlock = permute(gcamp6corrBlock,[1 2 4 3 5]);
        % spatial x spatial x freq x time x mouse
        
        t = linspace(0,20,size(gcamp6corrBlock,4)+1); t(1) = [];
        tInd = (t >= 5 + 1/3 & t <= 10);
        
        gcamp6corrStimAvg = squeeze(nanmean(gcamp6corrBlock(:,:,:,tInd,:),4));
        gcamp6corrStimAvgNorm = gcamp6corrStimAvg;
        for mouse = 1:14
            for stimInd = 1:2
                x = squeeze(gcamp6corrStimAvg(:,:,stimInd,mouse));
                if stimInd == 1
                    subset = x(53:88,17:49);
                else
                    subset = x(53:88,80:110);
                end
                maxVal = max(subset(:));
                gcamp6corrStimAvgNorm(:,:,stimInd,mouse) = x./maxVal;
            end
        end
        gcamp6corrStimAvg = nanmean(gcamp6corrStimAvg,4);
        gcamp6corrStimAvgNorm = nanmean(gcamp6corrStimAvgNorm,4);
        
        plotData(:,:,:,week) = gcamp6corrStimAvg;
        plotDataNorm(:,:,:,week) = gcamp6corrStimAvgNorm;
    end
    
    plotData = real(plotData);
    plotDataNorm = real(plotDataNorm);
    
    save(saveFile,'plotData','plotDataNorm');
end

% %% normalization
% 
% for week = 1:4
%     for stimInd = 1:2
%         x = squeeze(plotData(:,:,stimInd,week));
%         if stimInd == 1
%             subset = x(53:88,17:49);
%         else
%             subset = x(53:88,80:110);
%         end
%         maxVal = max(subset(:));
%         plotData(:,:,stimInd,week) = plotData(:,:,stimInd,week)./maxVal;
%     end
% end

%% get mask

maskFile = 'D:\data\zachRosenthal\_meta\mask.mat';
load(maskFile); % maskData

%% get contour

stimLoc = cell(4,2);

load('D:\data\zachRosenthal\_stim\ROI R 75.mat');
stimLoc{1,1} = roiR75;
load('D:\data\zachRosenthal\_stim\ROI R 75 vs baseline wk1 after stroke.mat');
stimLoc{2,1} = roiR75ofbaselineatwk1;
load('D:\data\zachRosenthal\_stim\ROI R 75 wk4 after stroke.mat');
stimLoc{3,1} = roiR75wk4;
load('D:\data\zachRosenthal\_stim\ROI R 75 wk8.mat');
stimLoc{4,1} = roiR75wk8;

load('D:\data\zachRosenthal\_stim\ROI L 75.mat');
stimLoc{1,2} = roiL75;
stimLoc{2,2} = roiL75;
stimLoc{3,2} = roiL75;
stimLoc{4,2} = roiL75;

%% plot

f1 = figure('Position',[100 100 800 365]);
p = panel();
p.pack('h',{0.23 0.23 0.23 0.23});
p.pack(2, 4);
for n = 1:4
    p(n).pack(2);
end
p.margin = [0 0 1 0];
cMap = jet(100);

rmMouse = cell(4,1);
rmMouse{1} = [12 14];
rmMouse{2} = [14];
rmMouse{3} = [12 14];
rmMouse{4} = [14];

for week = 1:4
    for stimInd = 1:2
        ax = p(week,stimInd).select();
        set(ax,'Color','k');
        set(gca,'xtick',[])
        set(gca,'xticklabel',[])
        set(gca,'ytick',[])
        set(gca,'yticklabel',[])
        axis(ax,'square');
        
        badMouse = false(size(maskData{week},3),1);
        badMouse(rmMouse{week}) = true;
        
        % plot response data
        mask = nanmean(maskData{week}(:,:,~badMouse),3);
        mask = mask >= 1;
        
        subplotData = real(squeeze(plotData(:,:,stimInd,week)));
        if stimInd == 1
            cLim = [-3E-3 3E-3];
        else
            cLim = [-2E-3 2E-3];
        end
        if week == 4
            ax = mouseAnalysis.plot.plotBrain(ax,subplotData,mask,cLim,cMap,true,0.02);
            set(ax(end),'FontSize',16);
        else
            ax = mouseAnalysis.plot.plotBrain(ax,subplotData,mask,cLim,cMap);
        end
        % plot contour
        contour = stimLoc{week,stimInd};
        
        if stimInd == 2 && week > 1
            % 75% of max
            subset = subplotData(53:88,80:110);
            maxVal = max(subset(:));
            contour = subplotData >= 0.75*maxVal;
            contour(:,1:79) = false;
        end
        
        if (stimInd == 1 && week == 1) || (stimInd == 1 && week == 4) || (stimInd == 2 && week == 1)
            ax = mouseAnalysis.plot.plotContour(ax,contour,'k','-',2);
        end
    end
end