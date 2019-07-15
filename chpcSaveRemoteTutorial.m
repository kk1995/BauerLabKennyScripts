% send data and save remotely.
% before running the code, make sure the parallel cluster you use is not
% 'local' but 'chpc'.

% how many iterations do you want to save?
iterNum = 10;

% parameterize
memoryPerCore = '4096'; % how much memory is needed per core? (Mbyte)
wallTime = '02:00:00'; % how much computing time allowed per job?

c = parcluster;
jobID = [];
for iter = 1:iterNum
    disp(['  Block #' num2str(iter)]);
    
    % make data for the iteration
    data = rand(20,20,1000);
    
    % file name
    fileName = ['randomData_' num2str(iter) '.mat'];
    
    % number of output arguments
    numOut = 0;
    
    c.AdditionalProperties.MemUsage = num2str(memoryPerCore);
    c.AdditionalProperties.WallTime = wallTime;
    j = c.batch(@sendData, numOut, {data,fileName}...
        ,'CurrentFolder','.','AutoAddClientPath',false);
    jobID = [jobID j.ID];
end

function sendData(data,fileName)
    save(fileName,'data','-v7.3');
end