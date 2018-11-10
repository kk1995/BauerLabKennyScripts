% loads the null distribution of PCA results and compares to actual PCA

%% params

numComponents = 10;
maxIter = 2000;


%% get null
nullDataDir = 'D:\data\StrokeMTEP\nullExpIter';

D = dir(nullDataDir); D(1:2) = [];

nullExp = [];
nullLat = [];
% nullCoe = [];
% nullSco = [];
iterations = [];

for file = 1:numel(D)
    load(fullfile(nullDataDir,D(file).name),'nullLatent','nullExplained','iterationVal');
    nullLat = [nullLat nullLatent];
    nullExp = [nullExp nullExplained];
%     nullCoe = cat(3,nullCoe, nullCoeff);
%     nullSco = cat(3,nullSco,nullScore);
    iterations = [iterations iterationVal];
end


% make the results double
nullExp = double(nullExp);
nullLat = double(nullLat);

% remove repeats
[~,IA,~] = unique(iterations);
nullExp = nullExp(:,IA);
nullLat = nullLat(:,IA);
iterations = iterations(IA);

% only the first few components you are interested in
nullExp = nullExp(1:numComponents,IA);
nullLat = nullLat(1:numComponents,IA);


% take only the first n number of iterations
iterations = iterations(1:maxIter);
nullExp = nullExp(:,1:maxIter);
nullLat = nullLat(:,1:maxIter);

save(['null' num2str(maxIter) 'Iter.mat'],'iterations','nullExp','nullLat');

% get normalization factor

totalLatent = sum(nullLat,1)./(sum(nullExp,1)/100);
totalLatent = median(totalLatent);

% assign
% nullVal = nullLat;
nullVal = 100.*nullLat./totalLatent;
% nullVal = nullExp;

%% get actual PCA

pcaData = 'D:\data\StrokeMTEP\PT_Groups_PCA.mat';

load(pcaData); % loads results of PCA (latent, var)

actualVal = 100.*double(latent)./totalLatent;
% actualVal = double(var);
% actualVal = actualVal./totalLatent*100;
    % get the total latent (for normalization of null)
actualVal = actualVal(1:numComponents); % only select the first few components

%% compare null and actual PCA
pVal = nan(numel(actualVal),1);
upperThr = nan(numel(actualVal),1);
lowerThr = nan(numel(actualVal),1);

for pc = 1:numel(actualVal)
    actualPCVar = actualVal(pc); % this is in percentage
    nullPCVar = nullVal(pc,:); % this is in percentage
    
    
    % make t statistic that allows non-parametric comparison
    tStatDist = nullPCVar;
    tStat = actualPCVar;
%     tStatDist = abs(nullPCVar - median(nullPCVar));
%     tStat = abs(actualPCVar - median(nullPCVar));
    pVal(pc) = (sum(tStat < tStatDist)+1)./(numel(tStatDist)+1);
    
    % get threshold
%     lowerThr(pc) = prctile(nullPCVar,2.5);
    upperThr(pc) = prctile(nullPCVar,95);
    lowerThr(pc) = prctile(nullPCVar,5);
    
%     % get threshold by fitting to beta distribution
%     phat = betafit(double(nullPCVar)./100); % beta parameter estimates
%     x = linspace(0,1,1001);
%     cumProb = betacdf(x,phat(1),phat(2));
%     upperThr(pc) = x(find(cumProb > 0.95,1,'first'))*100;
%     lowerThr(pc) = x(find(cumProb < 0.05,1,'last'))*100;
end

%% plot

% initialize figure
figure('Position',[100 200 600 500]);


pcInd = 1:numComponents;

colorOrder = get(gca,'defaultAxesColorOrder');

% plot the null hypothesis
hold on;
medianNull = median(nullVal,2);
upperError = upperThr - medianNull;
lowerError = medianNull;
midLine = boundedline(pcInd,medianNull,[lowerError upperError],'cmap',colorOrder(2,:),'-o','alpha');
set(gca,'fontname','helvetica');
thrLine = plot(pcInd,upperThr,'-','Color', colorOrder(2,:),'MarkerFaceColor', colorOrder(2,:));
set(thrLine,'LineWidth',1);
set(midLine,'LineWidth',1);
set(midLine,'MarkerFaceColor',colorOrder(2,:));
ylim([0 max([actualVal; upperThr])+8]);

% subplot(1,2,1);
% plot the actual PC variance
line = plot(pcInd,actualVal,'o','Color', colorOrder(1,:),'MarkerFaceColor', colorOrder(1,:),'LineWidth',2);
title(['Principal components significance (n = ' num2str(size(nullLat,2)) ')']);
set(gca,'XTick',1:numComponents);
set(gca,'XTickLabel',1:numComponents);
xlim([0.25 numComponents+0.5]);
ylabel('Variance');
xlabel('PCs')
hold on;
lowerBound = [0 0 0 0 0 0 0 0 0 0];
for pc = 1:numel(upperThr)
    y = linspace(lowerBound(pc),actualVal(pc),10);
    x = pc*ones(size(y));
    plot(x,y,'Color',colorOrder(1,:),'LineWidth',0.5);
end

lgd = legend([midLine line],'Null distribution (95th percentile)','Connectivity variance');
set(lgd,'Position',[0.65 0.82 0.1 0.08]);

shiftUp = 0.5.*log(actualVal).*ones(size(actualVal))+3;
textYLoc = actualVal;
for pc = 1:10
    textYLoc(pc) = textYLoc(pc) + shiftUp(pc);
end
text(1,textYLoc(1), ['p=' strrep(num2str(pVal(1),'%.4f'),'0.','.')],...
        'FontWeight','bold','HorizontalAlignment','center','Color','k','fontname','helvetica');
for pc = 2:numel(pVal)
%     text(pc,max([actualVal; upperThr])+3.5,num2str(pVal(pc),'%.3f'),'HorizontalAlignment','center','Color',colorOrder(1,:));
    text(pc,textYLoc(pc), strrep(num2str(pVal(pc),'%.3f'),'0.','.'),...
        'FontWeight','bold','HorizontalAlignment','center','Color','k','fontname','helvetica');
end

%%

load('D:\data\StrokeMTEP\MTEP_PTminusVeh_PCA.mat','symisbrainall');

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


nullCoeffShaped = nan(128*128,20,size(nullCoe,3));
nullCoeffShaped(idx_inv,:,:) = squeeze(nullCoe);
nullCoeffShaped = reshape(nullCoeffShaped,[128 128 20 size(nullCoe,3)]);

nullScoreShaped = nan(128*128,20,size(nullSco,3));
nullScoreShaped(idx_inv,:,:) = squeeze(nullSco);
nullScoreShaped = reshape(nullScoreShaped,[128 128 20 size(nullSco,3)]);


figure('Position',[50 650 1700 300]);
for i = 1:100
    for j = 1:5
        subplot(1,5,j);
        imagesc(squeeze(nullCoeffShaped(:,:,j,i)),[-0.01 0.01]); colormap('jet');
    end
    pause(4);
end
% using standard deviation

% subplot(1,2,2);
% 
% % plot the actual PC variance
% pcInd = 1:numComponents;
% plot(pcInd,actualVal,'o');
% title(['Principal components significance (n=' num2str(size(nullLat,2)) '), 2.5 sd ' edge]);
% set(gca,'XTick',1:numComponents);
% set(gca,'XTickLabel',1:numComponents);
% xlim([0.5 numComponents+0.5]);
% ylabel('Variance');
% xlabel('PCs')
% 
% % plot the null hypothesis
% hold on;
% sd = std(nullVal,[],2);
% boundedline(pcInd,mean(nullVal,2),2.5*[sd sd],'--ro','alpha');
% % plot(pcInd,mean(nullVal,2)+2.5*sd,'*');
% ylim([0 max([actualVal; mean(nullVal,2)+2.5*sd])+10]);
% 
% for pc = 1:numel(pVal)
% text(pc,max([actualVal; mean(nullVal,2)+2.5*sd])+8,num2str(pVal(pc)),'HorizontalAlignment','center');
% end