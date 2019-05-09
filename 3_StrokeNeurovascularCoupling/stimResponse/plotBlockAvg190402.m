dataFile = ["D:\ProcessedData\zach_gcamp_stroke_stim-2-43-blockAvg.mat",...
    "D:\ProcessedData\zach_gcamp_stroke_stim-44-83-blockAvg.mat",...
    "D:\ProcessedData\zach_gcamp_stroke_stim-84-125-blockAvg.mat",...
    "D:\ProcessedData\zach_gcamp_stroke_stim-126-167-blockAvg.mat",...
    "L:\ProcessedData\zach_gcamp_stroke_stim_left-2-43-blockAvg.mat",...
    "L:\ProcessedData\zach_gcamp_stroke_stim_left-44-84-blockAvg.mat",...
    "L:\ProcessedData\zach_gcamp_stroke_stim_left-85-126-blockAvg.mat",...
    "L:\ProcessedData\zach_gcamp_stroke_stim_left-127-168-blockAvg.mat"];

response = [];

for fileInd = 1:numel(dataFile)
    disp(['File #' num2str(fileInd)]);
    
    fileData = load(dataFile(fileInd));
    
    stimTime = fileData.blockTime > 9 & fileData.blockTime < 11;
    response = cat(3,response,squeeze(mean(sum(mean(fileData.hbBlock(:,:,:,stimTime,:),5),3),4)));
%     response = cat(3,response,squeeze(mean(sum(mean(fileData.fluorBlock(:,:,:,stimTime,:),5),3),4)));
end

%% plot

cLim = [-1 1]*1E-6;
% cLim = [-1 1]*0.3E-2;

load('L:\ProcessedData\noVasculatureMask.mat');
wlData = load('L:\ProcessedData\wl.mat');
roi = load('D:\ProcessedData\zachInfarctROI.mat');

mask = leftMask | rightMask;

f1 = figure('Position',[100 100 800 365]);
p = panel();
p.pack('h',{0.23 0.23 0.23 0.23});
for i = 1:4
    p(i).pack(2,1);
end
% p.pack(2, 4);
p.margin = [0 2 1 0];


cMap = jet(100);

stimROIAll = [];

for row = 1:2
    for col = 1:4
        responseInd = (row-1)*4 + col;
        ax = p(col,row,1).select();
        set(ax,'Color','k');
        set(gca,'xtick',[])
        set(gca,'xticklabel',[])
        set(gca,'ytick',[])
        set(gca,'yticklabel',[])
        axis(ax,'square');
        
        image(wlData.xform_wl,'AlphaData',wlData.xform_isbrain);
        xlim([1 size(wlData.xform_wl,1)]); ylim([1 size(wlData.xform_wl,2)]);
        set(gca,'ydir','reverse');
        hold on;
        
        if col == 4
            ax = mouse.plot.plotBrain(ax,response(:,:,responseInd),mask,cLim,cMap,true,0.025);
            set(ax(end),'FontSize',14);
        else
            ax = mouse.plot.plotBrain(ax,response(:,:,responseInd),mask,cLim,cMap);
        end
        
        if row == 1
            stimROI = mouse.expSpecific.getROI(response(:,:,responseInd),[63 31]);
            if col > 1
                stimROI = mouse.expSpecific.getROI(response(:,:,responseInd),[75 31]);
            end
        else
            stimROI = mouse.expSpecific.getROI(response(:,:,responseInd),[63 98]);
        end
        
        stimROIAll = cat(3,stimROIAll,stimROI);
        
        ax = mouse.plot.plotContour(ax,roi.infarctroi,'k','-',2);
        ax = mouse.plot.plotContour(ax,stimROI,'g','-',2);
    end
end

stimROIAll = reshape(stimROIAll,128,128,4,2);
stimROIAll = permute(stimROIAll,[1,2,4,3]);
save('L:\ProcessedData\gcampStimROI.mat','stimROIAll');

% %% gsr
% load('D:\data\zachRosenthal\week1mask.mat');
% mask = mask >= 0.5;
% 
% % oxyBlock = mouseAnalysis.preprocess.gsr(oxyBlock,mask);
% % deoxyBlock = mouseAnalysis.preprocess.gsr(deoxyBlock,mask);
% % gcamp6corrBlock = mouseAnalysis.preprocess.gsr(gcamp6corrBlock,mask);
% 
% %% get roi avg
% 
% roiDir = 'D:\data\zachRosenthal\_stim\ROI R 75.mat';
% load(roiDir)
% roi = roiR75;
% 
% oxyBlockVect = reshape(oxyBlock,size(oxyBlock,1)*size(oxyBlock,2),size(oxyBlock,3),size(oxyBlock,4));
% deoxyBlockVect = reshape(deoxyBlock,size(deoxyBlock,1)*size(deoxyBlock,2),size(deoxyBlock,3),size(deoxyBlock,4));
% gcamp6corrBlockVect = reshape(gcamp6corrBlock,size(gcamp6corrBlock,1)*size(gcamp6corrBlock,2),size(gcamp6corrBlock,3),size(gcamp6corrBlock,4));
% 
% t = linspace(0,20,size(oxyBlockVect,3)+1); t(1) = [];
% 
% oxyAvg = squeeze(nanmean(oxyBlockVect(roi,1,:),1));
% oxyAvg = oxyAvg - mean(oxyAvg(t<5));
% deoxyAvg = squeeze(nanmean(deoxyBlockVect(roi,1,:),1));
% deoxyAvg = deoxyAvg - mean(deoxyAvg(t<5));
% gcamp6corrAvg = squeeze(nanmean(gcamp6corrBlockVect(roi,1,:),1));
% gcamp6corrAvg = gcamp6corrAvg - mean(gcamp6corrAvg(t<5));
% 
% %% plot time course
% 
% figure('Position',[100 100 550 400]); p1 = plot(t,oxyAvg,'r'); hold on;
% p2 = plot(t,deoxyAvg,'b');
% p3 = plot(t,oxyAvg+deoxyAvg,'m');
% p4 = plot(t,gcamp6corrAvg,'k'); hold off;
% set(findall(gca, 'Type', 'Line'),'LineWidth',2);
% 
% % plotting stimulation
% stimTime = 5:1/3:10; stimTime(end) = [];
% yRange = ylim;
% hold on;
% for i = 1:numel(stimTime)
%     plot([stimTime(i) stimTime(i)],yRange,'g');
% end
% 
% legend([p1 p2 p3 p4],{'HbO','HbR','HbT','GCaMP'});
% 
% %% plot spatial avg
% 
% t = linspace(0,20,size(oxyBlock,4)+1); t(1) = [];
% tInd = (t >= 5 & t <= 10);
% 
% oxyStimAvg = squeeze(nanmean(oxyBlock(:,:,:,tInd),4));
% deoxyStimAvg = squeeze(nanmean(deoxyBlock(:,:,:,tInd),4));
% gcamp6corrStimAvg = squeeze(nanmean(gcamp6corrBlock(:,:,:,tInd),4));
% 
% figure('Position',[100 100 500 450]);
% imagesc(gcamp6corrStimAvg(:,:,1),'AlphaData',mask,[-1E-3 3E-3]); colormap('jet'); colorbar;
% set(gca,'color','black')
% axis(gca,'square');
% set(gca,'xtick',[])
% set(gca,'xticklabel',[])
% set(gca,'ytick',[])
% set(gca,'yticklabel',[])
% 
% % plot contour
% 
% hold on;
% load('D:\data\zachRosenthal\_stim\ROI R 75.mat');
% P = mask2poly(roiR75);
% for n = 1:numel(P)
% color = 'k';
% p1 = plot(P(n).X,P(n).Y,color,'LineWidth',2);
% end
% 
% load('D:\data\zachRosenthal\_stim\ROI R 75 vs baseline wk1 after stroke.mat');
% P = mask2poly(roiR75ofbaselineatwk1);
% for n = 1:numel(P)
% color = 'b';
% p2 = plot(P(n).X,P(n).Y,color,'LineWidth',2);
% end
% 
% load('D:\data\zachRosenthal\_stim\ROI R 75 wk4 after stroke.mat');
% P = mask2poly(roiR75wk4);
% for n = 1:numel(P)
% color = 'm';
% p3 = plot(P(n).X,P(n).Y,color,'LineWidth',2);
% end
% 
% load('D:\data\zachRosenthal\_stim\ROI R 75 wk8.mat');
% P = mask2poly(roiR75wk8);
% for n = 1:numel(P)
% color = 'g';
% p4 = plot(P(n).X,P(n).Y,color,'LineWidth',2);
% end
% hold off;
% 
% lgnd = legend([p1 p2 p3 p4],{'baseline','week 1','week 4','week 8'});
% set(lgnd,'color','white');