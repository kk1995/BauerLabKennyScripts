dataDir = {'D:\data\zachRosenthal\baseline_GCaMP_fc_L_canonical_0p5to5',...
    'D:\data\zachRosenthal\week1_GCaMP_fc_L_canonical_0p5to5',...
    'D:\data\zachRosenthal\week4_GCaMP_fc_L_canonical_0p5to5',...
    'D:\data\zachRosenthal\week8_GCaMP_fc_L_canonical_0p5to5'};
saveFile = 'D:\data\zachRosenthal\_meta\mask.mat';
maskData = cell(numel(dataDir),1);
for dirInd = 1:numel(dataDir)
    D = dir(dataDir{dirInd});
    D(1:2) = [];
    maskDataWeek = [];
    for fileInd = 1:numel(D)
        load(fullfile(D(fileInd).folder,D(fileInd).name),'xform_mask');
        maskDataWeek = cat(3,maskDataWeek,xform_mask);
    end
    maskData{dirInd} = maskDataWeek;
end

save(saveFile,'maskData');