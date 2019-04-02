load('L:\ProcessedData\yvNullPC_latents.mat');
x1 = latentComb(:,1);
load('L:\ProcessedData\ov-yvPC_latents.mat');
x2 = latentComb(:,1);
load('L:\ProcessedData\od-yvPC_latents.mat');
x3 = latentComb(:,1);
load('L:\ProcessedData\od-ovPC_latents.mat');
x4 = latentComb(:,1);

[~,pVal12] = ttest2(x1,x2);
[~,pVal13] = ttest2(x1,x3);
[~,pVal14] = ttest2(x1,x4);
[~,pVal24] = ttest2(x2,x4);
[~,pVal23] = ttest2(x2,x3);

H = notBoxPlot([x1; x2; x3; x4],[ones(size(x1)); 2*ones(size(x2)); 3*ones(size(x3)); 4*ones(size(x4))]);
set([H(:).data],'MarkerSize',4,...
    'markerFaceColor',[1,1,1]*0.25,...
    'markerEdgeColor', 'none');
set([H(:).semPtch],...
    'FaceColor',[30 144 255]./256,...
    'EdgeColor','none');
set([H(:).sdPtch],...
    'FaceColor',[0 191 255]./256,...
    'EdgeColor','none');
set([H(:).mu],...
    'Color',[1,1,1]*0.75)
set(gca,'XTick',1:4,'XTickLabel',{'Young Vehicle','YV + OV','YV + OD','OV + OD'});

sigstar([1 2],pVal12);
sigstar([1 3],pVal13);
sigstar([1 4],pVal14);
sigstar([2 4],pVal24);
sigstar([2 3],pVal23);