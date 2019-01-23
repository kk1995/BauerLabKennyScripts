[spectra_hdpf, wavelength]=bauerParams.getSpectra("D:\data\hillman_dpf.txt");
spectra_hdpf = spectra_hdpf{1}.spectrum;
spectra_hdpf = spectra_hdpf./10; % cm

% wang dpf
extCoeffFile = "C:\Repositories\GitHub\BauerLab\MATLAB\parameters\+bauerParams\prahl_extinct_coef.txt";
[lambda1, extCoeff] = mouse.expSpecific.getHbExtCoeff(extCoeffFile);
extCoeffNew(:,1) = interp1(lambda1,extCoeff(:,1),wavelength,'pchip');
extCoeffNew(:,2) = interp1(lambda1,extCoeff(:,2),wavelength,'pchip');
extCoeff = extCoeffNew;
conc = 76*10^-6*[0.71 1-0.71]; % concentration of species
% musp = 10; % Reduced Scattering Coefficient (cm-1)

a = 40.8; % 1/cm
% b = 3.089;
b = 1.5;
c = 3*10^10./1.4;
for f = 1:numel(wavelength)
    musp(f) = a*(wavelength(f)/500)^-b;
%     musp(f) = 10;
    mua(f) = log(10)*conc*extCoeff(f,:)';
    gamma = sqrt(c) ./ sqrt(3 * (mua(f) + musp(f)));
    dpf(f) = (c/musp(f))*(1./(2*gamma.*sqrt(mua(f)*c))).*(1+(3/c).*mua(f).*gamma.^2);
end

%% plot
figure;
plot(wavelength,mua)
hold on;
plot(wavelength,musp)

figure;
plot(wavelength,spectra_hdpf);
hold on;
plot(wavelength,dpf);