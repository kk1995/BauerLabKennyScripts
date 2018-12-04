dataFile = "K:\Proc2\170126\170126-2541_baseline-dataGCaMP-stim1.mat";
maskFile = "D:\data\170126\170126-2541_baseline-LandmarksandMask.mat";
load(dataFile); % oxy, deoxy, gcamp6, gcamp6corr, info
load(maskFile); % xform_mask, xform_WL

%% get hemoglobin total and mask

hbT = oxy + deoxy;
mask = xform_mask;

%% let's try looking at hemoglobin and gcamp together with delay between them

sR = info.framerate;
tDelay = 0; % seconds

figure('Position',[100 100 600 300]);
numFrames = size(gcamp6corr,3);
for frameGcamp6 = 1:numFrames
    frameHbT = frameGcamp6 + round(tDelay*sR);

    if frameGcamp6 > 0
        subplot(1,2,1); imagesc(gcamp6corr(:,:,frameGcamp6),'AlphaData',mask,[-0.04 0.04]);
        colormap('jet'); colorbar; axis(gca,'square');
        set(gca,'xtick',[]); set(gca,'ytick',[]);
        hold on; title(['G6 ' num2str(frameGcamp6/sR)]);
    end
    if frameHbT > 0 && frameHbT <= numFrames
        subplot(1,2,2); imagesc(oxy(:,:,frameHbT),'AlphaData',mask,[-0.004 0.004]);
        colormap('jet'); colorbar; axis(gca,'square');
        set(gca,'xtick',[]); set(gca,'ytick',[]);
        hold on; title(['HbO ' num2str(frameHbT/sR)]);
    end
    pause(0.1);
end