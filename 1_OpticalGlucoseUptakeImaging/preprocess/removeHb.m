% date = '180713'; mouse = 'NewProbeM3W5';
% date = '180713'; mouse = 'NewProbeM4W5';
% date = '180716'; mouse = 'NewProbeM1W6';\

% dateList = {'180713','180713','180716','180716','180716','180718'};
% mouseList = {'NewProbeM3W5','NewProbeM4W5','NewProbeM1W6','NewProbeM2W6','NewProbeM3W6','NewProbeM1W5'};
dateList = {'181108'};
mouseList = {'ProbeW5M1'};

extCoeffFile = 'C:\Repositories\GitHub\OIS\Spectroscopy\prahl_extinct_coef.txt';
blueWavelength = 454; % nm
greenWavelength = 512;

for animal = 1:numel(mouseList)
% for animal = 1
    
    date = dateList{animal}; mouse = mouseList{animal};
    dataDir = ['D:\data\' date];
    
    saveFile = fullfile(dataDir,[date '-' mouse '-fluorHbRemoved.mat']);

    %% load
    load(fullfile(dataDir,[date '-' mouse '-LandmarksandMask.mat']));
    load(fullfile(dataDir,[date '-' mouse '-Pre-GSR-Resampled.mat']));
    xform_preHb = xform_hb;
    xform_preFluor = xform_fluor;
    preT = t_fluor;
    
    load(fullfile(dataDir,[date '-' mouse '-Post-GSR-Resampled.mat']));
    xform_postHb = xform_hb;
    xform_postFluor = xform_fluor;
    postT = t_fluor;

    %%

    [lambda, extCoeff]=mouseAnalysis.expSpecific.getHb(extCoeffFile);

    blueLambdaInd = find(lambda == blueWavelength);
    greenLambdaInd = find(lambda == greenWavelength);
    
    hbOAbsCoeff = extCoeff([blueLambdaInd greenLambdaInd],1);
    hbRAbsCoeff = extCoeff([blueLambdaInd greenLambdaInd],2);
    
    bluePath = 0.056;
    greenPath = 0.057;
    
    xform_preFluorCorr = mouseAnalysis.physics.correctHb(xform_preFluor,xform_preHb,...
        hbOAbsCoeff,hbRAbsCoeff,bluePath,greenPath);
    
    xform_postFluorCorr = mouseAnalysis.physics.correctHb(xform_postFluor,xform_postHb,...
        hbOAbsCoeff,hbRAbsCoeff,bluePath,greenPath);

    %% save
    
    save(saveFile,'xform_isbrain','xform_preFluorCorr','xform_postFluorCorr','preT','postT');
    
end