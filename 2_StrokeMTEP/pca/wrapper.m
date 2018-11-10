iterations = [1:256 513:1024];

blockSize = 64;

for block = 1:ceil(numel(iterations)/blockSize)
    disp(['block # ' num2str(block) ' start.']);
    t0 = tic;
    %% params
    iter = iterations((block - 1)*blockSize + 1:block*blockSize);
    numberOfWorkers = 1;
    numberOfJobs = 2;
    memoryPerCore = '45000';
    wallTime = '04:00:00';
    
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
        j = c.batch(@chpcSaveDiff, 0, {iterJob{job}},'Pool',numberOfWorkers...
            ,'CurrentFolder','.','AutoAddClientPath',false);
        jobArraySaveDiff = [jobArraySaveDiff j];
    end
    
    allSaveJobsFinished = false;
    saveJobsFinished = false(numberOfJobs,1);
    while ~allSaveJobsFinished
        for job = 1:numberOfJobs
            saveJobsFinished(job) = strcmp(jobArraySaveDiff(job).State,'finished');
        end
        allSaveJobsFinished = sum(saveJobsFinished) == numberOfJobs;
        pause(30);
    end
    
    % run the PCA
    dataDir = '/scratch/kk1995/data/strokeMTEP/shuffle';
    dataFile = 'shuffle_';
    numberOfWorkers = 1;
    numberOfJobs = 16;
    memoryPerCore = '8000';
    wallTime = '06:00:00';
    numComponents = 20; % number of principal components
    saveFile = ['D:\data\StrokeMTEP\nullExpIter\nullExpIter' num2str(iter(1)) '-' num2str(iter(end)) '.mat'];
    
    %% make cell array of data file names
    
    iterJob = cell(numberOfJobs,1);
    for job = 1:numberOfJobs
        iterJob{job} = iter(job:numberOfJobs:numel(iter));
    end
    
    dataFileArray = cell(max(iter),1);
    for oneIter = iterations
        dataFileArray{oneIter} = [dataDir '/' dataFile num2str(oneIter) '.mat'];
    end
    c = parcluster;
    jobArray = [];
    for job = 1:numberOfJobs
        
        c.AdditionalProperties.MemUsage = num2str(memoryPerCore);
        c.AdditionalProperties.WallTime = wallTime;
        j = c.batch(@chpcPCA, 5, {dataFileArray(iterJob{job}),iterJob{job},numComponents,true},'Pool',numberOfWorkers...
            ,'CurrentFolder','.','AutoAddClientPath',false);
        jobArray = [jobArray j];
    end
    
    allJobsFinished = false;
    jobsFinished = false(numberOfJobs,1);
    while ~allJobsFinished
        for job = 1:numberOfJobs
            jobsFinished(job) = strcmp(jobArray(job).State,'finished');
        end
        allJobsFinished = sum(jobsFinished) == numberOfJobs;
        pause(60);
    end
    
    
    %% run when jobs are done
    nullCoeff = [];
    nullScore = [];
    nullLatent = [];
    nullExplained = [];
    iterationVal = [];
    
    for job = 1:numberOfJobs
        nullCoeff = cat(3,nullCoeff,jobArray(job).fetchOutputs{1});
        nullScore = cat(3,nullScore,jobArray(job).fetchOutputs{2});
        nullLatent = [nullLatent jobArray(job).fetchOutputs{3}];
        nullExplained = [nullExplained jobArray(job).fetchOutputs{4}];
        iterationVal = [iterationVal jobArray(job).fetchOutputs{5}];
    end
    
    save(saveFile,'nullCoeff','nullScore','nullLatent','nullExplained','iterationVal');
    
    disp(['block # ' num2str(block) ' done.']);
    disp(['Took ' num2str(toc(tic)/60) ' min.']);
    
end