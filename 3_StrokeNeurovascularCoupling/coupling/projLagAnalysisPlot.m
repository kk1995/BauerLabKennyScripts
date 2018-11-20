ds = 4;

mouseFile = strcat("D:\data\zachRosenthal\baseline_projLag\2541_baseline-run1-projLagOxyG6-ds", ...
    num2str(ds), ".mat");

load(mouseFile);

% lagTimeG6 = lagTimeG6./16.81;
% lagTimeOxy = lagTimeOxy./16.81;
% lagTimeOxyG6 = lagTimeOxyG6./16.81;

x = 10;
y = 27;
% x = 5;
% y = 13;

ind = y + (x-1)*sqrt(size(lagAmpG6,1));

figure('Position',[100 100 800 500]);
p = panel();
p.pack(2,3);

p(1,1).select(); set(gca,'Ydir','reverse');
lagAmpG6 = lagAmpG6(ind,:);
lagAmpG6 = reshape(lagAmpG6,size(xform_mask));
imagesc(lagAmpG6,'AlphaData',xform_mask,[0 1]); colormap('jet'); colorbar; axis(gca,'square');
xlim([1 size(xform_mask,2)]); ylim([1 size(xform_mask,1)]);
set(gca,'Visible','off');
title('GCaMP amp');

p(1,2).select(); set(gca,'Ydir','reverse');
lagAmpOxy = lagAmpOxy(ind,:);
lagAmpOxy = reshape(lagAmpOxy,size(xform_mask));
imagesc(lagAmpOxy,'AlphaData',xform_mask,[0 1]); colormap('jet'); colorbar; axis(gca,'square');
xlim([1 size(xform_mask,2)]); ylim([1 size(xform_mask,1)]);
set(gca,'Visible','off');
title('HbO amp');

p(1,3).select(); set(gca,'Ydir','reverse');
lagAmpOxyG6 = lagAmpOxyG6(ind,:);
lagAmpOxyG6 = reshape(lagAmpOxyG6,size(xform_mask));
imagesc(lagAmpOxyG6,'AlphaData',xform_mask,[0 1]); colormap('jet'); colorbar; axis(gca,'square');
xlim([1 size(xform_mask,2)]); ylim([1 size(xform_mask,1)]);
set(gca,'Visible','off');
title('HbO - GCaMP amp');

p(2,1).select(); set(gca,'Ydir','reverse');
lagTimeG6 = lagTimeG6(ind,:);
lagTimeG6 = reshape(lagTimeG6,size(xform_mask));
imagesc(lagTimeG6,'AlphaData',xform_mask,[-0.5 0.5]); colormap('jet'); colorbar; axis(gca,'square');
xlim([1 size(xform_mask,2)]); ylim([1 size(xform_mask,1)]);
set(gca,'Visible','off');
title('GCaMP time');

p(2,2).select(); set(gca,'Ydir','reverse');
lagTimeOxy = lagTimeOxy(ind,:);
lagTimeOxy = reshape(lagTimeOxy,size(xform_mask));
imagesc(lagTimeOxy,'AlphaData',xform_mask,[-0.5 0.5]); colormap('jet'); colorbar; axis(gca,'square');
xlim([1 size(xform_mask,2)]); ylim([1 size(xform_mask,1)]);
set(gca,'Visible','off');
title('HbO time');

p(2,3).select(); set(gca,'Ydir','reverse');
lagTimeOxyG6 = lagTimeOxyG6(ind,:);
lagTimeOxyG6 = reshape(lagTimeOxyG6,size(xform_mask));
imagesc(lagTimeOxyG6,'AlphaData',xform_mask,[-0.5 0.5]); colormap('jet'); colorbar; axis(gca,'square');
xlim([1 size(xform_mask,2)]); ylim([1 size(xform_mask,1)]);
set(gca,'Visible','off');

p.margin = [3 0 15 0];
