date = '180813'; mouse = 'ProbeW3M1';
% date = '180713'; mouse = 'NewProbeM4W5';
% date = '180716'; mouse = 'NewProbeM1W6';
dataDir = ['D:\data\' date];
bluePath = 0.056;
greenPath = 0.057;
% hbTConc = 2.3256; % mmol/liter = (150 g/liter) / (64500 g/mole) * (1000 mmole/mole)
% blueWavelength = 454;
% greenWavelength = 512;
extCoeffFile = 'C:\Repositories\GitHub\OIS\Spectroscopy\prahl_extinct_coef.txt';
% ledFiles = {'C:\Repositories\GitHub\OIS\Spectroscopy\LED Spectra\150917_TL_470nm_Pol.txt',...
%     'C:\Repositories\GitHub\OIS\Spectroscopy\LED Spectra\150917_Mtex_530nm_Pol.txt',...
%     'C:\Repositories\GitHub\OIS\Spectroscopy\LED Spectra\150917_TL_590nm_Pol.txt'...
%     'C:\Repositories\GitHub\OIS\Spectroscopy\LED Spectra\150917_TL_628nm_Pol.txt'};
% opticalFiles = 'D:\data\opticalProperties\mouseOpticalProperties.mat';

saveFile = fullfile(dataDir,[date '-' mouse '-fluorHbRemoved.mat']);
%% load

info.nVx = 128;
info.nVy = 128;
info.highpass = 0.009;
info.lowpass = 0.5 - eps;
info.framerate = 1;
info.numled=3;

load(fullfile(dataDir,[date '-' mouse '-Post-GSR.mat']));
xform_preHb = xform_datahb;
gcamp6Pre = xform_dataFluorDetrended;
preT = t_Fluor;

load(fullfile(dataDir,[date '-' mouse '-Post-GSR.mat']));
xform_postHb = xform_datahb;
gcamp6Post = xform_dataFluorDetrended;
postT = t_Fluor;

%%

preFluorHbRemoved = nan(info.nVy,info.nVx,1,size(xform_preHb,4));
postFluorHbRemoved = nan(info.nVy,info.nVx,1,size(xform_postHb,4));

disp('Getting Optical Properties')
[op, E]=getop(extCoeffFile);

%Ratiometric correction (mean normalization first, then ratio of gcamp to
%green)
for x=1:128
    for y=1:128
        gcamp6normPre(x,y,:)=gcamp6Pre(x,y,:)/mean(gcamp6Pre(x,y,:));
        gcamp6normPost(x,y,:)=gcamp6Post(x,y,:)/mean(gcamp6Post(x,y,:));
    end
end

disp('Processing Pixels')

xsize=info.nVx;
ysize=info.nVy;

%Ex-Em hemodynamic correction
for x=1:xsize
    for y=1:ysize
        bluemua_init(y,x,1,:)=op.blueLEDextcoeff(1)*xform_preHb(y,x,1,:);
        bluemua_init(y,x,2,:)=op.blueLEDextcoeff(2)*xform_preHb(y,x,2,:);
        bluemua_f(y,x,:)=bluemua_init(y,x,1,:)+bluemua_init(y,x,2,:);
        greenmua_init(y,x,1,:)=op.greenLEDextcoeff(1)*xform_preHb(y,x,1,:);
        greenmua_init(y,x,2,:)=op.greenLEDextcoeff(2)*xform_preHb(y,x,2,:);
        greenmua_f(y,x,:)=greenmua_init(y,x,1,:)+greenmua_init(y,x,2,:);
        
        preFluorHbRemoved(y,x,1,:)=gcamp6normPre(y,x,:)./(exp(-(bluemua_f(y,x,:).*bluePath+greenmua_f(y,x,:).*greenPath)));
        %e(y,x,:)=(exp(-(bluemua_f(y,x,:).*(.056)+greenmua_f(y,x,:).*(.057))));
        %%e is correction factor
        
        preFluorHbRemoved(y,x,1,:)=procPixel2(squeeze(preFluorHbRemoved(y,x,1,:))',op,E,info);
        
        bluemua_init(y,x,1,:)=op.blueLEDextcoeff(1)*xform_postHb(y,x,1,:);
        bluemua_init(y,x,2,:)=op.blueLEDextcoeff(2)*xform_postHb(y,x,2,:);
        bluemua_f(y,x,:)=bluemua_init(y,x,1,:)+bluemua_init(y,x,2,:);
        greenmua_init(y,x,1,:)=op.greenLEDextcoeff(1)*xform_postHb(y,x,1,:);
        greenmua_init(y,x,2,:)=op.greenLEDextcoeff(2)*xform_postHb(y,x,2,:);
        greenmua_f(y,x,:)=greenmua_init(y,x,1,:)+greenmua_init(y,x,2,:);
        
        postFluorHbRemoved(y,x,1,:)=gcamp6normPost(y,x,:)./(exp(-(bluemua_f(y,x,:).*bluePath+greenmua_f(y,x,:).*greenPath)));
        %e(y,x,:)=(exp(-(bluemua_f(y,x,:).*(.056)+greenmua_f(y,x,:).*(.057))));
        %%e is correction factor
        
        postFluorHbRemoved(y,x,1,:)=procPixel2(squeeze(postFluorHbRemoved(y,x,1,:))',op,E,info);
    end
end

save(saveFile,'xform_isbrain','preFluorHbRemoved','postFluorHbRemoved','preT','postT');

%% getop()
function [op, E, numled, led]=getop(extCoeffFile)

[lambda1, Hb]=getHb(extCoeffFile);
[led,lambda2]=getLED;
   
op.HbT=76*10^-3; % uM concentration
op.sO2=0.71; % Oxygen saturation (%/100)
op.BV=0.1; % blood volume (%/100)

op.nin=1.4; % Internal Index of Refraction
op.nout=1; % External Index of Refraction
op.c=3e10/op.nin; % Speed of Light in the Medium
op.musp=10; % Reduced Scattering Coefficient

numled=size(led,2);


for n=1:numled                                                            
    
    %if n==1 || n==2 || n==3
    % Interpolate from Spectrometer Wavelengths to Reference Wavelengths
    led{n}.ledpower=interp1(lambda2,led{n}.spectrum,lambda1,'pchip');
    
    % Normalize
    led{n}.ledpower=led{n}.ledpower/max(led{n}.ledpower);
    
    % Zero Out Noise
    led{n}.ledpower(led{n}.ledpower<0.01)=0;
    
    % Normalize
    led{n}.ledpower=led{n}.ledpower/sum(led{n}.ledpower);
    
    % Absorption Coeff.
    op.mua(n)=sum((Hb(:,1)*op.HbT*op.sO2+Hb(:,2)*op.HbT*(1-op.sO2)).*led{n}.ledpower);
    
    % Diffusion Coefficient
    op.gamma(n)=sqrt(op.c)/sqrt(3*(op.mua(n)+op.musp));
    op.dc(n)=1/(3*(op.mua(n)+op.musp));
    
    % Spectroscopy Matrix
    E(n,1)=sum(Hb(:,1).*led{n}.ledpower);
    E(n,2)=sum(Hb(:,2).*led{n}.ledpower);
    %assignin('base','E',E); return
    
    % Differential Pathlength Factors
    op.dpf(n)=(op.c/op.musp)*(1/(2*op.gamma(n)*sqrt(op.mua(n)*op.c)))*(1+(3/op.c)*op.mua(n)*op.gamma(n)^2);
    %end

end
    op.blueLEDextcoeff(1)=Hb(103,1);%*led{n}.ledpower; 454nm
    op.blueLEDextcoeff(2)=Hb(103,2);
    op.greenLEDextcoeff(1)=Hb(132,1);%*led{n}.ledpower; 512nm
    op.greenLEDextcoeff(2)=Hb(132,2);

end

%% getLED()
function [led, lambda]=getLED


folderName = 'C:\Users\Kenny\Downloads\ForAnnie';
led{1}.name='131029_Mightex_530nm_NoBPFilter';
led{2}.name='140801_ThorLabs_590nm_NoPol'; 
led{3}.name='140801_ThorLabs_625nm_NoPol';  

numled=size(led,2);

%Read in LED spectra data from included text files
for n=1:numled
    

        fid=fopen(fullfile(folderName,[led{n}.name, '.txt']));
        temp=textscan(fid,'%f %f','headerlines',17);
        fclose(fid);
        lambda=temp{1};
        led{n}.spectrum=temp{2};
  
end

end

%% procPixel()
function [data_dot]=procPixel(data,op,E,info)


% disp('Rytov and DPFs')

data=logmean(data);

for c=1:info.numled
    data(c,:)=squeeze(data(c,:))/op.dpf(c);
    %data_dot(c,:)=squeeze(data(c,:))/op.dpf(c);
end
% 
% 
[data]=highpass(data,info.highpass,info.framerate); %UNCOMMENT TO FILTER
% %NEXT LINE TOO
[data]=lowpass(data,info.lowpass,info.framerate);


data_dot=dotspect(data,E(1:3,:));

end


function [data2]=procPixel2(data,op,E,info)


%disp('Rytov and DPFs')
data=-logmean(data);

[data]=highpass(data,info.highpass,info.framerate);
[data2]=lowpass(data,info.lowpass,info.framerate); %uNCOMMENT PLUS ^ TO
%FILTER
%data2=data; %LEAVE THIS COMMENTED

end
