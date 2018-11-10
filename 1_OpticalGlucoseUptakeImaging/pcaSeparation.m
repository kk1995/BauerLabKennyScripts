% this script will run data through PCA to see the orthogonal components
% hidden.
% usually run after resampleSave.m

%% parameters

date = '180813';
mouse = 'W3M1';

dataFile = ['D:\data\' date '\' date '-Probe' mouse '-ResampledRaw-Post.mat'];
maskFile = ['D:\data\' date '\' date '-Probe' mouse '-LandmarksandMask.mat'];
cutOffFreq = 0.009; % cut off freq for Bauer et al. 2018
timeBounds = [0.5:59.5;1.5:60.5];
baselineInd = 1:5;
radius = 4;

%% load data

load(dataFile);
load(maskFile);
fs = 1; % framerate


%% preprocess

postRawPassed = highpass(postRaw,cutOffFreq,fs) + repmat(mean(postRaw,4),[1 1 1 size(postRaw,4)]);

% log mean (makes this percentage change in light intensity)
postRawPassedLog = logmean(postRawPassed);
% postRawPassedLog = nan(size(postRawPassed));
% for y = 1:128
%     for x = 1:128
%         if isbrain(y+(x-1)*128)
%             postRawPassedLog(y,x,:,:) = logmean(postRawPassed(y,x,:,:));
%         end
%     end
% end

% postRawPassed = gsr(postRawPassed,isbrain);

postRawPassedLog = postRawPassedLog(:,:,2:4,:);

% affine transform
postRawPassedLog = transformHb(postRawPassedLog,I);
xform_isbrain = transformHb(logical(isbrain),I);

% assign for subsequent analysis
data = postRawPassedLog;
time = postTime;
mask = xform_isbrain;

%% pca

% make the input 2D matrix by applying brain mask and combining pixel and
% time dimensions
originalSize = size(data);
pcaInput = permute(data,[1 2 4 3]);
pcaInput = reshape(pcaInput,[size(pcaInput,1)*size(pcaInput,2) size(pcaInput,3), size(pcaInput,4)]);
pcaInput = pcaInput(logical(mask(:)),:,:);
pcaInput = reshape(pcaInput,[size(pcaInput,1)*size(pcaInput,2) size(pcaInput,3)]);
[coeff, score, latent, ~, explained, mu] = pca(pcaInput);

% reverse the reshaping
scoreReshaped = reshape(score,[sum(mask(:)) originalSize(4) size(pcaInput,2)]);
scoreReshaped = permute(scoreReshaped,[1 3 2]);
scoreReshapedTemp = nan(originalSize(1)*originalSize(2),originalSize(3),originalSize(4));
scoreReshapedTemp(logical(mask(:)),:,:) = scoreReshaped;
scoreReshaped = reshape(scoreReshapedTemp,originalSize);

%% plot

toi = 9:11; % the time that we care about (seconds)

speciesNum =size(scoreReshaped,3);
imageData = nan(128,128,speciesNum);
for species = 1:speciesNum
    disp(['Species # ' num2str(species)]);
    for y = 1:128
        if mod(y,16) == 1
            disp(['  Row # ' num2str(y)]);
        end
        for x = 1:128
            if mask(y+(x-1)*128)
                output = getAvgTimeCourse(scoreReshaped(y,x,species,:),time,timeBounds,baselineInd);
                imageData(y,x,species) = mean(output(toi));
            end
        end
    end
end



figure('Position',[100 100 600 500]);
for species = 1:speciesNum
    subplot(2,2,species);
    alpha = double(mask);
    imagesc(squeeze(imageData(:,:,species)),'AlphaData',alpha,[-0.02 0.02]);
    colormap('jet');
    set(gca,'Visible','off');
    if species == speciesNum
        sPos = get(gca,'position');
        colorbar;
        set(gca,'Position',sPos);
    end
end


% roi
% centerCoor = [108 77];
centerCoor = [99 82];
coor = circleCoor(centerCoor,radius);


plotScores = reshape(scoreReshaped,[size(scoreReshaped,1)*size(scoreReshaped,2) size(scoreReshaped,3) size(scoreReshaped,4)]);
plotScores = plotScores(coor(2,:)+(coor(1,:)-1)*size(scoreReshaped,2),:,:);

figure;
for species = 1:speciesNum
    subplot(2,2,species);
    output = getAvgTimeCourse(plotScores(:,species,:),time,timeBounds,baselineInd);
    plot(output);
end