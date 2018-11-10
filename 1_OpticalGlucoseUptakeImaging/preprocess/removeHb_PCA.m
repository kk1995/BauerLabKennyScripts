date = '180813'; mouse = 'ProbeW3M1';
% date = '180713'; mouse = 'NewProbeM4W5';
% date = '180716'; mouse = 'NewProbeM1W6';
dataDir = ['D:\data\' date];
pathLen = 0.01; % cm, 1 way
% hbTConc = 2.3256; % mmol/liter = (150 g/liter) / (64500 g/mole) * (1000 mmole/mole)
blueWavelength = 454;
greenWavelength = 512;
bluePath = 0.056;
greenPath = 0.057;
extCoeffFile = 'C:\Repositories\GitHub\OIS\Spectroscopy\prahl_extinct_coef.txt';
ledFiles = {'C:\Repositories\GitHub\OIS\Spectroscopy\LED Spectra\150917_TL_470nm_Pol.txt',...
    'C:\Repositories\GitHub\OIS\Spectroscopy\LED Spectra\150917_Mtex_530nm_Pol.txt',...
    'C:\Repositories\GitHub\OIS\Spectroscopy\LED Spectra\150917_TL_590nm_Pol.txt'...
    'C:\Repositories\GitHub\OIS\Spectroscopy\LED Spectra\150917_TL_628nm_Pol.txt'};
opticalFiles = 'D:\data\opticalProperties\mouseOpticalProperties.mat';

saveFile = fullfile(dataDir,[date '-' mouse '-fluorHbRemoved.mat']);
%% load

load(fullfile(dataDir,[date '-' mouse '-Pre-GSR.mat']));
xform_preHb = xform_datahb;
xform_preFluor = xform_dataFluorDetrended;
preT = t_Fluor;

load(fullfile(dataDir,[date '-' mouse '-Post-GSR.mat']));
xform_postHb = xform_datahb;
xform_postFluor = xform_dataFluorDetrended;
postT = t_Fluor;

%% get dpf
[led, lambda2] = getLEDs(ledFiles);
[lambda, extCoeff]=getHb(extCoeffFile);
load(opticalFiles);
% conc = hbTConc*[0.71 0.29];
% pathLenLambdaCorrected = nan(numel(led),1);
% for n = 1:numel(led)
%     lightPower = interp1(lambda2,led{n}.spectrum,lambda,'pchip');
%     dpf = diffPathFac(op.c,op.musp,extCoeff,conc,lightPower);
%     pathLenLambdaCorrected(n) = pathLen/dpf;
% end
% 
% bluePath = pathLenLambdaCorrected(1);
% greenPath = pathLenLambdaCorrected(2);

%%

blueLambdaInd = find(lambda == blueWavelength);
greenLambdaInd = find(lambda == greenWavelength);

hbOAbsCoeff = extCoeff([blueLambdaInd greenLambdaInd],1);
hbRAbsCoeff = extCoeff([blueLambdaInd greenLambdaInd],2);

preFluorHbRemoved = nan(size(xform_preFluor));
preFluorFraction = nan(size(xform_preFluor));

meanPreFluor = mean(xform_preFluor,4);

for y = 1:128
    for x = 1:128
        if xform_isbrain(y,x)
            hbOData = squeeze(xform_preHb(y,x,1,:)); % mmol/l
            hbRData = squeeze(xform_preHb(y,x,2,:));
            
            fluorData = squeeze(xform_preFluor(y,x,1,:)); % abs intensity
            fluorDataChange = fluorData/mean(fluorData);
            fluorDataChange = log(fluorDataChange);
            
            pcaInput = [hbOData hbRData fluorDataChange];
            [coeff, score] = pca(pcaInput);
            
%             [fluorDataHbRemoved, preFluorFraction(y,x,1,:)] = rmvHbAbsLen(fluorData,hbOData,hbRData,...
%                 hbOAbsCoeff,hbRAbsCoeff);
            
            
%             preFluorHbRemoved(y,x,1,:) = fluorDataHbRemoved;
        end
    end
end

postFluorHbRemoved = nan(size(xform_postFluor));
postFluorFraction = nan(size(xform_postFluor));
for y = 1:128
    for x = 1:128
        if xform_isbrain(y,x)
            hbOData = squeeze(xform_postHb(y,x,1,:));
            hbRData = squeeze(xform_postHb(y,x,2,:));
            
            fluorData = squeeze(xform_postFluor(y,x,1,:));
            fluorDataChange = fluorData/mean(fluorData);
            fluorDataChange = log(fluorDataChange);
            
            pcaInput = [hbOData hbRData fluorDataChange];
            [coeff, score, latent] = pca(pcaInput,'Centered',false);
            
            
%             [fluorDataHbRemoved, postFluorFraction(y,x,1,:)] = rmvHbAbsLen(fluorData,hbOData,hbRData,...
%                 hbOAbsCoeff,hbRAbsCoeff);
            
%             postFluorHbRemoved(y,x,1,:) = fluorDataHbRemoved;
        end
    end
end

% preFluorHbRemoved = -logmean(preFluorHbRemoved);
% postFluorHbRemoved = -logmean(postFluorHbRemoved);

%% plot
% cMap = blueWhiteRed(100);
% 
% postFluorFractionCell = catByTime(postFluorFraction,postT,[0.5:59.5; 1.5:60.5]);
% 
% figure('Position',[50 200 600 500]);
% imAlpha=ones(128,128);
% imAlpha(isnan(squeeze(postFluorFraction(:,:,1,1))))=0;
% for i = 1:60
%     imagesc(squeeze(mean(postFluorFractionCell{i},4)),'AlphaData',imAlpha,[0.95 1.05]);
%     set(gca,'color',0.5*[1 1 1]);
%     colormap(cMap);
%     colorbar;
%     title(['t = ' num2str(i)]);
%     pause(0.2);
% end

% figure('Position',[50 200 600 500]);
% imAlpha=ones(size(squeeze(preFluorHbRemoved(:,:,1,1))));
% imAlpha(isnan(squeeze(preFluorHbRemoved(:,:,1,1))))=0;
% for i = 1:60
%     imagesc(squeeze(preFluorHbRemoved(:,:,1,i)),'AlphaData',imAlpha,[-0.05 0.05]);
%     set(gca,'color',0.5*[1 1 1]);
%     colormap(cMap);
%     colorbar;
%     title(['t = ' num2str(i)]);
%     pause(0.2);
% end

%% save

save(saveFile,'xform_isbrain','preFluorHbRemoved','preFluorFraction','postFluorHbRemoved','postFluorFraction','preT','postT');
