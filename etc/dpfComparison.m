extCoeffFile = "C:\Repositories\GitHub\BauerLab\MATLAB\parameters\+bauerParams\prahl_extinct_coef.txt";

nin=1.4; % Internal Index of Refraction
c=3*10^10/nin; % Speed of Light in the Medium (cm/s)
musp=10; % Reduced Scattering Coefficient (cm-1)
HbT=76*10^-6; % M concentration
sO2=0.71; % Oxygen saturation (%/100)
conc = HbT*[sO2 1-sO2]; % concentration of species

[lambda1, extCoeff] = mouse.expSpecific.getHbExtCoeff(extCoeffFile);

for lambdaInd = 1:numel(lambda1)
    dpf(lambdaInd) = mouse.physics.diffPathFac(c,musp,extCoeff(lambdaInd,:),conc);
end

for lambdaInd = 1:numel(lambda1)
    dpf2(lambdaInd) = mouse.physics.diffPathFac2(c,musp,extCoeff(lambdaInd,:),conc);
end

%% plot

plot(lambda1,dpf); hold on; plot(lambda1,dpf2); legend('original','Wang 1995')
