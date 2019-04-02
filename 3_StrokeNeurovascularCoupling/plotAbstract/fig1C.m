load('D:\data\atlas.mat');

atlas(atlas > 20) = atlas(atlas > 20) - 20;
imagesc(atlas,'AlphaData',atlas>0);
axis(gca,'square');
set(gca,'Visible','off');
colormap('jet');
hold on;

load('D:\data\zachRosenthal\_stim\infarctroi.mat');

P = mask2poly(infarctroi);
plot(P.X,P.Y,'k','LineWidth',3);
hold off;