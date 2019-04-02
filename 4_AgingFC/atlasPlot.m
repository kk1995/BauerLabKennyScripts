load('D:\data\atlas12.mat')
load('L:\ProcessedData\deborahHemisphereMask.mat')

x = atlasUnfilled;
x(x > 6) = x(x > 6) - 6;
x(x == 3) = 2.8;

cMap = [255 255 255; 139 34 34; 242 145 46; 227 227 43; 34 139 34; 56 221 221; 46 128 242]/255;
figure; imagesc(x,'AlphaData',x > 0); colormap(cMap); set(gca,'Color',[1 1 1 0]); set(gca,'Visible','off'); axis(gca,'square');
