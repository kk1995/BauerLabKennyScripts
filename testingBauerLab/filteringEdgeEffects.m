load('L:\ProcessedData\190523\190523-G11M2-awake-fc1-datafluor.mat');

data = reshape(xform_datafluorCorr,128*128,[]);

refseeds=GetReferenceSeeds;
refseeds = refseeds(1:14,:);
mm=10;
mpp=mm/128;
seedradmm=0.25;
seedradpix=seedradmm/mpp;
P=burnseeds(refseeds,seedradpix,xform_isbrain);  
data = data(P==7,:); data = mean(data,1);

%% 

fMin = 0.009; fMax = 0.08;
sR = 20;

%%

isaNorm = highpass(data,fMin,sR);
isaNorm = lowpass(isaNorm,fMax,sR);

figure; plot(data); hold on; plot(isaNorm);
title('All data ISA');

%%

isaPart = highpass(data(11:end),fMin,sR);
isaPart = lowpass(isaPart,fMax,20);

figure; plot(data(11:end)); hold on; plot(isaPart);
title('First 10 frames removed ISA');

%%

isaPart = highpass(data(1001:end),fMin,sR);
isaPart = lowpass(isaPart,fMax,20);

figure; plot(data(1001:end)); hold on; plot(isaPart);
title('First 1000 frames removed ISA');

%%

isaMirror = mouse.freq.filterData(data,fMin,fMax,sR);

figure; plot(data); hold on; plot(isaMirror);
title('All data with edge mirrored ISA');