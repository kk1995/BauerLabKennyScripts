load('D:\data\atlas.mat','AtlasSeedsFilled');

imagesc(AtlasSeedsFilled,'AlphaData',AtlasSeedsFilled>0);
axis(gca,'square');
set(gca,'Visible','off');
colormap('jet');
hold on;

load('D:\data\zachRosenthal\_stim\infarctroi.mat');

P = mask2poly(infarctroi);
plot(P.X,P.Y,'k','LineWidth',3);
hold off;