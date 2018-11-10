function chpcSaveDiff(iterations)

dataFile = '/scratch/kk1995/data/strokeMTEP/PT_Groups_Tad_single.mat';
metaFile = '/scratch/kk1995/data/strokeMTEP/shuffleDiffMeta.mat';
saveDir = '/scratch/kk1995/data/strokeMTEP/shuffle/';
saveData = 'shuffle_'; % where to save shuffled matrix locally

% check the iterations that need to be made
iterDone = [];
D = dir(saveDir); D(1:2) = [];
for i = 1:numel(D)
    fileName = D(i).name;
    if contains(fileName, saveData)
        underScoreLoc = strfind(fileName,'_'); underScoreLoc = underScoreLoc(end);
        iterStr = fileName(underScoreLoc+1:end-4);
        iterDone = [iterDone str2double(iterStr)];
    end
end

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

for iter = iterations % for each iteration
    
    if isempty(find(iter == iterDone, 1)) % if the iteration is not done
        
        % shuffle
        disp(['run: ' num2str(iter)]);
        t0 = tic;
        
        order = orderMat(:,iter==iterInd);
        diffData = mean(dataPool(:,:,order(sampleSize1+1:sampleSize1+sampleSize2)),3)...
            - mean(dataPool(:,:,order(1:sampleSize1)),3);
        
        % save diff connectivity matrix (diffData)
        saveFileName = [saveDir saveData num2str(iter) '.mat'];
        save(saveFileName,'diffData');
        
        t0 = toc(t0);
        disp(['  ' num2str(t0) ' seconds']);
    end
end