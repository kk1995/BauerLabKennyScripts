fMin = 2;
sR = 100;
butterOrder = 5;
edgeLen = 3;
relevantInd = 30:80;

[b,a] = butter(butterOrder,fMin/(sR/2),'high');

data1Filt = filtfilt(b,a,data1);
data2Filt = filtfilt(b,a,data2);

[lagTime,lagAmp,covResult] = findLag(data1Filt(relevantInd),data2Filt(relevantInd),edgeLen);