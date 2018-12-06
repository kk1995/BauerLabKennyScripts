radius = 3;
threshold=0.01;
saveFileName = 'NodalConnectivityZDetailedMotor';
% saveFileName = 'NodalConnectivityDetailedMotor';

%% get node locations

% get seed locations
load('D:\data\StrokeMTEP\AtlasandIsbrain.mat');
seednamesOld = seednames;
seednamesOld{4} = 'M2'; % M2 and M1 flipped in loaded data
seednamesOld{5} = 'M1';

seedCenterOld = nan(max(AtlasSeeds(:)),2);
for seed = 1:max(AtlasSeeds(:))
    ind = find(AtlasSeeds == seed);
    [row, col] = mouse.plot.ind2D(ind,size(AtlasSeeds));
    seedCenterOld(seed,1) = mean(col);
    seedCenterOld(seed,2) = mean(row);
end
seedCenterOld = round(seedCenterOld);

% add the other seeds
x = -1*[1.3,1,1.8,1.8,1.25,0.6];
x2 = [1.3,1,1.8,1.8,1.25,0.6];
y = [0.25,-0.75,1.5,2.4,2,-0.15];
[pixX,pixY] = mouse.expSpecific.mm2pix(x,y);
[pixX2,pixY2] = mouse.expSpecific.mm2pix(x2,y);

seedCenter = [seedCenterOld(1:3,:); pixX' pixY'; seedCenterOld(6:20,:);...
    seedCenterOld(21:23,:); pixX2' pixY2'; seedCenterOld(26:40,:)];
seednames = [seednamesOld(1:3) {'M1 CFA'} {'M1 HL'} {'M1 Head'} {'ALM'} ...
    {'M2 RFA'} {'M2p'} seednamesOld(6:20)];
seednames = repmat(seednames,1,2); % for both left and right

nodeIndOriginalSpace = cell(size(seedCenter,1),1);
% get pixels surrounding seed
for seed = 1:size(seedCenter,1)
%     nodeIndOriginalSpace{seed} = find(AtlasSeeds == seed);
    seed2DInd = mouse.plot.circleCoor(seedCenter(seed,:),radius);
    nodeIndOriginalSpace{seed} = seed2DInd(2,:) + (seed2DInd(1,:)-1)*size(AtlasSeeds,1);
end

% convert to brain space
load('D:\data\StrokeMTEP\MTEP_PTminusVeh_PCA.mat','symisbrainall');
isbrain = logical(symisbrainall);

[SeedsUsed]=CalcRasterSeedsUsed(symisbrainall);
idx=find(symisbrainall==1);
length=size(SeedsUsed,1);
map=[(1:2:length-1) (2:2:length)];
NewSeedsUsed(:,1)=SeedsUsed(map, 1);
NewSeedsUsed(:,2)=SeedsUsed(map, 2);

for n=1:size(NewSeedsUsed,1)
    idx_inv(n)=sub2ind([128,128], NewSeedsUsed(n,2), NewSeedsUsed(n,1)); % get the indices of the Seed coordinates used to organize the Pix-Pix matrix
    idx_inv=idx_inv';
end

nodeInd = cell(size(seedCenter,1),1);
for seed = 1:size(seedCenter,1)
    for i = 1:numel(nodeIndOriginalSpace{seed})
        nodeInd{seed} = [nodeInd{seed} find(nodeIndOriginalSpace{seed}(i) == idx_inv)];
    end
%     nodeInd{seed} = nodeInd{seed}(~isnan(nodeInd{seed}));
end

%% get connectivity matrix and get nodal connectivity
disp('load and get connectivity');

disp('loading PT_Groups');
load('D:\data\StrokeMTEP\PT_Groups_Tad_single.mat');

% % preprocess to R
% MTEP_PT = tanh(MTEP_PT);
% Veh_PT = tanh(Veh_PT);


MTEP_PT_Nodal_R = nan(numel(nodeInd),numel(nodeInd),size(MTEP_PT,3));
Veh_PT_Nodal_R = nan(numel(nodeInd),numel(nodeInd),size(Veh_PT,3));

disp('  nodal connectivity calculation MTEP_PT');
t0 = tic;
for mouseInd = 1:size(MTEP_PT,3)
    disp(['    mouse # ' num2str(mouseInd)]);
    t1 = tic;
    MTEP_PT_Nodal_R(:,:,mouseInd) = mouse.graph.nodalConnectivity(nodeInd,MTEP_PT(:,:,mouseInd));
    disp(['    took ' num2str(toc(t1)) ' seconds.']);
end
disp(['  took ' num2str(toc(t0)) ' seconds.']);

disp('  nodal connectivity calculation Veh_PT');
t0 = tic;
for mouseInd = 1:size(Veh_PT,3)
    disp(['    mouse # ' num2str(mouseInd)]);
    Veh_PT_Nodal_R(:,:,mouseInd) = mouse.graph.nodalConnectivity(nodeInd,Veh_PT(:,:,mouseInd));
end

% diagonal is zero and things below threshold are zero.
MTEP_PT_Nodal_R_Graph = MTEP_PT_Nodal_R;
temp=eye(size(MTEP_PT_Nodal_R_Graph,1));
temp = repmat(temp,1,1,size(MTEP_PT_Nodal_R_Graph,3));
idx=find(temp==1);
MTEP_PT_Nodal_R_Graph(idx)=0;
MTEP_PT_Nodal_R_Graph(MTEP_PT_Nodal_R_Graph<threshold)=0; % threshold

Veh_PT_Nodal_R_Graph = Veh_PT_Nodal_R;
temp=eye(size(Veh_PT_Nodal_R_Graph,1));
temp = repmat(temp,1,1,size(Veh_PT_Nodal_R_Graph,3));
idx=find(temp==1);
Veh_PT_Nodal_R_Graph(idx)=0;
Veh_PT_Nodal_R_Graph(Veh_PT_Nodal_R_Graph<threshold)=0; % threshold

disp(['  took ' num2str(toc(t0)) ' seconds.']);

clear MTEP_PT Veh_PT

disp('loading SHAM_Groups');

load('D:\data\StrokeMTEP\SHAM_Groups_Tad_single.mat');

% % preprocess to R
% MTEP_Sham = tanh(MTEP_Sham);
% Veh_Sham = tanh(Veh_Sham);
% 
% if useAbs
% MTEP_Sham = abs(MTEP_Sham);
% Veh_Sham = abs(Veh_Sham);
% end

MTEP_Sham_Nodal_R = nan(numel(nodeInd),numel(nodeInd),size(MTEP_Sham,3));
Veh_Sham_Nodal_R = nan(numel(nodeInd),numel(nodeInd),size(Veh_Sham,3));

disp('  nodal connectivity calculation MTEP_Sham');
t0 = tic;
for mouseInd = 1:size(MTEP_Sham,3)
    disp(['    mouse # ' num2str(mouseInd)]);
    MTEP_Sham_Nodal_R(:,:,mouseInd) = mouse.graph.nodalConnectivity(nodeInd,MTEP_Sham(:,:,mouseInd));
end
disp(['  took ' num2str(toc(t0)) ' seconds.']);

disp('  nodal connectivity calculation Veh_Sham');
t0 = tic;
for mouseInd = 1:size(Veh_Sham,3)
    disp(['    mouse # ' num2str(mouseInd)]);
    Veh_Sham_Nodal_R(:,:,mouseInd) = mouse.graph.nodalConnectivity(nodeInd,Veh_Sham(:,:,mouseInd));
end

MTEP_Sham_Nodal_R_Graph = MTEP_Sham_Nodal_R;
temp=eye(size(MTEP_Sham_Nodal_R_Graph,1));
temp = repmat(temp,1,1,size(MTEP_Sham_Nodal_R_Graph,3));
idx=find(temp==1);
MTEP_Sham_Nodal_R_Graph(idx)=0;
MTEP_Sham_Nodal_R_Graph(MTEP_Sham_Nodal_R_Graph<threshold)=0; % threshold

Veh_Sham_Nodal_R_Graph = Veh_Sham_Nodal_R;
temp=eye(size(Veh_Sham_Nodal_R_Graph,1));
temp = repmat(temp,1,1,size(Veh_Sham_Nodal_R_Graph,3));
idx=find(temp==1);
Veh_Sham_Nodal_R_Graph(idx)=0;
Veh_Sham_Nodal_R_Graph(Veh_Sham_Nodal_R_Graph<threshold)=0; % threshold

disp(['  took ' num2str(toc(t0)) ' seconds.']);

clear MTEP_Sham Veh_Sham

%% save

disp('save');
%
%     save(['D:\data\StrokeMTEP\' saveFileName 'Abs.mat'],'MTEP_PT_Nodal_R',...
%         'Veh_PT_Nodal_R','MTEP_Sham_Nodal_R','Veh_Sham_Nodal_R',...
%         'MTEP_PT_Nodal_R_Graph','Veh_PT_Nodal_R_Graph',...
%         'MTEP_Sham_Nodal_R_Graph','Veh_Sham_Nodal_R_Graph',...
%         'isbrain','seednames','nodeIndOriginalSpace','seedCenter');
save(['D:\data\StrokeMTEP\' saveFileName '.mat'],'MTEP_PT_Nodal_R',...
    'Veh_PT_Nodal_R','MTEP_Sham_Nodal_R','Veh_Sham_Nodal_R',...
    'MTEP_PT_Nodal_R_Graph','Veh_PT_Nodal_R_Graph',...
    'MTEP_Sham_Nodal_R_Graph','Veh_Sham_Nodal_R_Graph',...
    'isbrain','seednames','nodeIndOriginalSpace','seedCenter');
%% plot

cMin = -1;
cMax = 1;


% params
xRotAngle = 90; % degrees
% roiInd = [2:20 22:40];
% roiInd = [13:20 24:29 33:40];
% roiInd = [12:18 22:25 29:42];

disp('plot');

% seeds
figure('Position',[100 100 500 500]);
x = zeros(128);
x(isbrain) = -10;
for seed = 1:numel(nodeIndOriginalSpace); x(nodeIndOriginalSpace{seed}) = seed; end
alphaData = x~=0;
imagesc(x,'AlphaData',alphaData);
colormap('jet');
title('Seed locations');

figure('Position',[100 100 500 500]);
x = zeros(128);
x(isbrain) = -10;
for seed = roiInd; x(nodeIndOriginalSpace{seed}) = seed; end
alphaData = x~=0;
imagesc(x,'AlphaData',alphaData,[-10 numel(nodeIndOriginalSpace)]);
colormap('jet');
title('Seed locations');

% raw
figure('Position',[50 50 1120 950]);
subplot(2,2,1);
imagesc(mean(Veh_Sham_Nodal_R(roiInd,roiInd,:),3),[cMin cMax]);
% imagesc(abs(mean(Veh_Sham_Nodal_R(roiInd,roiInd,:),3)),[0 1]);
set(gca,'FontSize',7);
colorbar;
colormap('jet');
title('Vehicle Sham');
set(gca,'XTick',1:numel(roiInd));
set(gca,'XTickLabel',seednames(roiInd));
set(gca,'YTick',1:numel(roiInd));
set(gca,'YTickLabel',seednames(roiInd));
xtickangle(xRotAngle);

subplot(2,2,2);
imagesc(mean(MTEP_Sham_Nodal_R(roiInd,roiInd,:),3),[cMin cMax]);
% imagesc(abs(mean(MTEP_Sham_Nodal_R(roiInd,roiInd,:),3)),[0 1]);
set(gca,'FontSize',7);
colorbar;
colormap('jet');
title('MTEP Sham');
set(gca,'XTick',1:numel(roiInd));
set(gca,'XTickLabel',seednames(roiInd));
set(gca,'YTick',1:numel(roiInd));
set(gca,'YTickLabel',seednames(roiInd));
xtickangle(xRotAngle);

subplot(2,2,3);
imagesc(mean(Veh_PT_Nodal_R(roiInd,roiInd,:),3),[cMin cMax]);
% imagesc(abs(mean(Veh_PT_Nodal_R(roiInd,roiInd,:),3)),[0 1]);
set(gca,'FontSize',7);
colorbar;
colormap('jet');
title('Vehicle PT');
set(gca,'XTick',1:numel(roiInd));
set(gca,'XTickLabel',seednames(roiInd));
set(gca,'YTick',1:numel(roiInd));
set(gca,'YTickLabel',seednames(roiInd));
xtickangle(xRotAngle);

subplot(2,2,4);
imagesc(mean(MTEP_PT_Nodal_R(roiInd,roiInd,:),3),[cMin cMax]);
% imagesc(abs(mean(MTEP_PT_Nodal_R(roiInd,roiInd,:),3)),[0 1]);
set(gca,'FontSize',7);
colorbar;
colormap('jet');
title('MTEP PT');
set(gca,'XTick',1:numel(roiInd));
set(gca,'XTickLabel',seednames(roiInd));
set(gca,'YTick',1:numel(roiInd));
set(gca,'YTickLabel',seednames(roiInd));
xtickangle(xRotAngle);

% raw differences
cMap = blueWhiteRed(100);
figure('Position',[150 150 600 500]);
imagesc(mean(MTEP_Sham_Nodal_R(roiInd,roiInd,:),3)...
    -mean(Veh_Sham_Nodal_R(roiInd,roiInd,:),3),[-0.5 0.5]);
colorbar;
colormap(cMap);
title('MTEP Sham - Vehicle Sham');
set(gca,'XTick',1:numel(roiInd));
set(gca,'XTickLabel',seednames(roiInd));
set(gca,'YTick',1:numel(roiInd));
set(gca,'YTickLabel',seednames(roiInd));
xtickangle(xRotAngle);

figure('Position',[150 150 600 500]);
imagesc(mean(Veh_PT_Nodal_R(roiInd,roiInd,:),3)...
    -mean(Veh_Sham_Nodal_R(roiInd,roiInd,:),3),[-0.5 0.5]);
colorbar;
colormap(cMap);
title('Vehicle PT - Vehicle Sham');
set(gca,'XTick',1:numel(roiInd));
set(gca,'XTickLabel',seednames(roiInd));
set(gca,'YTick',1:numel(roiInd));
set(gca,'YTickLabel',seednames(roiInd));
xtickangle(xRotAngle);

figure('Position',[150 150 600 500]);
imagesc(mean(MTEP_PT_Nodal_R(roiInd,roiInd,:),3)...
    -mean(MTEP_Sham_Nodal_R(roiInd,roiInd,:),3),[-0.5 0.5]);
colorbar;
colormap(cMap);
title('MTEP PT - MTEP Sham');
set(gca,'XTick',1:numel(roiInd));
set(gca,'XTickLabel',seednames(roiInd));
set(gca,'YTick',1:numel(roiInd));
set(gca,'YTickLabel',seednames(roiInd));
xtickangle(xRotAngle);

figure('Position',[150 150 600 500]);
imagesc(mean(MTEP_PT_Nodal_R(roiInd,roiInd,:),3)...
    -mean(Veh_PT_Nodal_R(roiInd,roiInd,:),3),[-0.5 0.5]);
colorbar;
colormap(cMap);
title('MTEP PT - Vehicle PT');
set(gca,'XTick',1:numel(roiInd));
set(gca,'XTickLabel',seednames(roiInd));
set(gca,'YTick',1:numel(roiInd));
set(gca,'YTickLabel',seednames(roiInd));
xtickangle(xRotAngle);

% weighted distance
figure('Position',[50 50 1120 950]);
subplot(2,2,1);
[~,distance] = corr2pathLen(mean(Veh_Sham_Nodal_R_Graph(roiInd,roiInd,:),3));
imagesc(distance,[0 20]);
set(gca,'FontSize',7);
colorbar;
colormap('jet');
title('Vehicle Sham');
set(gca,'XTick',1:numel(roiInd));
set(gca,'XTickLabel',seednames(roiInd));
set(gca,'YTick',1:numel(roiInd));
set(gca,'YTickLabel',seednames(roiInd));
xtickangle(xRotAngle);

subplot(2,2,2);
[~,distance] = corr2pathLen(mean(MTEP_Sham_Nodal_R_Graph(roiInd,roiInd,:),3));
imagesc(distance,[0 20]);
set(gca,'FontSize',7);
colorbar;
colormap('jet');
title('MTEP Sham');
set(gca,'XTick',1:numel(roiInd));
set(gca,'XTickLabel',seednames(roiInd));
set(gca,'YTick',1:numel(roiInd));
set(gca,'YTickLabel',seednames(roiInd));
xtickangle(xRotAngle);

subplot(2,2,3);
[~,distance] = corr2pathLen(mean(Veh_PT_Nodal_R_Graph(roiInd,roiInd,:),3));
imagesc(distance,[0 20]);
set(gca,'FontSize',7);
colorbar;
colormap('jet');
title('Vehicle PT');
set(gca,'XTick',1:numel(roiInd));
set(gca,'XTickLabel',seednames(roiInd));
set(gca,'YTick',1:numel(roiInd));
set(gca,'YTickLabel',seednames(roiInd));
xtickangle(xRotAngle);

subplot(2,2,4);
[~,distance] = corr2pathLen(mean(MTEP_PT_Nodal_R_Graph(roiInd,roiInd,:),3));
imagesc(distance,[0 20]);
set(gca,'FontSize',7);
colorbar;
colormap('jet');
title('MTEP PT');
set(gca,'XTick',1:numel(roiInd));
set(gca,'XTickLabel',seednames(roiInd));
set(gca,'YTick',1:numel(roiInd));
set(gca,'YTickLabel',seednames(roiInd));
xtickangle(xRotAngle);

% weighted distance differences
cMap = blueWhiteRed(100);

figure('Position',[150 150 600 500]);
[~,distance1] = corr2pathLen(mean(Veh_Sham_Nodal_R_Graph(roiInd,roiInd,:),3));
[~,distance2] = corr2pathLen(mean(MTEP_Sham_Nodal_R_Graph(roiInd,roiInd,:),3));
imagesc(distance2 - distance1,[-12 12]);
set(gca,'FontSize',9);
colorbar;
colormap(cMap);
set(gca,'XTick',1:numel(roiInd));
set(gca,'XTickLabel',seednames(roiInd));
set(gca,'YTick',1:numel(roiInd));
set(gca,'YTickLabel',seednames(roiInd));
xtickangle(xRotAngle);
title('MTEP Sham - Vehicle Sham');

figure('Position',[150 150 600 500]);
[~,distance1] = corr2pathLen(mean(Veh_Sham_Nodal_R_Graph(roiInd,roiInd,:),3));
[~,distance2] = corr2pathLen(mean(Veh_PT_Nodal_R_Graph(roiInd,roiInd,:),3));
imagesc(distance2 - distance1,[-12 12]);
set(gca,'FontSize',9);
colorbar;
colormap(cMap);
set(gca,'XTick',1:numel(roiInd));
set(gca,'XTickLabel',seednames(roiInd));
set(gca,'YTick',1:numel(roiInd));
set(gca,'YTickLabel',seednames(roiInd));
xtickangle(xRotAngle);
title('Vehicle PT - Vehicle Sham');

figure('Position',[150 150 600 500]);
[~,distance1] = corr2pathLen(mean(MTEP_Sham_Nodal_R_Graph(roiInd,roiInd,:),3));
[~,distance2] = corr2pathLen(mean(MTEP_PT_Nodal_R_Graph(roiInd,roiInd,:),3));
imagesc(distance2 - distance1,[-12 12]);
set(gca,'FontSize',9);
colorbar;
colormap(cMap);
set(gca,'XTick',1:numel(roiInd));
set(gca,'XTickLabel',seednames(roiInd));
set(gca,'YTick',1:numel(roiInd));
set(gca,'YTickLabel',seednames(roiInd));
xtickangle(xRotAngle);
title('MTEP PT - MTEP Sham');

figure('Position',[150 150 600 500]);
[~,distance1] = corr2pathLen(mean(Veh_PT_Nodal_R_Graph(roiInd,roiInd,:),3));
[~,distance2] = corr2pathLen(mean(MTEP_PT_Nodal_R_Graph(roiInd,roiInd,:),3));
imagesc(distance2 - distance1,[-12 12]);
set(gca,'FontSize',9);
colorbar;
colormap(cMap);
title('Vehicle Sham');
set(gca,'XTick',1:numel(roiInd));
set(gca,'XTickLabel',seednames(roiInd));
set(gca,'YTick',1:numel(roiInd));
set(gca,'YTickLabel',seednames(roiInd));
xtickangle(xRotAngle);
title('MTEP PT - Vehicle PT');