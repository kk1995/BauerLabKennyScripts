saveFileLoc = "D:\data\190217-R1M2124KET";
hbFileName = strcat(saveFileLoc,"-datahb.mat");
fluorFileName = strcat(saveFileLoc,"-dataFluor.mat");
load(hbFileName); load(fluorFileName)
maskFileName = "C:\Users\Kenny\Box\ToKenny\190217-R1M2124KET-LandmarksandMarks.mat";
mask = load(maskFileName);
%%

xform_isbrain = mouse.process.affineTransform(mask.isbrain,mask.I);

hb = mouse.process.gsr(xform_datahb,xform_isbrain);
fluor = mouse.process.gsr(xform_datafluor,xform_isbrain);
fluorCorr = mouse.process.gsr(xform_datafluorCorr,xform_isbrain);

data = cat(3,hb,fluor,fluorCorr);

%%

[blockData,blockTime] = mouse.preprocess.blockAvg(data,rawTime,30,240);
stimInd = mod(blockTime,30) > 9 & mod(blockTime,30) < 11;
stimResponse = blockData(:,:,:,stimInd); stimResponse = mean(stimResponse,4);
roi = mouse.expSpecific.getROI(stimResponse(:,:,1),[85 21]);
roiData = reshape(blockData,128*128,[],size(blockData,4));
roiData = roiData(roi,:,:); roiData = squeeze(mean(roiData,1));
roiData = bsxfun(@minus,roiData,mean(roiData,2));

%%

figure;
plot(blockTime,roiData(1,:),'r'); hold on; plot(blockTime,roiData(2,:),'b'); hold off; 

figure;
plot(blockTime,roiData(3,:),'g'); hold on; plot(blockTime,roiData(4,:),'m'); hold off;