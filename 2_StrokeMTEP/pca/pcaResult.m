% saves PCA result and plots it

dataFile = 'D:\data\StrokeMTEP\PT_Groups_Tad_single.mat';
saveFile = 'D:\data\StrokeMTEP\PT_Groups_PCA.mat';
componentNum = 20;

%% loading

% seed locations
load('D:\data\StrokeMTEP\AtlasandIsbrain.mat');

seednames{4} = 'M2'; % M2 and M1 flipped in loaded data
seednames{5} = 'M1';
seednames = repmat(seednames,1,2); % for both left and right

% actual data
load('D:\data\StrokeMTEP\MTEP_PTminusVeh_PCA.mat','symisbrainall');
load(dataFile);
disp('loading done');

% preprocess
data1 = Veh_PT;
data2 = MTEP_PT;
clear Veh_PT;
clear MTEP_PT;
itep = logical(diag(ones(size(data1,1),1)));
itep1 = repmat(itep,[1 1 size(data1,3)]);
itep2 = repmat(itep,[1 1 size(data2,3)]);
data1(logical(itep1)) = 0;
data2(logical(itep2)) = 0;

diffData = mean(data2,3) - mean(data1,3);
[coeff, score, latent, tsquared, var, mu]=pca(diffData,'NumComponents',20);

scoreWithMean = diffData*coeff;

save(saveFile,'coeff','score','scoreWithMean','latent','tsquared','var','mu');
disp('PCA done')

%% plotting

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

for n=1:size(idx_inv,1)
    Seedidx2Maskidx(n)=find(idx_inv==idx(n),1, 'first'); % make a mapping vector between the indicies in the brain mask and the Pix-Pix organization
end


%% plot
cMap = blueWhiteRed(100);

figure('Position',[50 650 1700 300]);
yReshaped = nan(128,128);
for n =1:5
    subplot(1,5,n);
    alpha = double(symisbrainall);
    z = coeff(:,n);
    yReshaped(idx_inv) = z;
    imagesc(yReshaped,'AlphaData',alpha,[-0.02 0.02]);
    colormap('jet');
    if n == 5
    axPos = get(gca,'position');
    colorbar;
    set(gca,'Position',axPos);
    end
    set(gca,'color',0.5*[1 1 1]);
    title(num2str(var(n)));
    set(gca,'Visible','off');
end

figure('Position',[50 350 1700 300]);
yReshaped = nan(128,128);
for n =1:5
    subplot(1,5,n);
    alpha = double(symisbrainall);
    z = scoreWithMean(:,n);
    yReshaped(idx_inv) = z;
    imagesc(yReshaped,'AlphaData',alpha,[-10 10]);
    colormap('jet');
    if n == 5
    axPos = get(gca,'position');
    colorbar;
    set(gca,'Position',axPos);
    end
    set(gca,'color',0.5*[1 1 1]);
    title(num2str(var(n)));
    set(gca,'Visible','off');
end

figure('Position',[50 50 1700 300]);
yReshaped = nan(128,128);
for n =1:5
    subplot(1,5,n);
    alpha = double(symisbrainall);
    z = scoreWithMean(:,n)*coeff(:,n)';
    yReshaped(idx_inv) = mean(z,2);
    imagesc(yReshaped,'AlphaData',alpha,[-0.01 0.01]);
    colormap('jet');
    if n == 5
    axPos = get(gca,'position');
    colorbar;
    set(gca,'Position',axPos);
    end
    set(gca,'color',0.5*[1 1 1]);
    title(num2str(var(n)));
    set(gca,'Visible','off');
    
    if n < 3
        hold on;
        
        for seed = 1:size(seedCenter,1)
            text(seedCenter(seed,1),seedCenter(seed,2),seednames{seed},'HorizontalAlignment','center');
        end
        
        hold off;
    end
end