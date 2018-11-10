%% parameters

% dataFile = 'D:\data\StrokeMTEP\PT_Groups_Tad_single.mat';
iterNum = 4;
numberOfWorkers = 2;
memoryPerCore = '32000';

% dataFile =  '/scratch/kk1995/data/strokeMTEP/Toy3k10mice_single.mat';
% dataFile = '/scratch/kk1995/data/strokeMTEP/Toy_single.mat';



% dataFile = 'Toy3k_single.mat';

% dataFile = {'D:\data\StrokeMTEP\PT_Groups_Tad_1.mat',...
%     'D:\data\StrokeMTEP\PT_Groups_Tad_2.mat',...
%     'D:\data\StrokeMTEP\PT_Groups_Tad_3.mat'};


% dataFile =  '/scratch/kk1995/data/strokeMTEP/Toy_comp.mat';
dataFile = '/scratch/kk1995/data/strokeMTEP/PT_Groups_Tad_single_5mice.mat';

% dataFile = {'D:\data\StrokeMTEP\PT_Groups_Tad_1.mat',...
%     'D:\data\StrokeMTEP\PT_Groups_Tad_2.mat'};
% dataFile = {'/scratch/kk1995/data/strokeMTEP/PT_Groups_Tad_1.mat',...
%     '/scratch/kk1995/data/strokeMTEP/PT_Groups_Tad_2.mat'};

% dataFile = {'/scratch/kk1995/data/strokeMTEP/PT_Groups_Tad_1.mat',...
%     '/scratch/kk1995/data/strokeMTEP/PT_Groups_Tad_2.mat',...
%     '/scratch/kk1995/data/strokeMTEP/PT_Groups_Tad_3.mat'};

% dataFile = {'/scratch/kk1995/data/strokeMTEP/PT_Groups_Tad_1.mat',...
%     '/scratch/kk1995/data/strokeMTEP/PT_Groups_Tad_2.mat',...
%     '/scratch/kk1995/data/strokeMTEP/PT_Groups_Tad_3.mat',...
%     '/scratch/kk1995/data/strokeMTEP/PT_Groups_Tad_4.mat',...
%     '/scratch/kk1995/data/strokeMTEP/PT_Groups_Tad_5.mat',...
%     '/scratch/kk1995/data/strokeMTEP/PT_Groups_Tad_6.mat',...
%     '/scratch/kk1995/data/strokeMTEP/PT_Groups_Tad_7.mat',...
%     '/scratch/kk1995/data/strokeMTEP/PT_Groups_Tad_8.mat',...
%     '/scratch/kk1995/data/strokeMTEP/PT_Groups_Tad_9.mat',...
%     '/scratch/kk1995/data/strokeMTEP/PT_Groups_Tad_10.mat'};


% data1 = [];
% data2 = [];
% 
% if iscell(dataFile)
%     for i = 1:numel(dataFile)
%         
%         load(dataFile{i});
%         
%         data1 = cat(3,data1,single(Veh_PT_mouse));
%         data2 = cat(3,data2,single(MTEP_PT_mouse));
%         
%     end
% else
%     load(dataFile);
%     data1 = single(Veh_PT);
%     data2 = single(MTEP_PT);
% end
% 
% disp('data loaded');
% 
% data1 = 2*rand(1000,1000,3)-1;
% data2 = 2*rand(1000,1000,3)-1;
% 
% data1 = single(data1);
% data2 = single(data2);

% itep = logical(diag(ones(size(data1,1),1)));
% itep1 = repmat(itep,[1 1 size(data1,3)]);
% itep2 = repmat(itep,[1 1 size(data2,3)]);
% data1(logical(itep1)) = 0;
% data2(logical(itep2)) = 0;
% 
% disp('data preprocessed');


%% load (comment out if already loaded)

% warning off;
% t0 = tic;
% [nullExplained,orderMat] = iteratePCA(data1,data2,iterNum);
% disp(['total: ' num2str(toc(t0)) ' seconds']);
% warning on;

%%
c = parcluster;
c.AdditionalProperties.MemUsage = num2str(memoryPerCore);
c.AdditionalProperties.WallTime = '16:00:00';
j = c.batch(@iteratePCALoadFile, 2, {dataFile,iterNum},'Pool',numberOfWorkers...
    ,'CurrentFolder','.','AutoAddClientPath',false);

% t0 = tic;
% while strcmp(j.State,'queued')
%     disp([num2str(toc(t0)) ' seconds: In queue']);
%     pause(10);
% end
% 
% while strcmp(j.State,'running')
%     disp([num2str(toc(t0)) ' seconds: Running']);
%     pause(10);
% end
% 
% disp([num2str(toc(t0)) ' seconds: Complete']);
% 
% x = j.fetchOutputs;
% nullExplained = x{1};
% orderMat = x{2};
%% do PCA on original hypothesis

% diffData = mean(MTEP_PT,3) - mean(Veh_PT,3);
% 
% [~,~,~,~,lat] = pca(diffData);
% 
% %% plot
% 
% lastDim = 20;
% 
% figure('Position',[100 100 800 600]);
% plot(lat(1:lastDim));
% hold on;
% errorbar(1:lastDim-1,mean(nullLatent(1:lastDim,:),2),2.5*std(nullLatent(1:lastDim,:),0,2),'.','MarkerSize',12);
% legend('% Variance explained','Null hypothesis');
% hold off;