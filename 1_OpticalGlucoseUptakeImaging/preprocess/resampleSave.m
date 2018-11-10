% saves raw data at lower frequency for me to work with
% usually runs after saveHbAndFluor.m

%% params
dataDir = 'D:\data\';

% dataDate = {'180713','180713','180716','180716','180716','180718'};
% mouse = {'NewProbeM3W5','NewProbeM4W5','NewProbeM1W6','NewProbeM2W6','NewProbeM3W6','NewProbeM1W5'};

% dataDate = {'180713'}; mouse = {'NewProbeM3W5'};

% dataDate = {'180813','180813','180813','180813'};
% mouse = {'ProbeW3M1','ProbeW3M2','ProbeW3M3','ProbeW4M1'};

dataDate = {'181108'};
mouse = {'ProbeW5M1'};

saveDir = 'D:\data';
probe = {'Pre','Post'};
numLED = 4;
% fIn = 16.8;
fIn = 5;
fOut = 1;
disp('resample save');
for mouseInd = 1:numel(mouse)
    for probeInd = 1:2
        %% get list of files to load and resample
        disp(['mouse # ' num2str(mouseInd)]);
        D = dir(fullfile(dataDir,dataDate{mouseInd})); D(1:2) = [];
        dataFileList = {};
        for file = 1:numel(D)
            % condition
            if isempty(strfind(D(file).name,'Resampled'))
                if strfind(D(file).name,[dataDate{mouseInd} '-' mouse{mouseInd} '-' probe{probeInd} '-GSR'])
                    dataFileList = [dataFileList; {fullfile(D(file).folder,D(file).name)}];
                end
            end
        end
        
        %% get list of save file names
        if strcmp(probe{probeInd},'Pre')
            saveName = [dataFileList{1}(1:end-4) '-Resampled.mat'];
        else
            saveName = [dataFileList{1}(1:end-5) 'Resampled.mat'];
        end
        
        %% for each mouse get data and analyze
        t_fluor = [];
        t_hb = [];
        xform_fluor = [];
        xform_hb = [];
        
        for file = 1:numel(dataFileList)
            disp(['file #' num2str(file)]);
            disp('  data loading');
            dataName = dataFileList{file};
            fileData = load(dataName);
            
            disp('  resampling');
            t_fluor = [t_fluor resampledata(fileData.t_fluor,fIn,fOut,10^-5)];
            t_hb = [t_hb resampledata(fileData.t_hb,fIn,fOut,10^-5)];
            xform_fluor = cat(4,xform_fluor,resampledata(fileData.xform_fluor,fIn,fOut,10^-5));
            xform_hb = cat(4,xform_hb,resampledata(fileData.xform_hb,fIn,fOut,10^-5));
        end
        
        disp('  saving');
        save(saveName,'t_fluor','t_hb','xform_fluor','xform_hb','-v7.3');
    end
end
disp('done!');