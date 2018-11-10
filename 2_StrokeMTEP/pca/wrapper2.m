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
blockSize = 32;
numComponents = 20;

disp(['Doing iterations # ' num2str(iterations(1)) '-' num2str(iterations(end))]);

c = parcluster;
jobArray = [];
jobNumel = ceil(numel(iterations)/blockSize);
startT = tic;
% assign job
jobID = [];
for job = 1:jobNumel
    %% params
    try
        iter = iterations((job - 1)*blockSize + 1:job*blockSize);
    catch
        iter = iterations((job - 1)*blockSize + 1:numel(iterations));
    end
    memoryPerCore = '40000';
    wallTime = '24:00:00';
    
    c.AdditionalProperties.MemUsage = num2str(memoryPerCore);
    c.AdditionalProperties.WallTime = wallTime;
    j = c.batch(@saveAndPCA, 0, {iter, numComponents}...
        ,'CurrentFolder','.','AutoAddClientPath',false);
    jobID = [jobID j.ID];
end

% % check on the jobs every now and then
% allJobsComplete = false;
% jobComplete = false(jobNumel,1);
% while ~allJobsComplete
%     pause(300);
%     disp(['    ' num2str(round(toc(startT)/60)) ' min since assigning.']);
%     for job = 1:jobNumel
%         j = c.findJob('ID',jobID(job));
%         if strcmp(j.State,'finished') && ~jobComplete(job)
%             jobComplete(job) = true;
%             nullCoeff = j.fetchOutputs{1};
%             nullScore = j.fetchOutputs{2};
%             nullLatent = j.fetchOutputs{3};
%             nullExplained = j.fetchOutputs{4};
%             iterationVal = j.fetchOutputs{5};
%             saveFile = ['D:\data\StrokeMTEP\nullExpIter\nullExpIter' num2str(min(iterationVal)) '-' num2str(max(iterationVal)) '.mat'];
%             save(saveFile,'nullCoeff','nullScore','nullLatent','nullExplained','iterationVal');
%             disp(['  Job # ' num2str(job) ' done.']);
%             disp(['  Took ' num2str(toc(startT)/60) ' min.']);
%             j.delete;
%         end
%     end
% end