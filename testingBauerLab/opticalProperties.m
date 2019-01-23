% small script to explore optical properties

systemInfo = mouse.expSpecific.sysInfo('fcOIS2_Fluor2');
ledFiles = systemInfo.LEDFiles;
pkgDir = what('bauerParams');

for file = 1:numel(ledFiles)
    ledFiles(file) = fullfile(pkgDir.path,'ledSpectra',ledFiles(file));
end
[op, E] = bauerParams.getHbOpticalProperties(ledFiles);

[sourceSpectra, lambda2] = bauerParams.getSpectra(ledFiles);

figure;
for i = 1:4
plot(lambda2,sourceSpectra{i}.spectrum); hold on;
end

E./1000*log(10)

op.dpf