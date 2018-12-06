saveDir = "D:\data\zachRosenthal\preprocessed";
systemInfo = mouse.expSpecific.sysInfo('fcOIS2');
sessionInfo = mouse.expSpecific.session2procInfo('stim');
sessionInfo.framerate = 16.8;
sessionInfo.lowpass = sessionInfo.framerate./2-0.1;
sessionInfo.freqout = sessionInfo.framerate;

% get list of mice
excelFile = 'D:\data\Stroke Study 1 sorted.xlsx';
rows = 1:14;
recDates = [];
mouseNames = [];
for row = rows
    [~, ~, raw]=xlsread(excelFile,1, ['A',num2str(row),':B',num2str(row)]);
    recDates = [recDates string(raw{1})];
    mouseNames = [mouseNames string(raw{2})];
end

roiResponse = [];
darkFrame = 100*ones(128,128,4); % here I am assuming that dark values are 100.

for mouseInd = 1:numel(mouseNames)
    disp(['mouse # ' num2str(mouseInd)]);
    maskFile = strcat("K:\Proc2\",recDates(mouseInd),"\",recDates(mouseInd),"-",...
        mouseNames(mouseInd),"-LandmarksandMask.mat");
    load(maskFile);
    isbrain = mask > 0;
    markers = I;
    for run = 1:3
        tiffFileName = strcat("K:\",recDates(mouseInd),"\",recDates(mouseInd),"-",...
            mouseNames(mouseInd),"-stim",num2str(run),".tif");
        darkFrameNum = 0*sessionInfo.framerate;
        if exist('isbrain')
            % if brain mask and markers are available:
            [raw, time, xform_hb, xform_gcamp, xform_gcampCorr, isbrain, xform_isbrain, markers] ...
                = gcamp.gcampImaging(tiffFileName, systemInfo, sessionInfo, isbrain, markers,'darkFrame',darkFrame);
        else
            [raw, time, xform_hb, xform_gcamp, xform_gcampCorr, isbrain, xform_isbrain, markers] ...
                = gcamp.gcampImaging(tiffFileName, systemInfo, sessionInfo,'darkFrame',darkFrame);
        end
        oxy = squeeze(xform_hb(:,:,1,:)); deoxy = squeeze(xform_hb(:,:,2,:));
        gcamp6 = squeeze(xform_gcamp);
        gcamp6corr = squeeze(xform_gcampCorr);
        xform_mask = mask;
        
        % save
        saveFile = fullfile(saveDir,strcat(recDates(mouseInd),"-",...
            mouseNames(mouseInd),"-stim",num2str(run),".mat"));
        save(saveFile,'oxy','deoxy','gcamp6','gcamp6corr','-v7.3');
    end
end