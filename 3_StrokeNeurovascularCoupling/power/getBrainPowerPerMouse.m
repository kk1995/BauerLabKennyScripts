function [f,y] = getBrainPowerPerMouse(dataFiles,maskFile,sR)
%getBrainPowerPerMouse Gets average power of the whole brain per mouse
%   dataFiles = string array of file locations
%   maskFile = string array of mask file location
%   sR = sampling rate

y = [];
mask = load(maskFile);
mask = mask.mask > 0;
for run = 1:numel(dataFiles)
    load(dataFiles(run),'oxy','deoxy','gcamp6corr');
    runPower = zeros(3,size(oxy,3));
    [f,runPower(1,:)] = getBrainPower(oxy,mask,sR);
    [~,runPower(2,:)] = getBrainPower(deoxy,mask,sR);
    [~,runPower(3,:)] = getBrainPower(gcamp6corr,mask,sR);
    
    y = cat(3,y,runPower);
end
y = nanmean(y,3);
end