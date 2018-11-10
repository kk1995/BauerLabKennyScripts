rootDir = 'D:\data\zachRosenthal\_stim';

week = 1;
if week == 1
    weekChar = 'baseline';
end

dataDir = fullfile(rootDir,[weekChar '_blockAvg']);
fileList = dir(dataDir); fileList(1:2) = [];

fileData = load(fullfile(dataDir,fileList(1).name));

oxyBlock = nan([size(fileData.oxyBlock) numel(fileList)]);
deoxyBlock = nan([size(fileData.deoxyBlock) numel(fileList)]);
gcamp6corrBlock = nan([size(fileData.gcamp6corrBlock) numel(fileList)]);

for fileInd = 1:numel(fileList)
    disp(['File #' num2str(fileInd)]);
    fileData = load(fullfile(dataDir,fileList(fileInd).name));
    % oxyBlock, deoxyBlock, gcamp6corrBlock
    
    oxyBlock(:,:,:,:,fileInd) = fileData.oxyBlock;
    deoxyBlock(:,:,:,:,fileInd) = fileData.deoxyBlock;
    gcamp6corrBlock(:,:,:,:,fileInd) = fileData.gcamp6corrBlock;
end

oxyBlock = nanmean(oxyBlock,5);
deoxyBlock = nanmean(deoxyBlock,5);
gcamp6corrBlock = nanmean(gcamp6corrBlock,5);

oxyBlock = permute(oxyBlock,[1 2 4 3]);
deoxyBlock = permute(deoxyBlock,[1 2 4 3]);
gcamp6corrBlock = permute(gcamp6corrBlock,[1 2 4 3]);

% spatial x spatial x freq x time

%% gsr
load('D:\data\zachRosenthal\week1mask.mat');
mask = mask >= 0.5;

% oxyBlock = mouseAnalysis.preprocess.gsr(oxyBlock,mask);
% deoxyBlock = mouseAnalysis.preprocess.gsr(deoxyBlock,mask);
% gcamp6corrBlock = mouseAnalysis.preprocess.gsr(gcamp6corrBlock,mask);

%% get roi avg

roiDir = 'D:\data\zachRosenthal\_stim\ROI R 75.mat';
load(roiDir)
roi = roiR75;

oxyBlockVect = reshape(oxyBlock,size(oxyBlock,1)*size(oxyBlock,2),size(oxyBlock,3),size(oxyBlock,4));
deoxyBlockVect = reshape(deoxyBlock,size(deoxyBlock,1)*size(deoxyBlock,2),size(deoxyBlock,3),size(deoxyBlock,4));
gcamp6corrBlockVect = reshape(gcamp6corrBlock,size(gcamp6corrBlock,1)*size(gcamp6corrBlock,2),size(gcamp6corrBlock,3),size(gcamp6corrBlock,4));

t = linspace(0,20,size(oxyBlockVect,3)+1); t(1) = [];

oxyAvg = squeeze(nanmean(oxyBlockVect(roi,1,:),1));
deoxyAvg = squeeze(nanmean(deoxyBlockVect(roi,1,:),1));
gcamp6corrAvg = squeeze(nanmean(gcamp6corrBlockVect(roi,1,:),1));

%% plot time course

figure('Position',[100 100 550 400]); p1 = plot(t,oxyAvg,'r'); hold on;
p2 = plot(t,deoxyAvg,'b');
p3 = plot(t,oxyAvg+deoxyAvg,'m');
p4 = plot(t,gcamp6corrAvg,'k'); hold off;
set(findall(gca, 'Type', 'Line'),'LineWidth',2);

% plotting stimulation
stimTime = 5:1/3:10; stimTime(end) = [];
yRange = ylim;
hold on;
for i = 1:numel(stimTime)
    plot([stimTime(i) stimTime(i)],yRange,'g');
end

legend([p1 p2 p3 p4],{'HbO','HbR','HbT','GCaMP'});

%% plot spatial avg

t = linspace(0,20,size(oxyBlock,4)+1); t(1) = [];
tInd = (t >= 5 & t <= 10);

oxyStimAvg = squeeze(nanmean(oxyBlock(:,:,:,tInd),4));
deoxyStimAvg = squeeze(nanmean(deoxyBlock(:,:,:,tInd),4));
gcamp6corrStimAvg = squeeze(nanmean(gcamp6corrBlock(:,:,:,tInd),4));

figure('Position',[100 100 500 450]);
imagesc(gcamp6corrStimAvg(:,:,1),'AlphaData',mask,[-1E-3 3E-3]); colormap('jet'); colorbar;
set(gca,'color','black')
axis(gca,'square');
set(gca,'xtick',[])
set(gca,'xticklabel',[])
set(gca,'ytick',[])
set(gca,'yticklabel',[])

% plot contour

hold on;
load('D:\data\zachRosenthal\_stim\ROI R 75.mat');
P = mask2poly(roiR75);
for n = 1:numel(P)
color = 'k';
p1 = plot(P(n).X,P(n).Y,color,'LineWidth',2);
end

load('D:\data\zachRosenthal\_stim\ROI R 75 vs baseline wk1 after stroke.mat');
P = mask2poly(roiR75ofbaselineatwk1);
for n = 1:numel(P)
color = 'b';
p2 = plot(P(n).X,P(n).Y,color,'LineWidth',2);
end

load('D:\data\zachRosenthal\_stim\ROI R 75 wk4 after stroke.mat');
P = mask2poly(roiR75wk4);
for n = 1:numel(P)
color = 'm';
p3 = plot(P(n).X,P(n).Y,color,'LineWidth',2);
end

load('D:\data\zachRosenthal\_stim\ROI R 75 wk8.mat');
P = mask2poly(roiR75wk8);
for n = 1:numel(P)
color = 'g';
p4 = plot(P(n).X,P(n).Y,color,'LineWidth',2);
end
hold off;

lgnd = legend([p1 p2 p3 p4],{'baseline','week 1','week 4','week 8'});
set(lgnd,'color','white');