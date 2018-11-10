dataDir = 'D:\data\StrokeMTEP\';
dataFile = 'PT_Groups_Tad';

% load(fullfile(dataDir,[dataFile '.mat']));

for mouse = 1:size(Veh_PT,3)
    disp(num2str(mouse));
    saveName = [dataFile '_' num2str(mouse) '.mat'];
    Veh_PT_mouse = Veh_PT(:,:,mouse);
    MTEP_PT_mouse = MTEP_PT(:,:,mouse);
    
%     load(fullfile(dataDir,saveName));
    
%     save(fullfile(dataDir,saveName),'Veh_PT_mouse','MTEP_PT_mouse');
    
    system(['pscp ' dataDir saveName ...
        ' kk1995@login.chpc.wustl.edu:/scratch/kk1995/data/strokeMTEP']);
end