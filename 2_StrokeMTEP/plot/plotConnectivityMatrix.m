% param
rawFile = 'D:\data\StrokeMTEP\PT_Groups_Tad_single.mat';
maskFile = 'D:\data\atlas.mat';

% load
load(rawFile); % Veh_PT, MTEP_PT
load(maskFile,'mask','mask2','AtlasSeedsFilled','seednames'); % mask

Veh_PT = tanh(Veh_PT);
MTEP_PT = tanh(MTEP_PT);
Veh_PT = nanmean(Veh_PT,3);
MTEP_PT = nanmean(MTEP_PT,3);


%%
% make sure the mask has all 40 regions
for x = 65:128
    for y = 1:128
        if AtlasSeedsFilled(y,x) ~=0
            AtlasSeedsFilled(y,x) = AtlasSeedsFilled(y,x) + 20;
        end
    end
end

% remap spatial ind
SeedsUsed=CalcRasterSeedsUsed(mask);
idx=find(mask==1);
length=size(SeedsUsed,1);
map=[(1:2:length-1) (2:2:length)];
NewSeedsUsed(:,1)=SeedsUsed(map, 1);
NewSeedsUsed(:,2)=SeedsUsed(map, 2);
for n=1:size(NewSeedsUsed,1)
    idx_inv(n)=sub2ind([128,128], NewSeedsUsed(n,2), NewSeedsUsed(n,1)); % get the indices of the Seed coordinates used to organize the Pix-Pix matrix
    idx_inv=idx_inv';
end
[B,I] = sort(AtlasSeedsFilled(idx_inv),'ascend');
% regionEndInd = [find(diff(B)>0); numel(B)]; regionEndInd(1) = [];
% regionStartInd = find(diff(B)>0) + 1;

extraneous = B==0;
B(extraneous) = [];
I(extraneous) = [];

regionEnd = [find(diff(B)~=0); numel(B)];
regionStart = [1; find(diff(B)~=0)+1];
tickLabels = seednames;

%%
% for i = 1:20
%     tickLabels{i} = [tickLabels{i} '-L'];
% end
% for i = 21:40
%     tickLabels{i} = [tickLabels{i} '-R'];
% end

% newRegionEnd = nan(1,40);
% newRegionStart = nan(1,40);
% newTickLabels = cell(1,40);

% % left
% newRegionStart(1) = regionStart(2);
% newRegionEnd(1) = regionEnd(2);
% newRegionStart(2) = regionStart(4);
% newRegionEnd(2) = regionEnd(5);
% newRegionStart(3) = regionStart(6);
% newRegionEnd(3) = regionEnd(11);
% newRegionStart(4) = regionStart(13);
% newRegionEnd(4) = regionEnd(15);
% newRegionStart(5) = regionStart(16);
% newRegionEnd(5) = regionEnd(18);
% % right
% newRegionStart(6) = regionStart(22);
% newRegionEnd(6) = regionEnd(22);
% newRegionStart(7) = regionStart(24); 
% newRegionEnd(7) = regionEnd(25);
% newRegionStart(8) = regionStart(26);
% newRegionEnd(8) = regionEnd(31);
% newRegionStart(9) = regionStart(33);
% newRegionEnd(9) = regionEnd(35);
% newRegionStart(10) = regionStart(36);
% newRegionEnd(10) = regionEnd(38);
% 
% % left
% newTickLabels{1} = 'Frontal-L';
% newTickLabels{2} = 'Motor-L';
% newTickLabels{3} = 'SS-L';
% newTickLabels{4} = 'Parietal-L';
% newTickLabels{5} = 'Visual-R';
% 
% % right
% newTickLabels{6} = 'Frontal-R';
% newTickLabels{7} = 'Motor-R';
% newTickLabels{8} = 'SS-R';
% newTickLabels{9} = 'Parietal-R';
% newTickLabels{10} = 'Visual-R';
% 
% tickInd = (regionStart + regionEnd)./2;
% tickInd = round(tickInd);

% ss
regionEnd(6) = regionEnd(11);
regionEnd(26) = regionEnd(31);

% parietal
regionEnd(13) = regionEnd(15);
regionEnd(33) = regionEnd(35);

regionStart([7:11 14:15 20 27:31 34:35 40]) = [];
regionEnd([7:11 14:15 20 27:31 34:35 40]) = [];
tickLabels([7:11 14:15 20 27:31 34:35 40]) = [];


tickInd = (regionStart + regionEnd)./2;
tickInd = round(tickInd);

tickLabels{6} = 'SS'; tickLabels{18} = 'SS';
tickLabels{8} = 'P'; tickLabels{20} = 'P';

tickLabels = string(tickLabels);

% % use simplified ticks
% tickInd = newtickInd;
% tickLabels = newTickLabels;


%% save
Veh_PT = Veh_PT(I,I);
MTEP_PT = MTEP_PT(I,I);

save('D:\data\StrokeMTEP\PT_Groups_avg_reorganized.mat','Veh_PT','MTEP_PT',...
    'regionStart','regionEnd','tickInd','tickLabels','-v7.3');

%% plot

angle = 90;

% plot matrix
f1 = figure('Position',[50 50 500 500]);
p = subplot(1,1,1);
imagesc(Veh_PT,[-1 1]);
yticks(tickInd);
yticklabels(tickLabels);
xticks(tickInd);
xticklabels(tickLabels);
xtickangle(angle);
colormap('jet');
colorbar;
axis(p,'square');
yl = get(gca,'YAxis');
xl = get(gca,'XAxis');
set([yl xl],'FontSize',7);
set(gca,'TickLength',[0 0]);
hold on;
for region = 1:numel(tickLabels)
    xHorz = [1 size(Veh_PT,1)];
    yHorz = [regionStart regionStart];
    plot(xHorz,yHorz,'k');
    
    xVert = [regionStart regionStart];
    yVert = [1 size(Veh_PT,1)];
    plot(xVert,yVert,'k');
end

% plot matrix
f2 = figure('Position',[50 50 500 500]);
p = subplot(1,1,1);
imagesc(MTEP_PT,[-1 1]);
yticks(tickInd);
yticklabels(tickLabels);
xticks(tickInd);
xticklabels(tickLabels);
xtickangle(angle);
colormap('jet');
colorbar;
axis(p,'square');
yl = get(gca,'YAxis');
xl = get(gca,'XAxis');
set([yl xl],'FontSize',7);
set(gca,'TickLength',[0 0]);
hold on;
for region = 1:numel(tickLabels)
    xHorz = [1 size(MTEP_PT,1)];
    yHorz = [regionStart regionStart];
    plot(xHorz,yHorz,'k');
    
    xVert = [regionStart regionStart];
    yVert = [1 size(MTEP_PT,1)];
    plot(xVert,yVert,'k');
end

% plot matrix
f3 = figure('Position',[50 50 500 500]);
p = subplot(1,1,1);
imagesc(MTEP_PT - Veh_PT,[-0.3 0.3]);
yticks(tickInd);
yticklabels(tickLabels);
xticks(tickInd);
xticklabels(tickLabels);
xtickangle(angle);
colormap('jet');
colorbar;
axis(p,'square');
yl = get(gca,'YAxis');
xl = get(gca,'XAxis');
set([yl xl],'FontSize',7);
set(gca,'TickLength',[0 0]);
hold on;
for region = 1:numel(tickLabels)
    xHorz = [1 size(MTEP_PT,1)];
    yHorz = [regionStart regionStart];
    plot(xHorz,yHorz,'k');
    
    xVert = [regionStart regionStart];
    yVert = [1 size(MTEP_PT,1)];
    plot(xVert,yVert,'k');
end