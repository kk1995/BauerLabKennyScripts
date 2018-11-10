date = '180713';
mouse = 'NewProbeM4W5';
dataDir = ['D:\data\' date];
saveFile = fullfile(dataDir,[date '-' mouse '-fluorHbRemoved.mat']);
load(fullfile(dataDir,[date '-' mouse '-Pre-GSR.mat']));
xform_preHb = xform_datahb;
xform_preFluor = xform_dataFluor;

load(fullfile(dataDir,[date '-' mouse '-Post-GSR.mat']));
xform_postHb = xform_datahb;
xform_postFluor = xform_dataFluor;

highPassFreq = 0.05; % Hz

xform_preFluor = highpass(xform_preFluor,highPassFreq,1);
xform_postFluor = highpass(xform_postFluor,highPassFreq,1);

hbFluorFitMat = nan(128,128,3,2); % spatial y, spatial x, species (HbO, HbR, HbT), 2 weights of linear function
hbFluorFitR = nan(128,128,3);
for species = 1:3
    for y = 1:128
        for x = 1:128
            if xform_isbrain(y,x)
                if species == 3
                    hbSpecies = 1:2;
                else
                    hbSpecies = species;
                end
                hbVal = squeeze(sum(xform_preHb(y,x,hbSpecies,:),3));
                fluorVal = squeeze(xform_preFluor(y,x,1,:));
                
%                 X = [ones(length(hbVal),1) hbVal];
%                 hbFluorFitMat(y,x,species,:) = X\fluorVal;
                
                p = polyfit(hbVal,fluorVal,1);
                yfit = polyval(p,hbVal);
                yresid = fluorVal - yfit;
                SSresid = sum(yresid.^2);
                SStotal = (length(fluorVal)-1) * var(fluorVal);
                rsq = 1 - SSresid/SStotal;
                hbFluorFitMat(y,x,species,:) = p;
                hbFluorFitR(y,x,species) = rsq;
            end
        end
    end
end

xform_postFluor_HbRemoved = zeros(size(xform_postFluor));
species = 3;
for y = 1:128
    for x = 1:128
        if xform_isbrain(y,x)
            if species == 3
                hbSpecies = 1:2;
            else
                hbSpecies = species;
            end
            hbVal = squeeze(sum(xform_postHb(y,x,hbSpecies,:),3));
            fluorVal = squeeze(xform_postFluor(y,x,1,:));
            
            hbBlue = polyval(squeeze(hbFluorFitMat(y,x,species,:)),hbVal);
            xform_postFluor_HbRemoved(y,x,1,:) = fluorVal - hbBlue;
        end
    end
end

xform_postFluor = smoothimage(xform_postFluor,5,1.2); % spatially smooth data
xform_postFluor_HbRemoved = smoothimage(xform_postFluor_HbRemoved,5,1.2); % spatially smooth data

postFluorSize = size(xform_postFluor_HbRemoved);
xform_postFluor_HbRemoved = reshape(xform_postFluor_HbRemoved,postFluorSize(1)*postFluorSize(2),postFluorSize(3),postFluorSize(4));
xform_postFluor_HbRemoved(~xform_isbrain(:),:,:) = nan;
xform_postFluor_HbRemoved = reshape(xform_postFluor_HbRemoved,postFluorSize);

xform_postFluor = reshape(xform_postFluor,postFluorSize(1)*postFluorSize(2),postFluorSize(3),postFluorSize(4));
xform_postFluor(~xform_isbrain(:),:,:) = nan;
xform_postFluor = reshape(xform_postFluor,postFluorSize);

%% plot
cMap = blueWhiteRed(100);

figure('Position',[50 200 1200 500]);
imAlpha=ones(size(squeeze(xform_postFluor(:,:,1,1))));
imAlpha(isnan(squeeze(xform_postFluor_HbRemoved(:,:,1,1))))=0;
for i = 1:60
    subplot(1,2,1);
    imagesc(squeeze(xform_postFluor(:,:,1,i)),'AlphaData',imAlpha,[-20 20]);
    set(gca,'color',0.5*[1 1 1]);
    colormap(cMap);
    colorbar;
    title(['t = ' num2str(i)]);
    
    subplot(1,2,2);
    imagesc(squeeze(xform_postFluor_HbRemoved(:,:,1,i)),'AlphaData',imAlpha,[-20 20]);
    set(gca,'color',0.5*[1 1 1]);
    colormap(cMap);
    colorbar;
    title(['t = ' num2str(i)]);
    pause(0.5);
end

%% save

save(saveFile,'xform_isbrain','xform_postFluor','xform_postFluor_HbRemoved','t_Fluor');

%% smoothimage()
function [data2]=smoothimage(data,gbox,gsigma)

[nVx nVy cnum T]=size(data);

% Gaussian box filter center
x0=ceil(gbox/2);
y0=ceil(gbox/2);

% Make Gaussian filter
G=zeros(gbox);
for x=1:gbox
    for y=1:gbox
        G(x,y)=exp((-(x-x0)^2-(y-y0)^2)/(2*gsigma^2));
    end
end

% normalize Gaussian to 1
G=G/sum(sum(G));

% Initialize
data2=zeros(nVx,nVy,cnum,T);

% convolve data with filter
for c=1:cnum
    for t=1:T
        data2(:,:,c,t)=conv2(squeeze(data(:,:,c,t)),G,'same');
    end
end

end