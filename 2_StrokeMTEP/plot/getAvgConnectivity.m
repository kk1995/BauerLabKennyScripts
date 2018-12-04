rawFile = "D:\data\StrokeMTEP\PT_Groups_Tad_single.mat";
saveFile = "D:\data\StrokeMTEP\PT_Groups_avg_reorganized.mat";
maskFile = 'D:\data\atlas.mat';

%%
load(rawFile);

MTEP_PT = nanmean(MTEP_PT,3);
Veh_PT = nanmean(Veh_PT,3);
diff_PT = MTEP_PT - Veh_PT;

% diagonal
dInd = 1:size(MTEP_PT,1)+1:numel(MTEP_PT);
diff_PT(dInd) = 0;
MTEP_PT(dInd) = inf;
Veh_PT(dInd) = inf;

%% load region indices

load(maskFile,'mask','mask2','AtlasSeedsFilled','seednames'); % mask

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

extraneous = B==0;
B(extraneous) = [];
I(extraneous) = [];

regionEnd = [find(diff(B)~=0); numel(B)];
regionStart = [1; find(diff(B)~=0)+1];

tickInd = (regionStart + regionEnd)./2;
tickInd = round(tickInd);

% ss
regionEnd(6) = regionEnd(11);
regionEnd(26) = regionEnd(31);
tickInd(6) = mean(tickInd(6:11));
tickInd(26) = mean(tickInd(26:31));

% parietal
regionEnd(13) = regionEnd(15);
regionEnd(33) = regionEnd(35);
tickInd(13) = mean(tickInd(13:15));
tickInd(33) = mean(tickInd(33:35));

tickInd([7:11 14:15 20 27:31 34:35 40]) = [];
regionStart([7:11 14:15 20 27:31 34:35 40]) = [];
regionEnd([7:11 14:15 20 27:31 34:35 40]) = [];

%% remap data to region indices

MTEP_PT = MTEP_PT(I,I);
Veh_PT = Veh_PT(I,I);
diff_PT = diff_PT(I,I);

%%

save(saveFile,'MTEP_PT','Veh_PT','diff_PT','tickInd','regionStart','regionEnd','-v7.3');