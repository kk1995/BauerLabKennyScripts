dataFile = 'D:\data\170126\170126-2541_baseline-dataGCaMP-fc1.mat';
sR = 16.8;
fMin = 0.02;
fMax = 2;

load(dataFile);
data = [];
data = cat(3,data,reshape(oxy,[128 128 1 size(oxy,3)])+reshape(deoxy,[128 128 1 size(deoxy,3)]));
data = cat(3,data,reshape(gcamp6corr,[128 128 1 size(gcamp6corr,3)]));

filteredData = filterData(data,fMin,fMax,sR);

%% plot

figure('Position',[100 100 600 300]);
for frame = 1:size(filteredData,4)
    t = (frame - 1)./sR;
    
    s = subplot(1,2,1);
    imagesc(squeeze(filteredData(:,:,2,frame)),'AlphaData',xform_mask,[-0.015 0.015]);
    axis(s,'square');
    title(['GCaMP ' num2str(t)]);
    
    s = subplot(1,2,2);
    imagesc(squeeze(filteredData(:,:,1,frame)),'AlphaData',xform_mask,[-0.001 0.001]);
    axis(s,'square');
    title(['HbT ' num2str(t)]);
    
    pause(1/sR);
end