%% load data

load('D:\ProcessedData\180713\180713-NewProbeM3W5Pre-datahb.mat');
load('D:\ProcessedData\180713\180713-NewProbeM3W5Pre-dataFluor.mat');

xform_datafluorCorr = bsxfun(@times,xform_datafluorCorr+1,xform_baseline);

preData = cat(3,xform_datahb,xform_datafluorCorr);

load('D:\ProcessedData\180713\180713-NewProbeM3W5Post-datahb.mat');
load('D:\ProcessedData\180713\180713-NewProbeM3W5Post-dataFluor.mat');

xform_datafluorCorr = bsxfun(@times,xform_datafluorCorr+1,xform_baseline);

postData = cat(3,xform_datahb,xform_datafluorCorr);

%% determine vascular roi

preBaseline = mean(preData,4);

% postEnd = postData(:,:,:,size(postData,4));
postEnd = postData(:,:,:,3000);

post2preRatio = postEnd./preBaseline;

%% plot

figure('Position',[100 100 900 400]);
subplot(1,3,1);
imagesc(post2preRatio(:,:,1)); colorbar; axis(gca,'square');
subplot(1,3,2);
imagesc(post2preRatio(:,:,2)); colorbar; axis(gca,'square');
subplot(1,3,3);
imagesc(post2preRatio(:,:,3)); colorbar; axis(gca,'square');