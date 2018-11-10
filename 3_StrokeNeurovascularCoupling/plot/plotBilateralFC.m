dataDir = 'D:\data\zachRosenthal\week1_fc_bilateral_GSR_0p009to0p5';
fileList = dir(dataDir); fileList(1:2) = [];

fcData = [];
mask = [];
for i = 1:numel(fileList)
    fileData = load(fullfile(dataDir,fileList(i).name)); % fcMouse (128 x 128 x 4), maskMouse
    fcData = cat(4,fcData,fileData.fcMouse);
    mask = cat(3,mask,fileData.maskMouse);
end

fcData = nanmean(fcData,4);
mask = nanmean(mask,3);

% fcData = 128 x 128 x 4
% mask = 128 x 128

%% plot

load('D:\data\zachRosenthal\_stim\infarctroi.mat');
roi = infarctroi;
P = mask2poly(roi);

figure;

plotMask = mask> 0.5;
imagesc(fcData(:,:,4),'AlphaData',plotMask,[-1 1]); colormap('jet');
colorbar;
axis(gca,'square')
set(gca,'color','k');
set(gca,'xlabel',[]);
set(gca,'xtick',[]);
set(gca,'ylabel',[]);
set(gca,'ytick',[]);
hold on;
plot(P.X,P.Y,'k','LineWidth',2);
hold off;
