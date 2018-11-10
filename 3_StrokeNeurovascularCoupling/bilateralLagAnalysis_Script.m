fRange = [0.009 0.5; ...
    0.5 5]; % 1st col is minimum frequency
tZone = [7; 2]; % in seconds
corrThr = 0.3;

bilateralLagStroke(1:56,fRange,16.81,tZone,false,corrThr);

bilateralLagStroke(1:56,fRange,16.81,tZone,true,corrThr);