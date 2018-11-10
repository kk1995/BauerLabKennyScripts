%% params
iter2Run = 3:1000;
dataFile = 'D:\data\StrokeMTEP\PT_Groups_Tad_single.mat';
privateSSHKey = 'C:\Users\Kenny\.ssh\id_rsa.ppk';
metaFile = 'D:\data\StrokeMTEP\shuffleDiffMeta.mat';
saveData = 'D:\data\StrokeMTEP\shuffle\shuffle_'; % where to save shuffled matrix locally
saveCHPC = 'kk1995@login.chpc.wustl.edu:/scratch/kk1995/data/strokeMTEP'; % where to send the matrix to

%% get raw data

load(metaFile); % orderMat, iterInd
load(dataFile); % MTEP_PT, Veh_PT

data1 = Veh_PT; clear Veh_PT;
data2 = MTEP_PT; clear MTEP_PT;

disp('data loaded');

itep = logical(diag(ones(size(data1,1),1)));
itep1 = repmat(itep,[1 1 size(data1,3)]);
itep2 = repmat(itep,[1 1 size(data2,3)]);
data1(logical(itep1)) = 0;
data2(logical(itep2)) = 0;
clear itep1; clear itep2;

disp('data preprocessed');

%% shuffle, make diff mat, save, and send to chpc

% pool data
dataPool = cat(3,data1,data2);
sampleSize1 = size(data1,3);
sampleSize2 = size(data2,3);
clear data1
clear data2

for iter = iter2Run % for each iteration
    
    % shuffle
    disp(['run: ' num2str(iter)]);
    t0 = tic;
    
    order = orderMat(:,iter==iterInd);
    diffData = mean(dataPool(:,:,order(sampleSize1+1:sampleSize1+sampleSize2)),3)...
        - mean(dataPool(:,:,order(1:sampleSize1)),3);
    
    % save diff connectivity matrix (diffData)
    saveFileName = [saveData num2str(iter) '.mat'];
    save(saveFileName,'diffData');
    
    % send via terminal command
    system(['pscp -i ' privateSSHKey ' ' saveData num2str(iter) '.mat ' saveCHPC]);
    
    % delete the file local
    delete saveFileName
    
    t0 = toc(t0);
    disp(['  ' num2str(t0) ' seconds']);
end

