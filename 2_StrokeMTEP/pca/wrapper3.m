% here I am doing the shuffling and diff mat creation locally, but sends it
% to cluster.

% find which iterations I already have
nullDataDir = 'D:\data\StrokeMTEP\nullExpIter';
D = dir(nullDataDir); D(1:2) = [];

iterations = [];

for file = 1:numel(D)
    load(fullfile(nullDataDir,D(file).name),'iterationVal');
    iterations = [iterations iterationVal];
end

% remove repeats
[~,IA,~] = unique(iterations);
iterationsBool = false(2048,1);
iterationsBool(iterations(IA)) = true;
iterations = find(~iterationsBool);

iterations = iterations(1:100); % trying with a smaller batch

% parameterize
blockSize = 2;
numComponents = 20;
memoryPerCore = '10000';
wallTime = '02:00:00';

dataFile = 'D:\data\StrokeMTEP\PT_Groups_Tad_single.mat';
metaFile = 'D:\data\StrokeMTEP\shuffleDiffMeta.mat';

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

% pool data
dataPool = cat(3,data1,data2);
sampleSize1 = size(data1,3);
sampleSize2 = size(data2,3);
clear data1
clear data2

disp('data pooled');

c = parcluster;
jobID = [];
for block = 1:ceil(numel(iterations)/blockSize)
    disp(['  Block #' num2str(block)]);
    blockIterations = iterations((block-1)*blockSize + 1:block*blockSize);
    % make difference matrix
    
    diffData = nan(size(dataPool,1),size(dataPool,2),numel(blockIterations));
    for iter = 1:numel(blockIterations) % for each iteration
        % shuffle
        order = orderMat(:,blockIterations(iter));
        diffData(:,:,iter) = mean(dataPool(:,:,order(sampleSize1+1:sampleSize1+sampleSize2)),3)...
            - mean(dataPool(:,:,order(1:sampleSize1)),3);
    end
    
    disp('  diff data made');
    
    
    c.AdditionalProperties.MemUsage = num2str(memoryPerCore);
    c.AdditionalProperties.WallTime = wallTime;
    j = c.batch(@chpcPCASendData, 5, {diffData,blockIterations,numComponents}...
        ,'CurrentFolder','.','AutoAddClientPath',false);
    jobID = [jobID j.ID];
end


%% save
nullCoeff = [];
nullScore = [];
nullLatent = [];
nullExplained = [];
iterationVal = [];
for job = [5:9 11:15]
    j = c.findJob('ID',jobID(job));
    nullCoeff = cat(3,nullCoeff,j.fetchOutputs{1});
    nullScore = cat(3,nullScore,j.fetchOutputs{2});
    nullLatent = [nullLatent j.fetchOutputs{3}];
    nullExplained = [nullExplained j.fetchOutputs{4}];
    iterationVal = [iterationVal j.fetchOutputs{5}];
    
    j.delete;
end
saveFile = ['D:\data\StrokeMTEP\nullExpIter\nullExpIter' num2str(iterationVal(1)) '-' num2str(iterationVal(end)) '.mat'];
save(saveFile,'nullCoeff','nullScore','nullLatent','nullExplained','iterationVal');