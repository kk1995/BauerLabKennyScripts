%% params
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

iterations = sort(iterations)';
numberOfJobs = 8;
memoryPerCore = '45000';
wallTime = '08:00:00';

%% make cell array of data file names

iterJob = cell(numberOfJobs,1);
for job = 1:numberOfJobs
    iterJob{job} = iterations(job:numberOfJobs:numel(iterations));
end


jobArraySaveDiff = [];
for job = 1:numberOfJobs
    c = parcluster;
    c.AdditionalProperties.MemUsage = num2str(memoryPerCore);
    c.AdditionalProperties.WallTime = wallTime;
    j = c.batch(@chpcSaveDiff, 0, {iterJob{job}}...
        ,'CurrentFolder','.','AutoAddClientPath',false);
    jobArraySaveDiff = [jobArraySaveDiff j];
end