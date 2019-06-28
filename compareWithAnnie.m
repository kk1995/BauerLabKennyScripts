data = load('L:\ProcessedData\171211\171211-SAMODM1-fc1-dataHb.mat');
mask = load('L:\ProcessedData\171211\171211-SAMODM1-LandmarksAndMask.mat');
annie = load('L:\ProcessedData\annie2\171211-SAMODM1-fc1-datahb.mat');
vidName = 'L:\ProcessedData\comparison-171211-SAMODM1-fc1.mp4';

annieData = annie.datahb;
annieData = mouse.process.affineTransform(annieData,mask.I);

hb = lowpass(data.xform_datahb,0.08,29.76);
hb = highpass(hb,0.009,29.76);
% time = 0:300;
% hb = resampledata(hb,29.76,1,1E-5);
time = 1:300;
% hb = data.xform_datahb;
hb = mouse.freq.resampledata(hb,data.hbTime,time);

%% get diff

diff = abs(hb(:,:,1,:) - annieData(:,:,1,2:end));
diff = squeeze(diff(:,:,1,:));
diff = reshape(diff,[],size(diff,3));
diffAvg = mean(diff(data.xform_isbrain,:),1);

%% plot

figure;
plot(time,diffAvg);
xlabel('time (s)');
ylabel('delta HbO (M)');
title('Average difference (BauerLab - Annie)');

v = VideoWriter(vidName);
v.FrameRate = 1;
open(v);
figure('Position',[100 100 900 300]);
for i = 1:300
    subplot(1,3,1)
    imagesc(squeeze(hb(:,:,1,i)),[-5 5]*1E-6); axis(gca,'square'); colormap('jet');
    title(['BauerLab pipeline, ' num2str(time(i))]); colorbar;
    subplot(1,3,2)
    imagesc(squeeze(annieData(:,:,1,i+1)),[-5 5]*1E-6); axis(gca,'square'); colormap('jet');
    title('Annie pipeline'); colorbar;
    subplot(1,3,3)
    imagesc(squeeze(hb(:,:,1,i))-squeeze(annieData(:,:,1,i+1)),[-1 1]*1E-6); axis(gca,'square'); colormap('jet');
    title('BauerLab - Annie'); colorbar;
    frame = getframe(gcf);
    writeVideo(v,frame);
end
close(v);
