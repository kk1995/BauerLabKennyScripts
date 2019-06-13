function [mousePowerMap,f] = getPowerMapPerMouse(dataFiles,fRange,sR)
%getPowerMapPerMouse Gets map of power at certain band
%   dataFiles = string array of file locations
%   maskFile = string array of mask file location
%   sR = sampling rate

mousePowerMap = [];
for run = 1:numel(dataFiles)
    load(dataFiles(run),'oxy','deoxy','gcamp6corr');
    ySize = size(oxy,1); xSize = size(oxy,2);
    runPowerMaps = zeros(ySize,xSize,3);
    
    
    for species = 1:3
        if species == 1
            runData = oxy;
        elseif species == 2
            runData = deoxy;
        else
            runData = gcamp6corr;
        end
        
        runData = reshape(runData,[],size(runData,3));
        [runPowerMap,f] = pwelch(runData',[],[],[],sR);
        fInd = f >= fRange(1) & f <= fRange(2);
        runPowerMap = nanmean(runPowerMap(fInd,:),1);
        runPowerMap = reshape(runPowerMap,ySize,xSize);
        
        runPowerMaps(:,:,species) = runPowerMap;
    end
    
    mousePowerMap = cat(4,mousePowerMap,runPowerMaps);
end
mousePowerMap = nanmean(mousePowerMap,4);
end