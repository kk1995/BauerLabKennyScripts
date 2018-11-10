% load('D:\data\StrokeMTEP\NodalConnectivityAbs.mat');
load('D:\data\StrokeMTEP\NodalConnectivityDetailedMotorAbs.mat');

% params
roiInd = [2:20 22:40];
% roiInd = [13:20 24:29 33:40];
roiInd = [12:18 22:25 29:42];

xRotAngle = 90;

% select for roi
Veh_Sham_Nodal_R = Veh_Sham_Nodal_R(roiInd,roiInd,:);
MTEP_Sham_Nodal_R = MTEP_Sham_Nodal_R(roiInd,roiInd,:);
Veh_PT_Nodal_R = Veh_PT_Nodal_R(roiInd,roiInd,:);
MTEP_PT_Nodal_R = MTEP_PT_Nodal_R(roiInd,roiInd,:);

% % only consider the magnitude
% Veh_Sham_Nodal_R = abs(Veh_Sham_Nodal_R);
% MTEP_Sham_Nodal_R = abs(MTEP_Sham_Nodal_R);
% Veh_PT_Nodal_R = abs(Veh_PT_Nodal_R);
% MTEP_PT_Nodal_R = abs(MTEP_PT_Nodal_R);

Veh_Sham_Nodal_R_Graph = Veh_Sham_Nodal_R_Graph(roiInd,roiInd,:);
MTEP_Sham_Nodal_R_Graph = MTEP_Sham_Nodal_R_Graph(roiInd,roiInd,:);
Veh_PT_Nodal_R_Graph = Veh_PT_Nodal_R_Graph(roiInd,roiInd,:);
MTEP_PT_Nodal_R_Graph = MTEP_PT_Nodal_R_Graph(roiInd,roiInd,:);

indMat = 1:size(Veh_Sham_Nodal_R,1)*size(Veh_Sham_Nodal_R,2);
indMat = reshape(indMat,size(Veh_Sham_Nodal_R,1),size(Veh_Sham_Nodal_R,2));
indMat = extractSymmetricMatrix(indMat);

%% neg control

data1 = Veh_Sham_Nodal_R;
data2 = MTEP_Sham_Nodal_R;

data1Comparison = extractSymmetricMatrix(data1);
data2Comparison = extractSymmetricMatrix(data2);
[pTriangle, rejectTriangle] = multipleComparisons(data1Comparison,data2Comparison);
p = ones(size(data1,1),size(data1,2));
reject = false(size(data1,1),size(data1,2));
p(indMat) = pTriangle;
reject(indMat) = rejectTriangle;

cMap = blueWhiteRed(100,[0 1],true);
figure('Position',[150 150 600 500]);
imagesc(log(p)/log(10),[-7 -1]);
colormap(cMap);
colorbar;
set(gca,'XTick',1:numel(roiInd));
set(gca,'XTickLabel',seednames(roiInd));
set(gca,'YTick',1:numel(roiInd));
set(gca,'YTickLabel',seednames(roiInd));
title('Veh Sham vs MTEP Sham p value (log10 scale)');
xtickangle(xRotAngle);

figure('Position',[150 150 600 500]);
imagesc(log(p)/log(10),'AlphaData',reject,[-7 -1]);
set(gca,'color',0.5*[1 1 1]);
colormap(cMap);
colorbar;
set(gca,'XTick',1:numel(roiInd));
set(gca,'XTickLabel',seednames(roiInd));
set(gca,'YTick',1:numel(roiInd));
set(gca,'YTickLabel',seednames(roiInd));
title('Veh Sham vs MTEP Sham p value thresholded (log10 scale)');
xtickangle(xRotAngle);

cMap = blueWhiteRed(100);
figure('Position',[150 150 600 500]);
imagesc(mean(data2,3)-mean(data1,3),'AlphaData',reject,[-0.5 0.5]);
set(gca,'color',0.5*[1 1 1]);
colormap(cMap);
colorbar;
set(gca,'XTick',1:numel(roiInd));
set(gca,'XTickLabel',seednames(roiInd));
set(gca,'YTick',1:numel(roiInd));
set(gca,'YTickLabel',seednames(roiInd));
title('MTEP Sham - Vehicle Sham connectivity');
xtickangle(xRotAngle);

% data1 = Veh_Sham_Nodal_R_Graph;
% data2 = MTEP_Sham_Nodal_R_Graph;
% for i = 1:size(data1,3)
%     [~, data1(:,:,i)] = corr2pathLen(data1(:,:,i));
% end
% for i = 1:size(data2,3)
%     [~, data2(:,:,i)] = corr2pathLen(data2(:,:,i));
% end
% 
% 
% data1Comparison = extractSymmetricMatrix(data1);
% data2Comparison = extractSymmetricMatrix(data2);
% [pTriangle, rejectTriangle] = multipleComparisons(data1Comparison,data2Comparison);
% p = ones(size(data1,1),size(data1,2));
% reject = false(size(data1,1),size(data1,2));
% p(indMat) = pTriangle;
% reject(indMat) = rejectTriangle;
% p(isnan(p)) = 1;
% cMap = blueWhiteRed(100,[1 0],true);
% figure('Position',[150 150 600 500]);
% imagesc(log(p)/log(10),[-7 -1]);
% colormap(cMap);
% colorbar;
% set(gca,'XTick',1:numel(roiInd));
% set(gca,'XTickLabel',seednames(roiInd));
% set(gca,'YTick',1:numel(roiInd));
% set(gca,'YTickLabel',seednames(roiInd));
% title('Veh Sham vs MTEP Sham p value (log10 scale)');
% xtickangle(xRotAngle);
% 
% figure('Position',[150 150 600 500]);
% imagesc(log(p)/log(10),'AlphaData',reject,[-7 -1]);
% set(gca,'color',0.5*[1 1 1]);
% colormap(cMap);
% colorbar;
% set(gca,'XTick',1:numel(roiInd));
% set(gca,'XTickLabel',seednames(roiInd));
% set(gca,'YTick',1:numel(roiInd));
% set(gca,'YTickLabel',seednames(roiInd));
% title('Veh Sham vs MTEP Sham p value thresholded (log10 scale)');
% xtickangle(xRotAngle);
% 
% cMap = blueWhiteRed(100);
% figure('Position',[150 150 600 500]);
% imagesc(mean(data2,3)-mean(data1,3),'AlphaData',reject,[-12 12]);
% set(gca,'color',0.5*[1 1 1]);
% colormap(cMap);
% colorbar;
% set(gca,'XTick',1:numel(roiInd));
% set(gca,'XTickLabel',seednames(roiInd));
% set(gca,'YTick',1:numel(roiInd));
% set(gca,'YTickLabel',seednames(roiInd));
% title('MTEP Sham - Vehicle Sham connectivity');
% xtickangle(xRotAngle);

%% veh stroke
data1 = Veh_Sham_Nodal_R;
data2 = Veh_PT_Nodal_R;

data1Comparison = extractSymmetricMatrix(data1);
data2Comparison = extractSymmetricMatrix(data2);
[pTriangle, rejectTriangle] = multipleComparisons(data1Comparison,data2Comparison);
p = ones(size(data1,1),size(data1,2));
reject = true(size(data1,1),size(data1,2));
p(indMat) = pTriangle;
reject(indMat) = rejectTriangle;
cMap = blueWhiteRed(100,[0 1],true);
figure('Position',[150 150 600 500]);
imagesc(log(p)/log(10),[-7 -1]);
colormap(cMap);
colorbar;
set(gca,'XTick',1:numel(roiInd));
set(gca,'XTickLabel',seednames(roiInd));
set(gca,'YTick',1:numel(roiInd));
set(gca,'YTickLabel',seednames(roiInd));
title('Veh Sham vs Veh PT p value (log10 scale)');
xtickangle(xRotAngle);

figure('Position',[150 150 600 500]);
imagesc(log(p)/log(10),'AlphaData',reject,[-7 -1]);
set(gca,'color',0.5*[1 1 1]);
colormap(cMap);
colorbar;
set(gca,'XTick',1:numel(roiInd));
set(gca,'XTickLabel',seednames(roiInd));
set(gca,'YTick',1:numel(roiInd));
set(gca,'YTickLabel',seednames(roiInd));
title('Veh Sham vs Veh PT p value thresholded (log10 scale)');
xtickangle(xRotAngle);

cMap = blueWhiteRed(100);
figure('Position',[150 150 600 500]);
imagesc(mean(data2,3)-mean(data1,3),'AlphaData',reject,[-0.5 0.5]);
set(gca,'color',0.5*[1 1 1]);
colormap(cMap);
colorbar;
set(gca,'XTick',1:numel(roiInd));
set(gca,'XTickLabel',seednames(roiInd));
set(gca,'YTick',1:numel(roiInd));
set(gca,'YTickLabel',seednames(roiInd));
title('Vehicle PT - Vehicle Sham connectivity');
xtickangle(xRotAngle);

data1 = Veh_Sham_Nodal_R_Graph;
data2 = Veh_PT_Nodal_R_Graph;
for i = 1:size(data1,3)
    [~, data1(:,:,i)] = corr2pathLen(data1(:,:,i));
end
for i = 1:size(data2,3)
    [~, data2(:,:,i)] = corr2pathLen(data2(:,:,i));
end

data1Comparison = extractSymmetricMatrix(data1);
data2Comparison = extractSymmetricMatrix(data2);
[pTriangle, rejectTriangle] = multipleComparisons(data1Comparison,data2Comparison);
p = ones(size(data1,1),size(data1,2));
reject = true(size(data1,1),size(data1,2));
p(indMat) = pTriangle;
reject(indMat) = rejectTriangle;
p(isnan(p)) = 1;
cMap = blueWhiteRed(100,[0 1],true);
figure('Position',[150 150 600 500]);
imagesc(log(p)/log(10),[-7 -1]);
colormap(cMap);
colorbar;
set(gca,'XTick',1:numel(roiInd));
set(gca,'XTickLabel',seednames(roiInd));
set(gca,'YTick',1:numel(roiInd));
set(gca,'YTickLabel',seednames(roiInd));
title('Veh Sham vs Veh PT p value (log10 scale)');
xtickangle(xRotAngle);

figure('Position',[150 150 600 500]);
imagesc(log(p)/log(10),'AlphaData',reject,[-7 -1]);
set(gca,'color',0.5*[1 1 1]);
colormap(cMap);
colorbar;
set(gca,'XTick',1:numel(roiInd));
set(gca,'XTickLabel',seednames(roiInd));
set(gca,'YTick',1:numel(roiInd));
set(gca,'YTickLabel',seednames(roiInd));
title('Veh Sham vs Veh PT p value thresholded (log10 scale)');
xtickangle(xRotAngle);

cMap = blueWhiteRed(100);
figure('Position',[150 150 600 500]);
imagesc(mean(data2,3)-mean(data1,3),'AlphaData',reject,[-12 12]);
set(gca,'color',0.5*[1 1 1]);
colormap(cMap);
colorbar;
set(gca,'XTick',1:numel(roiInd));
set(gca,'XTickLabel',seednames(roiInd));
set(gca,'YTick',1:numel(roiInd));
set(gca,'YTickLabel',seednames(roiInd));
title('Vehicle PT - Vehicle Sham connectivity');
xtickangle(xRotAngle);

%% MTEP stroke
data1 = MTEP_Sham_Nodal_R;
data2 = MTEP_PT_Nodal_R;

data1Comparison = extractSymmetricMatrix(data1);
data2Comparison = extractSymmetricMatrix(data2);
[pTriangle, rejectTriangle] = multipleComparisons(data1Comparison,data2Comparison);
p = ones(size(data1,1),size(data1,2));
reject = true(size(data1,1),size(data1,2));
p(indMat) = pTriangle;
reject(indMat) = rejectTriangle;
cMap = blueWhiteRed(100,[0 1],true);
figure('Position',[150 150 600 500]);
imagesc(log(p)/log(10),[-7 -1]);
colormap(cMap);
colorbar;
set(gca,'XTick',1:numel(roiInd));
set(gca,'XTickLabel',seednames(roiInd));
set(gca,'YTick',1:numel(roiInd));
set(gca,'YTickLabel',seednames(roiInd));
title('MTEP Sham vs MTEP PT p value (log10 scale)');
xtickangle(xRotAngle);

figure('Position',[150 150 600 500]);
imagesc(log(p)/log(10),'AlphaData',reject,[-7 -1]);
set(gca,'color',0.5*[1 1 1]);
colormap(cMap);
colorbar;
set(gca,'XTick',1:numel(roiInd));
set(gca,'XTickLabel',seednames(roiInd));
set(gca,'YTick',1:numel(roiInd));
set(gca,'YTickLabel',seednames(roiInd));
title('MTEP Sham vs MTEP PT p value thresholded (log10 scale)');
xtickangle(xRotAngle);

cMap = blueWhiteRed(100);
figure('Position',[150 150 600 500]);
imagesc(mean(data2,3)-mean(data1,3),'AlphaData',reject,[-0.5 0.5]);
set(gca,'color',0.5*[1 1 1]);
colormap(cMap);
colorbar;
set(gca,'XTick',1:numel(roiInd));
set(gca,'XTickLabel',seednames(roiInd));
set(gca,'YTick',1:numel(roiInd));
set(gca,'YTickLabel',seednames(roiInd));
title('MTEP PT - MTEP Sham connectivity');
xtickangle(xRotAngle);

data1 = MTEP_Sham_Nodal_R_Graph;
data2 = MTEP_PT_Nodal_R_Graph;
for i = 1:size(data1,3)
    [~, data1(:,:,i)] = corr2pathLen(data1(:,:,i));
end
for i = 1:size(data2,3)
    [~, data2(:,:,i)] = corr2pathLen(data2(:,:,i));
end

data1Comparison = extractSymmetricMatrix(data1);
data2Comparison = extractSymmetricMatrix(data2);
[pTriangle, rejectTriangle] = multipleComparisons(data1Comparison,data2Comparison);
p = ones(size(data1,1),size(data1,2));
reject = true(size(data1,1),size(data1,2));
p(indMat) = pTriangle;
reject(indMat) = rejectTriangle;
p(isnan(p)) = 1;
cMap = blueWhiteRed(100,[0 1],true);
figure('Position',[150 150 600 500]);
imagesc(log(p)/log(10),[-7 -1]);
colormap(cMap);
colorbar;
set(gca,'XTick',1:numel(roiInd));
set(gca,'XTickLabel',seednames(roiInd));
set(gca,'YTick',1:numel(roiInd));
set(gca,'YTickLabel',seednames(roiInd));
title('MTEP Sham vs MTEP PT p value (log10 scale)');
xtickangle(xRotAngle);

figure('Position',[150 150 600 500]);
imagesc(log(p)/log(10),'AlphaData',reject,[-7 -1]);
set(gca,'color',0.5*[1 1 1]);
colormap(cMap);
colorbar;
set(gca,'XTick',1:numel(roiInd));
set(gca,'XTickLabel',seednames(roiInd));
set(gca,'YTick',1:numel(roiInd));
set(gca,'YTickLabel',seednames(roiInd));
title('MTEP Sham vs MTEP PT p value thresholded (log10 scale)');
xtickangle(xRotAngle);

cMap = blueWhiteRed(100);
figure('Position',[150 150 600 500]);
imagesc(mean(data2,3)-mean(data1,3),'AlphaData',reject,[-12 12]);
set(gca,'color',0.5*[1 1 1]);
colormap(cMap);
colorbar;
set(gca,'XTick',1:numel(roiInd));
set(gca,'XTickLabel',seednames(roiInd));
set(gca,'YTick',1:numel(roiInd));
set(gca,'YTickLabel',seednames(roiInd));
title('MTEP PT - MTEP Sham connectivity');
xtickangle(xRotAngle);

%% MTEP effect
data1 = Veh_PT_Nodal_R;
data2 = MTEP_PT_Nodal_R;

data1Comparison = extractSymmetricMatrix(data1);
data2Comparison = extractSymmetricMatrix(data2);
[pTriangle, rejectTriangle] = multipleComparisons(data1Comparison,data2Comparison);
p = ones(size(data1,1),size(data1,2));
reject = true(size(data1,1),size(data1,2));
p(indMat) = pTriangle;
reject(indMat) = rejectTriangle;
cMap = blueWhiteRed(100,[0 1],true);
figure('Position',[150 150 600 500]);
imagesc(log(p)/log(10),[-7 -1]);
colormap(cMap);
colorbar;
set(gca,'XTick',1:numel(roiInd));
set(gca,'XTickLabel',seednames(roiInd));
set(gca,'YTick',1:numel(roiInd));
set(gca,'YTickLabel',seednames(roiInd));
title('Veh PT vs MTEP PT p value (log10 scale)');
xtickangle(xRotAngle);

figure('Position',[150 150 600 500]);
imagesc(log(p)/log(10),'AlphaData',reject,[-7 -1]);
set(gca,'color',0.5*[1 1 1]);
colormap(cMap);
colorbar;
set(gca,'XTick',1:numel(roiInd));
set(gca,'XTickLabel',seednames(roiInd));
set(gca,'YTick',1:numel(roiInd));
set(gca,'YTickLabel',seednames(roiInd));
title('Veh PT vs MTEP PT p value thresholded (log10 scale)');
xtickangle(xRotAngle);

cMap = blueWhiteRed(100);
figure('Position',[150 150 600 500]);
imagesc(mean(data2,3)-mean(data1,3),'AlphaData',reject,[-0.5 0.5]);
set(gca,'color',0.5*[1 1 1]);
colormap(cMap);
colorbar;
set(gca,'XTick',1:numel(roiInd));
set(gca,'XTickLabel',seednames(roiInd));
set(gca,'YTick',1:numel(roiInd));
set(gca,'YTickLabel',seednames(roiInd));
title('MTEP PT - Veh PT connectivity');
xtickangle(xRotAngle);

data1 = Veh_PT_Nodal_R_Graph;
data2 = MTEP_PT_Nodal_R_Graph;
for i = 1:size(data1,3)
    [~, data1(:,:,i)] = corr2pathLen(data1(:,:,i));
end
for i = 1:size(data2,3)
    [~, data2(:,:,i)] = corr2pathLen(data2(:,:,i));
end

data1Comparison = extractSymmetricMatrix(data1);
data2Comparison = extractSymmetricMatrix(data2);
[pTriangle, rejectTriangle] = multipleComparisons(data1Comparison,data2Comparison);
p = ones(size(data1,1),size(data1,2));
reject = true(size(data1,1),size(data1,2));
p(indMat) = pTriangle;
reject(indMat) = rejectTriangle;
p(isnan(p)) = 1;
cMap = blueWhiteRed(100,[0 1],true);
figure('Position',[150 150 600 500]);
imagesc(log(p)/log(10),[-7 -1]);
colormap(cMap);
colorbar;
set(gca,'XTick',1:numel(roiInd));
set(gca,'XTickLabel',seednames(roiInd));
set(gca,'YTick',1:numel(roiInd));
set(gca,'YTickLabel',seednames(roiInd));
title('Veh PT vs MTEP PT p value (log10 scale)');
xtickangle(xRotAngle);

figure('Position',[150 150 600 500]);
imagesc(log(p)/log(10),'AlphaData',reject,[-7 -1]);
set(gca,'color',0.5*[1 1 1]);
colormap(cMap);
colorbar;
set(gca,'XTick',1:numel(roiInd));
set(gca,'XTickLabel',seednames(roiInd));
set(gca,'YTick',1:numel(roiInd));
set(gca,'YTickLabel',seednames(roiInd));
title('Veh PT vs MTEP PT p value thresholded (log10 scale)');
xtickangle(xRotAngle);

cMap = blueWhiteRed(100);
figure('Position',[150 150 600 500]);
imagesc(mean(data2,3)-mean(data1,3),'AlphaData',reject,[-12 12]);
set(gca,'color',0.5*[1 1 1]);
colormap(cMap);
colorbar;
set(gca,'XTick',1:numel(roiInd));
set(gca,'XTickLabel',seednames(roiInd));
set(gca,'YTick',1:numel(roiInd));
set(gca,'YTickLabel',seednames(roiInd));
title('MTEP PT - Veh PT connectivity');
xtickangle(xRotAngle);

%% Veh Sham vs MTEP PT
data1 = Veh_Sham_Nodal_R;
data2 = MTEP_PT_Nodal_R;

data1Comparison = extractSymmetricMatrix(data1);
data2Comparison = extractSymmetricMatrix(data2);
[pTriangle, rejectTriangle] = multipleComparisons(data1Comparison,data2Comparison);
p = ones(size(data1,1),size(data1,2));
reject = true(size(data1,1),size(data1,2));
p(indMat) = pTriangle;
reject(indMat) = rejectTriangle;
cMap = blueWhiteRed(100,[0 1],true);
figure('Position',[150 150 600 500]);
imagesc(log(p)/log(10),[-7 -1]);
colormap(cMap);
colorbar;
set(gca,'XTick',1:numel(roiInd));
set(gca,'XTickLabel',seednames(roiInd));
set(gca,'YTick',1:numel(roiInd));
set(gca,'YTickLabel',seednames(roiInd));
title('Veh Sham vs MTEP PT p value (log10 scale)');
xtickangle(xRotAngle);

figure('Position',[150 150 600 500]);
imagesc(log(p)/log(10),'AlphaData',reject,[-7 -1]);
set(gca,'color',0.5*[1 1 1]);
colormap(cMap);
colorbar;
set(gca,'XTick',1:numel(roiInd));
set(gca,'XTickLabel',seednames(roiInd));
set(gca,'YTick',1:numel(roiInd));
set(gca,'YTickLabel',seednames(roiInd));
title('Veh Sham vs MTEP PT p value thresholded (log10 scale)');
xtickangle(xRotAngle);

cMap = blueWhiteRed(100);
figure('Position',[150 150 600 500]);
imagesc(mean(data2,3)-mean(data1,3),'AlphaData',reject,[-0.5 0.5]);
set(gca,'color',0.5*[1 1 1]);
colormap(cMap);
colorbar;
set(gca,'XTick',1:numel(roiInd));
set(gca,'XTickLabel',seednames(roiInd));
set(gca,'YTick',1:numel(roiInd));
set(gca,'YTickLabel',seednames(roiInd));
title('MTEP PT - Veh Sham connectivity');
xtickangle(xRotAngle);

data1 = Veh_Sham_Nodal_R_Graph;
data2 = MTEP_PT_Nodal_R_Graph;
for i = 1:size(data1,3)
    [~, data1(:,:,i)] = corr2pathLen(data1(:,:,i));
end
for i = 1:size(data2,3)
    [~, data2(:,:,i)] = corr2pathLen(data2(:,:,i));
end

data1Comparison = extractSymmetricMatrix(data1);
data2Comparison = extractSymmetricMatrix(data2);
[pTriangle, rejectTriangle] = multipleComparisons(data1Comparison,data2Comparison);
p = ones(size(data1,1),size(data1,2));
reject = true(size(data1,1),size(data1,2));
p(indMat) = pTriangle;
reject(indMat) = rejectTriangle;
p(isnan(p)) = 1;
cMap = blueWhiteRed(100,[0 1],true);
figure('Position',[150 150 600 500]);
imagesc(log(p)/log(10),[-7 -1]);
colormap(cMap);
colorbar;
set(gca,'XTick',1:numel(roiInd));
set(gca,'XTickLabel',seednames(roiInd));
set(gca,'YTick',1:numel(roiInd));
set(gca,'YTickLabel',seednames(roiInd));
title('Veh Sham vs MTEP PT p value (log10 scale)');
xtickangle(xRotAngle);

figure('Position',[150 150 600 500]);
imagesc(log(p)/log(10),'AlphaData',reject,[-7 -1]);
set(gca,'color',0.5*[1 1 1]);
colormap(cMap);
colorbar;
set(gca,'XTick',1:numel(roiInd));
set(gca,'XTickLabel',seednames(roiInd));
set(gca,'YTick',1:numel(roiInd));
set(gca,'YTickLabel',seednames(roiInd));
title('Veh Sham vs MTEP PT p value thresholded (log10 scale)');
xtickangle(xRotAngle);

cMap = blueWhiteRed(100);
figure('Position',[150 150 600 500]);
imagesc(mean(data2,3)-mean(data1,3),'AlphaData',reject,[-12 12]);
set(gca,'color',0.5*[1 1 1]);
colormap(cMap);
colorbar;
set(gca,'XTick',1:numel(roiInd));
set(gca,'XTickLabel',seednames(roiInd));
set(gca,'YTick',1:numel(roiInd));
set(gca,'YTickLabel',seednames(roiInd));
title('MTEP PT - Veh Sham connectivity');
xtickangle(xRotAngle);