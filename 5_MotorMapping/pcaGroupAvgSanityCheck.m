clear all; close all; clc;

wakeData = 'D:\data\Kenny_Awake.mat';
anesthData = 'D:\data\Kenny_Anesthetized.mat';
wlData = 'L:\ProcessedData\wl.mat';

dataFile = {'D:\data\motorMovementAvg_Awake.mat','D:\data\motorMovementAvg_Anesthetized.mat'};

load(wlData);

stateStr = ["Awake","Anesthesia"];
for stateInd = 1:2 % wake, then anesthesia
    
    if stateInd == 1
        data = load(wakeData);
        disp = cat(1,data.XdispRight,data.YdispRight,data.ZdispRight);
        disp = disp';
        disp = reshape(disp,size(disp,1),99,3);
        seedLocs = data.MappingSeedLocs;
    else
        data = load(anesthData);
        stimNum = numel(data.disp);
        disp = zeros(numel(data.disp),99*3);
        for pix = 1:stimNum
            disp(pix,:) = data.disp{pix}(:);
        end
        disp = reshape(disp,size(disp,1),99,3);
        seedLocs = data.MappingSeedLocs;
    end
    
    pcaData = load(dataFile{stateInd});
    
    for dataSource = 1:4
        if dataSource == 1
            data = disp;
        elseif dataSource == 2
            data = bsxfun(@plus,pcaData.score(:,1)*pcaData.coeff(:,1)',pcaData.mu);
            data = reshape(data,size(data,1),99,3);
        elseif dataSource == 3
            data = bsxfun(@plus,pcaData.score(:,1:3)*pcaData.coeff(:,1:3)',pcaData.mu);
            data = reshape(data,size(data,1),99,3);
        else
            data = bsxfun(@plus,pcaData.score*pcaData.coeff',pcaData.mu);
            data = reshape(data,size(data,1),99,3);
        end
        
        dispTotal = sum(data.^2,3);
        
        % find peak response
        validTInd = 25:75;
        peakResp = nan(238,3);
        for seedInd = 1:238
            tInd = find(max(dispTotal(seedInd,validTInd)) == dispTotal(seedInd,validTInd)); tInd = tInd(1);
            peakResp(seedInd,:) = data(seedInd,validTInd(tInd),:);
        end
        
        % plot brain map of pca result
        weights = nan(128,128,3);
        for coorDim = 1:3
            for seedInd = 1:size(seedLocs,1)
                yPix = seedLocs(seedInd,2); xPix = seedLocs(seedInd,1);
                [yPix, xPix] = meshgrid(yPix-1:yPix+1,xPix-1:xPix+1);
                weights(yPix(:),xPix(:),coorDim) = peakResp(seedInd,coorDim);
            end
        end
        
        figure('Position',[50+(stateInd-1)*700+(dataSource-1)*350 50 300 900]);
        cMap = mouse.plot.blueWhiteRed(100);
        titleStr = {'x','y','z'};
        for coorDim = 1:3
            s(coorDim) = subplot(3,1,coorDim);
            image(xform_wl); hold on;
            validPix = ~isnan(weights(:,:,coorDim));
            cLim = weights(:,:,coorDim); cLim = max(cLim(:)); cLim = [-cLim cLim];
            imagesc(weights(:,:,coorDim),'AlphaData',validPix,cLim);
            colormap(cMap); colorbar; axis(gca,'square');
            set(gca,'YTick',[]); set(gca,'XTick',[]);
            title(titleStr{coorDim});
        end
    end
end