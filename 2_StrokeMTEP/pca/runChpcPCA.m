%% params
% find which iterations I already have
nullDataDir = 'D:\data\StrokeMTEP\nullExpIter';
D = dir(nullDataDir); D(1:2) = [];

load('D:\data\StrokeMTEP\MTEP_PTminusVeh_PCA.mat','symisbrainall');
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

iterations = sort(iterations);
iterations = iterations';
dataDir = '/scratch/kk1995/data/strokeMTEP/shuffle';
dataFile = 'shuffle_';
numberOfJobs = 32;
memoryPerCore = '8000';
wallTime = '16:00:00';
numComponents = 20; % number of principal components
% saveFile = ['D:\data\StrokeMTEP\nullExpIter\nullExpIter' num2str(iterations(1)) '-' num2str(iterations(end)) '.mat'];

%% make cell array of data file names

iterJob = cell(numberOfJobs,1);
for job = 1:numberOfJobs
    iterJob{job} = iterations(job:numberOfJobs:numel(iterations));
end

dataFileArray = cell(max(iterations),1);
for iter = iterations
    dataFileArray{iter} = [dataDir '/' dataFile num2str(iter) '.mat'];
end
c = parcluster;
jobArray = [];

startT = tic;

for job = 1:numberOfJobs
    disp(num2str(job));
    c.AdditionalProperties.MemUsage = num2str(memoryPerCore);
    c.AdditionalProperties.WallTime = wallTime;
    j = c.batch(@chpcPCA, 5, {dataFileArray(iterJob{job}),iterJob{job},numComponents,true}...
        ,'CurrentFolder','.','AutoAddClientPath',false);
    jobArray = [jobArray j];
end


%% check on the jobs every now and then


doneJobs = [];

nullCoeff = [];
nullScore = [];
nullLatent = [];
nullExplained = [];
iterationVal = [];
for job = 1:numberOfJobs
    if strcmp(jobArray(job).State,'finished') && (sum(job == doneJobs)==0)
        nullCoeff = cat(3,nullCoeff,jobArray(job).fetchOutputs{1});
        nullScore = cat(3,nullScore,jobArray(job).fetchOutputs{2});
        nullLatent = [nullLatent jobArray(job).fetchOutputs{3}];
        nullExplained = [nullExplained jobArray(job).fetchOutputs{4}];
        iterationVal = [iterationVal jobArray(job).fetchOutputs{5}];
        disp(['  Job # ' num2str(job) ' done.']);
        doneJobs = [doneJobs job];
    end
end
saveFile = ['D:\data\StrokeMTEP\nullExpIter\nullExpIter'...
    num2str(iterationVal(1)) '-' num2str(iterationVal(end)) 'mixed.mat'];
save(saveFile,'nullCoeff','nullScore','nullLatent','nullExplained','iterationVal');