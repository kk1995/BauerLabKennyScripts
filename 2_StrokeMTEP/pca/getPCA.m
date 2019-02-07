rawFile1 = "D:\data\StrokeMTEP\SHAM_Groups_Tad.mat";
rawFile2 = "D:\data\StrokeMTEP\PT_Groups_Tad_single.mat";
saveFile = "D:\data\StrokeMTEP\MTEP_PT-Veh_PT_PCA.mat";

%%
load(rawFile2,'Veh_PT');

data1 = nanmean(Veh_PT,3);

load(rawFile2,'MTEP_PT');

data2 = nanmean(MTEP_PT,3);
diff = data2 - data1;

% diagonal
dInd = 1:size(data1,1)+1:numel(data1);
diff(dInd) = 0;
data1(dInd) = inf;
data2(dInd) = inf;

%% pca

[coeff,score,latent,~,~,mu] = pca(diff);

%%

save(saveFile,'diff','coeff','score','latent','mu','-v7.3');