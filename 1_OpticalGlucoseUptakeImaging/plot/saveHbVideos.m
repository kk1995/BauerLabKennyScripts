recDate = '180713';
mouse = 'NewProbeM3W5';
modification = 'GSR';
dataDir = ['D:\data\' recDate];
vidDir = 'C:\Repositories\GitHub\BauerLab\figures';

%% load

load(fullfile(dataDir,[recDate '-' mouse '-Pre-' modification '.mat']));

preHb = datahbCell;

load(fullfile(dataDir,[recDate '-' mouse '-Post-' modification '.mat']));

postHb = datahbCell;

%% get first 5 seconds of data

preHbFirst5Seconds = [];
for i = 1:5
    preHbFirst5Seconds = cat(4,preHbFirst5Seconds,preHb{i});
end
preHbFirst5SecondsAvg = mean(preHbFirst5Seconds,4);

postHbFirst5Seconds = [];
for i = 1:5
    postHbFirst5Seconds = cat(4,postHbFirst5Seconds,postHb{i});
end
postHbFirst5SecondsAvg = mean(postHbFirst5Seconds,4);

%% remove first 5 seconds avg from rest of data

preHbAligned = cell(60,1);
postHbAligned = cell(60,1);
for i = 1:60
    preHbAligned{i} = preHb{i} - repmat(preHbFirst5SecondsAvg,[1 1 1 size(preHb{i},4)]);
    postHbAligned{i} = postHb{i} - repmat(postHbFirst5SecondsAvg,[1 1 1 size(postHb{i},4)]);
end

%% get the data to feed into video maker

preHbOAvg = [];
preHbRAvg = [];
preHbTAvg = [];
for time = 1:60
    preHbOAvg = cat(3,preHbOAvg,mean(squeeze(preHbAligned{time}(:,:,1,:)),3));
    preHbRAvg = cat(3,preHbRAvg,mean(squeeze(preHbAligned{time}(:,:,2,:)),3));
    preHbTAvg = cat(3,preHbTAvg,mean(squeeze(sum(preHbAligned{time},3)),3));
end

imagesc2Vid(preHbOAvg,4,[-0.005 0.005],fullfile(vidDir,[recDate '-' mouse '-HbO' modification '_pre.avi']));
imagesc2Vid(preHbRAvg,4,[-0.005 0.005],fullfile(vidDir,[recDate '-' mouse '-HbR' modification '_pre.avi']));
imagesc2Vid(preHbTAvg,4,[-0.005 0.005],fullfile(vidDir,[recDate '-' mouse '-HbT' modification '_pre.avi']));
imagesc2Vid(preHbOAvg,4,[-0.005 0.005],fullfile(vidDir,[recDate '-' mouse '-HbO' modification '_pre_Compressed.avi']),'Compressed');
imagesc2Vid(preHbRAvg,4,[-0.005 0.005],fullfile(vidDir,[recDate '-' mouse '-HbR' modification '_pre_Compressed.avi']),'Compressed');
imagesc2Vid(preHbTAvg,4,[-0.005 0.005],fullfile(vidDir,[recDate '-' mouse '-HbT' modification '_pre_Compressed.avi']),'Compressed');

postHbOAvg = [];
postHbRAvg = [];
postHbTAvg = [];
for time = 1:60
    postHbOAvg = cat(3,postHbOAvg,mean(squeeze(postHbAligned{time}(:,:,1,:)),3));
    postHbRAvg = cat(3,postHbRAvg,mean(squeeze(postHbAligned{time}(:,:,2,:)),3));
    postHbTAvg = cat(3,postHbTAvg,mean(squeeze(sum(postHbAligned{time},3)),3));
end

imagesc2Vid(postHbOAvg,4,[-0.005 0.005],fullfile(vidDir,[recDate '-' mouse '-HbO' modification '_post.avi']));
imagesc2Vid(postHbRAvg,4,[-0.005 0.005],fullfile(vidDir,[recDate '-' mouse '-HbR' modification '_post.avi']));
imagesc2Vid(postHbTAvg,4,[-0.005 0.005],fullfile(vidDir,[recDate '-' mouse '-HbT' modification '_post.avi']));
imagesc2Vid(postHbOAvg,4,[-0.005 0.005],fullfile(vidDir,[recDate '-' mouse '-HbO' modification '_post_Compressed.avi']),'Compressed');
imagesc2Vid(postHbRAvg,4,[-0.005 0.005],fullfile(vidDir,[recDate '-' mouse '-HbR' modification '_post_Compressed.avi']),'Compressed');
imagesc2Vid(postHbTAvg,4,[-0.005 0.005],fullfile(vidDir,[recDate '-' mouse '-HbT' modification '_post_Compressed.avi']),'Compressed');