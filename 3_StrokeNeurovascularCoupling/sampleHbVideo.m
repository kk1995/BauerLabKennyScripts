load('D:\ProcessedData\170127\170127-2535_baseline-fc2-datahb.mat')
filename = 'D:\ProcessedData\170127\170127-2535_baseline-fc2-hbVideo.mp4';

xform_isbrain = mouse.process.affineTransform(hbProcInfo.Mask,hbProcInfo.AffineMarkers);

xform_datahb = mouse.process.gsr(xform_datahb,xform_isbrain);

% filter
xform_datahb = lowpass(xform_datahb,0.08,16.8);
xform_datahb = highpass(xform_datahb,0.01,16.8);

%% make video
wlData = load('L:\ProcessedData\wl.mat');
load('L:\ProcessedData\noVasculatureMask.mat');
alpha = (leftMask | rightMask) & xform_isbrain;

v = VideoWriter(filename);
v.FrameRate = 16.8;
open(v);
figure('Position',[100 100 1500 500]);
tInd = 2:10:1800;
for i = tInd
    subplot('Position',[0 0 0.3 0.9]);
    image(wlData.xform_wl,'AlphaData',wlData.xform_isbrain); hold on;
    imagesc(squeeze(xform_datahb(:,:,1,i)),'AlphaData',alpha,[-4.9E-6 4.9E-6]);
    axis(gca,'square'); colorbar; colormap('jet'); set(gca,'Visible','off'); set(gca,'FontSize',16);
    t = title('HbO'); set(t,'Visible','on'); set(t,'FontSize',18);
    subplot('Position',[0.32 0 0.3 0.9]);
    image(wlData.xform_wl,'AlphaData',wlData.xform_isbrain); hold on;
    imagesc(squeeze(xform_datahb(:,:,2,i)),'AlphaData',alpha,[-2E-6 2E-6]);
    axis(gca,'square'); colorbar; colormap('jet'); set(gca,'Visible','off'); set(gca,'FontSize',16);
    t = title('HbR'); set(t,'Visible','on'); set(t,'FontSize',18);
    subplot('Position',[0.64 0 0.3 0.9]);
    image(wlData.xform_wl,'AlphaData',wlData.xform_isbrain); hold on;
    imagesc(squeeze(sum(xform_datahb(:,:,:,i),3)),'AlphaData',alpha,[-3E-6 3E-6]);
    axis(gca,'square'); colorbar; colormap('jet'); set(gca,'Visible','off'); set(gca,'FontSize',16);
    t = title('HbT'); set(t,'Visible','on'); set(t,'FontSize',18);
    frame = getframe(gcf);
    writeVideo(v,frame);
end
close(v);