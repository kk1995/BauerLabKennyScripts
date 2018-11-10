% toy data

data = reshape(1:256,16,16);

% transform to hilbert curve
transData = hilbertCurve(data);

% reverse transform to 2D
twoDimData = hilbertCurveRev(transData);

% observation: twoDimData is the same as data, so information is retained
% through the process.

%% Hilbert curve is great for reducing the resolution for faster process!

% toy data
rowLen = 256;
data = zeros(rowLen,rowLen);
for x = 1:rowLen
    for y = 1:rowLen
        data(x,y) = exp(-(0.125/rowLen)*((x-(rowLen+1)/2)^2+(y-(rowLen+1)/2)^2));
    end
end

% transform to hilbert curve
transData = hilbertCurve(data);

% reduce dimensionality
reduceRatio = 16; % has to be power of 4
transData = downsample(transData,reduceRatio);

% reverse transform to 2D
twoDimData = hilbertCurveRev(transData);

% plot
figure('Position',[100 100 1000 400]);
subplot(1,2,1);
imagesc(data,[0 1]);
subplot(1,2,2);
imagesc(twoDimData,[0 1]);