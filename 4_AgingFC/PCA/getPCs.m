dataFile = "L:\ProcessedData\avgFC_gsr.mat";
saveFile = "L:\ProcessedData\ov-yvPCs.mat";
saveFile2 = "L:\ProcessedData\od-ovPCs.mat";

load(dataFile);
diffFC = ovFC-yvFC;
brain = ~isnan(yvFC(1:size(yvFC,1)+1:end)) & ~isnan(ovFC(1:size(ovFC,1)+1:end));
fc = diffFC(brain,brain);
fc(1:size(fc,1)+1:end) = 0;

[coeff, score, latent, tsquared, explained] = pca(fc);

save(saveFile,'coeff','score','latent','tsquared','explained','brain','-v7.3');

diffFC = odFC-ovFC;
brain = ~isnan(odFC(1:size(odFC,1)+1:end)) & ~isnan(ovFC(1:size(ovFC,1)+1:end));
fc = diffFC(brain,brain);
fc(1:size(fc,1)+1:end) = 0;

[coeff, score, latent, tsquared, explained] = pca(fc);

save(saveFile2,'coeff','score','latent','tsquared','explained','brain','-v7.3');