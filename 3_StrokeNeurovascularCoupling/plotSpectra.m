load('D:\ProcessedData\hbtSpectra_gsr-2-43.mat');

hbT = permute(spectra,[1 2 4 3]);
hbT = reshape(hbT,[],numel(freq));
hbT = hbT(mask>0,:);
hbT = mean(hbT,1);

load('D:\ProcessedData\g6corrSpectra_gsr-2-43.mat');

g6c = permute(spectra,[1 2 4 3]);
g6c = reshape(g6c,[],numel(freq));
g6c = g6c(mask>0,:);
g6c = mean(g6c,1);

validFreq = freq < 3;
g6c = g6c(validFreq);
hbT = hbT(validFreq);
freq = freq(validFreq);

%%

figure;
loglog(freq,1E6*hbT,'LineWidth',3); hold on;
loglog(freq,g6c,'LineWidth',3);

ylabel('Power (log 10)');
xlabel('Frequency (Hz, log 10)');

xlim([min(freq) max(freq)]);
legend('HbT (mM)','G6 corrected (ratiometric)');