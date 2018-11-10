date = '180713';
mouse = 'NewProbeM3W5';
dataDir = ['D:\data\' date];
dataFile = [date '-' mouse '-fluorHbRemoved.mat'];
vidDir = 'C:\Repositories\GitHub\BauerLab\figures';
timeBounds = [0.5:59.5;1.5:60.5];
%% load

load(fullfile(dataDir,dataFile));

for condition = 1:2
    
    if condition == 1
        data = xform_postFluor;
        vidFile = [recDate '-' mouse '-Fluor_post.avi'];
        vidCompressedFile = [recDate '-' mouse '-Fluor_post_Compressed.avi'];
    else
        data = xform_postFluor_HbRemoved;
        vidFile = [recDate '-' mouse '-FluorHbRemoved_post.avi'];
        vidCompressedFile = [recDate '-' mouse '-FluorHbRemoved_post_Compressed.avi'];
    end
    
    
    
    %% categorize to bins
    
    postCell = catByTime(data,t_Fluor,timeBounds);
    
    %% get first 5 seconds of data
    
    postFirst5Seconds = [];
    for i = 1:5
        postFirst5Seconds = cat(4,postFirst5Seconds,postCell{i});
    end
    postFirst5SecondsAvg = mean(postFirst5Seconds,4);
    
    %% remove first 5 seconds avg from rest of data
    
    postAligned = cell(60,1);
    for i = 1:60
        postAligned{i} = postCell{i} - repmat(postFirst5SecondsAvg,[1 1 1 size(postCell{i},4)]);
    end
    
    %% get the data to feed into video maker
    
    postAvg = [];
    for time = 1:60
        postAvg = cat(3,postAvg,mean(squeeze(postAligned{time}(:,:,1,:)),3));
    end
    
    imagesc2Vid(postAvg,4,[-20 20],fullfile(vidDir,vidFile));
    imagesc2Vid(postAvg,4,[-20 20],fullfile(vidDir,vidCompressedFile),'Compressed');
    
end