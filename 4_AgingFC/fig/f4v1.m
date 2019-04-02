dataFile = "L:\ProcessedData\deborah\avgFC_gsr.mat";
atlasFile = "D:\data\atlas12.mat";

load(dataFile);
load(atlasFile);

labels = {'Frontal','Motor','SS','RS','Parietal','Visual'};
labels = repmat(labels,1,2);

groupFC = cat(3,yvFC,ovFC,odFC);

clear yvFC
clear ovFC
clear odFC

groupNum = size(groupFC,3);
[B,I] = sort(atlas(:));

groupFC2 = [];
nanInd = [];
for i = 1:groupNum
    fc = groupFC(:,:,i);
    fc = fc(I,I);
    fc(B == 0,:) = [];
    fc(:,B == 0) = [];
    labelInd = B(B > 0);
    
    groupFC2(:,:,i) = fc;
    nanInd(i,:) = isnan(fc(1:(size(fc,1)+1):end));
end
groupFC = groupFC2;
clear groupFC2

groupFC(sum(nanInd,1) > 0,:,:) = [];
groupFC(:,sum(nanInd,1) > 0,:) = [];
labelInd(sum(nanInd,1) > 0) = [];

labelTickStart = [1; find(diff(labelInd) > 0) + 1];
labelTickEnd = [find(diff(labelInd) > 0); numel(labelInd)];

tooSmallInd = find((labelTickEnd - labelTickStart + 1) < round(size(fc,1)*0));
tooSmall = false(numel(labelInd),1);
for i = 1:numel(tooSmallInd)
    tooSmall(tooSmallInd(i) == labelInd) = true;
end

labelInd = labelInd(~tooSmall);

labelTickStart = [1; find(diff(labelInd) > 0) + 1];
labelTickEnd = [find(diff(labelInd) > 0); numel(labelInd)];
labelTickMiddle = round((labelTickStart + labelTickEnd)/2);
labels = labels(unique(labelInd));
groupFC = groupFC(:,~tooSmall,:);
groupFC = groupFC(~tooSmall,:,:);

groupFC = real(groupFC);

%% plot

cMap = jet(100);

f1 = figure('Position',[100 50 1500 920]);
p = panel();
p.pack(2,3);
p.marginright = 15;

p(1,1).select();
set(gca,'Color',[1,1,1,0]);
set(gca,'FontSize',12);
diffFC = diff(groupFC(:,:,[2 1]),1,3);
imagesc(diffFC,[-0.31 0.31]); colormap(cMap); pause(0.1);
ch = colorbar; ylabh = ylabel(ch,'correlation coefficient, z(r)');
set(ylabh,'Units','normalized');
set(ylabh,'position',get(ylabh,'position') - [0.5 0 0]);
hold on;
for i = 1:numel(labelTickStart)
    plot([labelTickStart(i) labelTickStart(i)],[1 size(fc,1)],'k');
    plot([1 size(fc,1)],[labelTickStart(i) labelTickStart(i)],'k');
end
hold off;
set(gca,'YDir','reverse'); ylim([0.5 size(groupFC,1)+0.5]); xlim([0.5 size(groupFC,1)+0.5]);
axis(gca,'square'); yticks(labelTickMiddle); xticks(labelTickMiddle);
yticklabels(labels); xticklabels(labels); xtickangle(90);
ax = gca;
yrule = ax.YAxis;
yrule.FontSize = 8;
xrule = ax.XAxis;
xrule.FontSize = 8;
title('Old Vehicle - Young Vehicle');

p(2,1).select();
set(gca,'Color',[1,1,1,0]);
set(gca,'FontSize',12);
diffFC = diff(groupFC(:,:,[3 2]),1,3);
imagesc(diffFC,[-0.31 0.31]); colormap(cMap); pause(0.1);
ch = colorbar; ylabh = ylabel(ch,'correlation coefficient, z(r)');
set(ylabh,'Units','normalized');
set(ylabh,'position',get(ylabh,'position') - [0.5 0 0]);
hold on;
for i = 1:numel(labelTickStart)
    plot([labelTickStart(i) labelTickStart(i)],[1 size(fc,1)],'k');
    plot([1 size(fc,1)],[labelTickStart(i) labelTickStart(i)],'k');
end
hold off;
set(gca,'YDir','reverse'); ylim([0.5 size(groupFC,1)+0.5]); xlim([0.5 size(groupFC,1)+0.5]);
axis(gca,'square'); yticks(labelTickMiddle); xticks(labelTickMiddle);
yticklabels(labels); xticklabels(labels); xtickangle(90);
ax = gca;
yrule = ax.YAxis;
yrule.FontSize = 8;
xrule = ax.XAxis;
xrule.FontSize = 8;
title('Old Drug - Old Vehicle');

%% get pca data

pcaFileList = ["L:\ProcessedData\deborah\ov-yvPCs.mat","L:\ProcessedData\deborah\od-ovPCs.mat"];
hemisphereData = load("L:\ProcessedData\deborah\deborahHemisphereMask.mat");

coeffs = zeros(128^2,3,2);
explained = {};
brain = false(128,128,2);

pcNum = 3;

for pcaFileInd = 1:2
    pcaDataObj = matfile(pcaFileList(pcaFileInd));
    coeff = pcaDataObj.coeff(:,1:pcNum);
    explained{pcaFileInd} = pcaDataObj.explained;
    brain(:,:,pcaFileInd) = reshape(pcaDataObj.brain,128,128);
    noVasculature = hemisphereData.leftMask | hemisphereData.rightMask;
    
    % get coefficients
    for i = 1:pcNum
        brainVect = brain(:,:,pcaFileInd); brainVect = brainVect(:);
        coeffs(brainVect,i,pcaFileInd) = coeff(:,i);
    end
end

coeffs = reshape(coeffs,128,128,pcNum,2);

%% make everything bigger

wlData = load("L:\ProcessedData\deborah\deborahWL.mat");

scaleFactor = 2;

noVasculature = imresize(noVasculature,scaleFactor);
noVasculature = imgaussfilt(double(noVasculature),scaleFactor) >= 0.5;

newCoeffs = zeros(size(coeffs,1)*scaleFactor,size(coeffs,2)*scaleFactor,...
    pcNum,2);
for i = 1:pcNum
    for pcaFileInd = 1:2
        newCoeffs(:,:,i,pcaFileInd) = imresize(coeffs(:,:,i,pcaFileInd),2);
    end
end
coeffs = newCoeffs;

newBrain = zeros(128*scaleFactor,128*scaleFactor,2);
for pcaFileInd = 1:2
    newBrain(:,:,pcaFileInd) = imgaussfilt(double(imresize(brain(:,:,pcaFileInd),scaleFactor,'nearest')),scaleFactor) >= 0.5;
end
brain = newBrain;

newWL = nan(128*scaleFactor,128*scaleFactor,3);
for i = 1:3
    newWL(:,:,i) = imresize(wlData.xform_wl(:,:,i),scaleFactor);
end
wlData.xform_wl = newWL;
wlData.xform_isbrain = imgaussfilt(double(imresize(wlData.xform_isbrain,scaleFactor,'nearest')),scaleFactor) >= 0.5;

%%

excelFile = "D:\data\deborahData.xlsx";

for comparison = 1:2
    
    mask = reshape(brain(:,:,comparison),128*scaleFactor,128*scaleFactor) & noVasculature;
    for i = 1:2
        p(comparison,i+1).select();
        h1 = gca;
        set(gca,'Color',[1,1,1,0]);
        set(gca,'Visible','off');
        set(gca,'FontSize',12);
        set(gca,'Color','k')
        x = reshape(coeffs(:,:,i,comparison),128*scaleFactor,128*scaleFactor);
        
        if i == 1 && comparison == 2
            x = -x; % adam wants this to be flipped.
        end
        
        image(wlData.xform_wl,'AlphaData',wlData.xform_isbrain);
        hold on;
        cLim = max([abs(min(x(:))) abs(max(x(:)))]);
        imagesc(x,'AlphaData',mask,[-cLim cLim]); colormap('jet');
        axis(gca,'square'); yticks([]); xticks([]);
        set(gca,'YDir','reverse'); ylim([0.5 128*scaleFactor+.5]); xlim([0.5 128*scaleFactor+.5]);
        t = title(['PC' num2str(i) ': ' num2str(explained{comparison}(i),3) '%']);
        if i == 2
            ch = colorbar; ylabh = ylabel(ch,'PC coefficient (normalized)');
            set(ylabh,'Units','normalized');
            set(ylabh,'position',get(ylabh,'position') - [0.5 0 0]);
            set(ch,'XTick',[-cLim cLim]);
            set(ch,'XTickLabel',{'min','max'});
            set(ch,'Visible','on');
        end
        originalSize = get(gca, 'Position');
        set(h1, 'Position', originalSize);
        
        set(t,'Units','normalized');
        set(t,'position',get(t,'position') + [0 -0.05 0]);
        set(t,'Visible','on');
    end
end