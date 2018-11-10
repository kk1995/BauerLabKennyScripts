% make toy data
data = normrnd(0,1,10000,1);
sR = 50;

% parameters
fMin = 3;
fMax = 5;
ind = [1 numel(data)];

% make wavelet for that freq
fCenter = (fMin + fMax)/2;
fwhm = fMax - fMin;
wavelet = makeGabor(fCenter,fwhm,sR);

% select the data. Edges are considered to reduce edge effects.
edgeLength = round(numel(wavelet)/2);
[selectedData, realInd, hasFalse] = selectWithEdges(data,ind,edgeLength);

% filter
filtData = conv(selectedData,wavelet,'same');
filtData = filtData(realInd(1):realInd(2));

% plot
figure;
t = 0:numel(filtData)-1; t = t./sR;
plot(t,real(filtData));
xlim([0 10]);