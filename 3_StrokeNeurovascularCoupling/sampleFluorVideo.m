load('D:\ProcessedData\170127\170127-2535_baseline-stim2-datahb.mat')
load('D:\ProcessedData\170127\170127-2535_baseline-stim2-datafluor.mat')
filename = 'D:\ProcessedData\170127\170127-2535_baseline-stim2-fluorVideo.mp4';

xform_isbrain = mouse.process.affineTransform(hbProcInfo.Mask,hbProcInfo.AffineMarkers);

% filter
xform_datahb = lowpass(xform_datahb,0.08,16.8); xform_datahb = highpass(xform_datahb,0.01,16.8);
xform_datafluor = lowpass(xform_datafluor,0.08,16.8); xform_datafluor = highpass(xform_datafluor,0.01,16.8);
xform_datafluorCorr = lowpass(xform_datafluorCorr,0.08,16.8); xform_datafluorCorr = highpass(xform_datafluorCorr,0.01,16.8);

% gsr
xform_datahb = mouse.process.gsr(xform_datahb,xform_isbrain);
xform_datafluor = mouse.process.gsr(xform_datafluor,xform_isbrain);
xform_datafluorCorr = mouse.process.gsr(xform_datafluorCorr,xform_isbrain);

% block avg
[xform_datahb, blockTime] = mouse.expSpecific.blockAvg(xform_datahb,rawTime,20,20*16.8);
xform_datafluor = mouse.expSpecific.blockAvg(xform_datafluor,rawTime,20,20*16.8);
xform_datafluorCorr = mouse.expSpecific.blockAvg(xform_datafluorCorr,rawTime,20,20*16.8);

% remove baseline
xform_datahb = bsxfun(@minus,xform_datahb,nanmean(xform_datahb(:,:,:,blockTime < 5),4));
xform_datafluor = bsxfun(@minus,xform_datafluor,nanmean(xform_datafluor(:,:,:,blockTime < 5),4));
xform_datafluorCorr = bsxfun(@minus,xform_datafluorCorr,nanmean(xform_datafluorCorr(:,:,:,blockTime < 5),4));

%% make video
wlData = load('L:\ProcessedData\wl.mat');
load('L:\ProcessedData\noVasculatureMask.mat');
alpha = (leftMask | rightMask) & xform_isbrain;

v = VideoWriter(filename);
v.FrameRate = 16.8;
open(v);
figure('Position',[100 100 900 300]);
for i = 1:5:numel(blockTime)
%     subplot('Position',[0 0 0.19 0.95]);
%     image(wlData.xform_wl,'AlphaData',wlData.xform_isbrain); hold on;
%     imagesc(squeeze(xform_datahb(:,:,1,i)),'AlphaData',alpha,[-1E-6 1E-6]);
%     axis(gca,'square'); colorbar; colormap('jet'); set(gca,'Visible','off'); set(gca,'FontSize',14);
%     t = title('HbO'); set(t,'Visible','on'); set(t,'FontSize',18);
%     subplot('Position',[0.2 0 0.19 0.95]);
%     image(wlData.xform_wl,'AlphaData',wlData.xform_isbrain); hold on;
%     imagesc(squeeze(xform_datahb(:,:,2,i)),'AlphaData',alpha,[-3E-7 3E-7]);
%     axis(gca,'square'); colorbar; colormap('jet'); set(gca,'Visible','off'); set(gca,'FontSize',14);
%     t = title('HbR'); set(t,'Visible','on'); set(t,'FontSize',18);
    subplot('Position',[0 0 0.3 0.9]);
    image(wlData.xform_wl,'AlphaData',wlData.xform_isbrain); hold on;
    imagesc(squeeze(sum(xform_datahb(:,:,:,i),3)),'AlphaData',alpha,[-5E-7 5E-7]);
    axis(gca,'square'); colorbar; colormap('jet'); set(gca,'Visible','off'); set(gca,'FontSize',14);
    t = title('HbT'); set(t,'Visible','on'); set(t,'FontSize',18);
    subplot('Position',[0.32 0 0.3 0.9]);
    image(wlData.xform_wl,'AlphaData',wlData.xform_isbrain); hold on;
    imagesc(squeeze(xform_datafluor(:,:,1,i)),'AlphaData',alpha,[-3E-3 3E-3]);
    axis(gca,'square'); colorbar; colormap('jet'); set(gca,'Visible','off'); set(gca,'FontSize',14);
    t = title('fluor uncorrected'); set(t,'Visible','on'); set(t,'FontSize',18);
    subplot('Position',[0.64 0 0.3 0.9]);
    image(wlData.xform_wl,'AlphaData',wlData.xform_isbrain); hold on;
    imagesc(squeeze(xform_datafluorCorr(:,:,1,i)),'AlphaData',alpha,[-3E-3 3E-3]);
    axis(gca,'square'); colorbar; colormap('jet'); set(gca,'Visible','off'); set(gca,'FontSize',14);
    t = title('fluor corrected'); set(t,'Visible','on'); set(t,'FontSize',18);
    frame = getframe(gcf);
    writeVideo(v,frame);
end
close(v);