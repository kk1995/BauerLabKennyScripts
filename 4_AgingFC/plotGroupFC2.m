dataFile = "L:\ProcessedData\deborah\avgFC_gsr.mat";
atlasFile = "D:\data\atlas12.mat";

load(dataFile,'yvFC','ovFC');
load(atlasFile);

labels = {'Frontal','Motor','SS','RS','Parietal','Visual'};
labels = repmat(labels,1,2);

f1 = mouse.expSpecific.plotPixelFC(yvFC,isinf(yvFC(1:size(yvFC,1)+1:end)),atlas(:),labels);
f2 = mouse.expSpecific.plotPixelFC(ovFC,isinf(ovFC(1:size(ovFC,1)+1:end)),atlas(:),labels);
mask = isinf(yvFC(1:size(yvFC,1)+1:end)) & isinf(ovFC(1:size(ovFC,1)+1:end));
f3 = mouse.expSpecific.plotPixelFC(ovFC-yvFC,mask,atlas(:),labels,[-0.3 0.3]);