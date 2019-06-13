clear all;
close all;
clc;

wakeData = 'D:\data\Kenny_Awake.mat';
anesthData = 'D:\data\Kenny_Anesthetized.mat';
wlData = 'L:\ProcessedData\wl.mat';

saveData = {'D:\data\motorMovementAvg_Awake.mat','D:\data\motorMovementAvg_Anesthetized.mat'};

load(wlData);

limits = {[-0.1 0.1]};

stateStr = ["Awake","Anesthesia"];
for stateInd = 1:2 % wake, then anesthesia
    
    if stateInd == 1
        data = load(wakeData);
        disp = cat(1,data.XdispRight,data.YdispRight,data.ZdispRight);
        disp = disp';
        
        seedLocs = data.MappingSeedLocs;
    else
        data = load(anesthData);
        stimNum = numel(data.disp);
        disp = zeros(numel(data.disp),99*3);
        for pix = 1:stimNum
            disp(pix,:) = data.disp{pix}(:);
        end
        
        seedLocs = data.MappingSeedLocs;
    end
        
    [coeff,score,latent,~,explained,mu] = pca(disp,'Centered',false);
    
    % plot 3d movement of principal components
    figure('Position',[100+(stateInd-1)*900 600 700 300]);
    subplot('Position',[0.05 0.1 0.35 0.8]);
    for movementType = 1:3
        m = coeff(:,movementType); m = reshape(m,99,3);
        m = m(26:75,:);
        m = m.*explained(movementType)./100;
        plot3(m(:,1),m(:,3),m(:,2),'LineWidth',2); hold on;
    end
    xlim(limits{1}); ylim(limits{1}); zlim(limits{1});
    axis square
    
    xlabel('x'); ylabel('z'); zlabel('y');
    legend({'PC 1','PC 2','PC 3'},'Location','northeast');
    title(stateStr(stateInd));
    subplot('Position',[0.55 0.1 0.35 0.8]);
    for movementType = 1:3
        m = coeff(:,movementType); m = reshape(m,99,3);
        m = m(26:75,:);
        m = m.*explained(movementType)./100;
        plot3(m(:,2),m(:,3),m(:,1),'LineWidth',2); hold on;
    end
    xlim(limits{1}); ylim(limits{1}); zlim(limits{1});
    xlabel('y'); ylabel('z'); zlabel('x');
    axis square
%     % plot variance
%     figure('Position',[100+(stateInd-1)*900 100 500 400]);
%     plot(explained(1:3),'b','LineWidth',2); hold on;
%     scatter(1:3,explained(1:3),'filled','k');
%     title('PC variance explained'); ylabel('%'); xlabel('PC Index');
%     xticks(1:3);
%     
%     % plot brain map
%     weights = nan(128,128,3);
%     for movementType = 1:3
%         for seedInd = 1:size(seedLocs,1)
%             yPix = seedLocs(seedInd,2); xPix = seedLocs(seedInd,1);
%             [yPix, xPix] = meshgrid(yPix-1:yPix+1,xPix-1:xPix+1);
%             weights(yPix(:),xPix(:),movementType) = score(seedInd,movementType);
%         end
%     end
%     figure('Position',[600+(stateInd-1)*900 100 300 900]);
%     cMap = mouse.plot.blueWhiteRed(100);
%     for movementType = 1:3
%         s(movementType) = subplot(3,1,movementType);
%         image(xform_wl); hold on;
%         validPix = ~isnan(weights(:,:,movementType));
%         cLim = weights(:,:,movementType); cLim = max(cLim(:)); cLim = [-cLim cLim];
%         imagesc(weights(:,:,movementType),'AlphaData',validPix,cLim);
%         colormap(cMap); colorbar; axis(gca,'square');
%         set(gca,'YTick',[]); set(gca,'XTick',[]);
%         title(['PC' num2str(movementType)]);
%     end
    
    save(saveData{stateInd},'coeff','score','latent','explained','mu','-v7.3');
end