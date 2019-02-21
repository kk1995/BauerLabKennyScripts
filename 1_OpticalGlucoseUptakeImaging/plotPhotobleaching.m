fileDir = '\\10.39.168.176\RawData_East3410\190214';
fileNames = ["1Hz-10ms-1V.tif","10Hz-10ms-1V.tif","10Hz-10ms-5V.tif",...
    "20Hz-10ms-1V.tif","20Hz-10ms-2V.tif","20Hz-10ms-5V.tif","40Hz-10ms-5V.tif"];
pulseRate = [1,10,10,20,20,20,40];
pulseWidth = [10,10,10,10,10,10,10];
pulseAmp = [1,1,5,1,2,5,5];
baselineFileName = "deionized-water.tif";
invalidInd = 1;
roi = false(128);
roi(mouse.math.matCoor2Ind(mouse.math.circleCoor([64 64],10),[128 128])) = true;
resampleFs = 1;
saveFile = 'D:\data\6nbdg-photobleaching.mat';
%% get baseline value

reader = mouse.read.TiffVideoReader();
reader.SpeciesNum = 1;
baseData = reader.read(fullfile(fileDir,baselineFileName));
baseData(:,:,:,invalidInd) = [];
baseline = squeeze(mean(baseData,4));
baseline = mean(baseline(roi)); % 1 number

%% for each photobleaching experiment

% if exist(saveFile)
%     load(saveFile);
% else
    data = [];
    for expInd = 1:numel(fileNames)
        disp(['exp # ' num2str(expInd)]);
        expData = reader.read(fullfile(fileDir,fileNames(expInd)));
        expData = double(expData);
        expData = squeeze(expData); % 128 x 128 x time
%         expData = expData - 100 - (baseline-100)*(pulseRate(expInd)/10)*(pulseWidth(expInd)/10)*(pulseAmp(expInd)/1);
        expData = expData - baseline*(pulseRate(expInd)/10)*(pulseWidth(expInd)/10)*(pulseAmp(expInd)/1);
        expDataT = (0:size(expData,3)-1)./pulseRate(expInd);
        resampleT = (0:max(expDataT))./resampleFs;
        expData(:,:,invalidInd) = [];
        expDataT(invalidInd) = [];
        resampleT(resampleT < expDataT(1)) = [];
        expData = bsxfun(@rdivide,expData,mean(expData(:,:,1:10),3)); % normalize by initial values
        
        goodRoi = roi & squeeze(expData(:,:,1)) < 16000;
        expData = reshape(expData,[],size(expData,3));
        expData = expData(goodRoi,:);
        expData = mean(expData,1);
        expData = mouse.freq.resampledata(expData,expDataT,resampleT);
        
        data = cat(1,data,expData);
    end
    
    % save
    save(saveFile,'data','resampleT','pulseRate','pulseWidth','pulseAmp','-v7.3');
% end
%% plot

goodFiles = 2:numel(fileNames);
data = data(goodFiles,:);
fileNames = fileNames(goodFiles);
lightIntensity = pulseWidth.*pulseRate.*pulseAmp;
lightIntensity = lightIntensity(goodFiles);

figure;
plot(resampleT,data')
legend(cellfun(@num2str,num2cell(lightIntensity),'UniformOutput',false));

%% get time constant

timeConst = nan(numel(fileNames),1); % unit of 1/s
amp = nan(numel(fileNames),1); % normalized
% timeMin = resampleT./60;
goodInd = 200:size(data,2);
g = fittype('a*exp(b*x)+c','independent','x','dependent','y');
for expInd = 1:numel(fileNames)
    f = fit(resampleT(goodInd)',data(expInd,goodInd)','exp2');
    coeffvals = coeffvalues(f);
    expCoeffCandidates = [coeffvals(2) coeffvals(4)];
    expCoeffInd = find(max(abs(expCoeffCandidates)) == abs(expCoeffCandidates));
    expCoeffCandidates = expCoeffCandidates(expCoeffInd);
    timeConst(expInd) = expCoeffCandidates;
    amp(expInd) = coeffvals(expCoeffInd*2 - 1);
end


g = fittype('a*x','independent','x','dependent','y');
f2 = fit(lightIntensity',timeConst,g);
figure;
plot(f2,lightIntensity,timeConst);
coeffvals = coeffvalues(f2);
timeConstSlope = coeffvals(1);
disp(['time constant slope is ' num2str(timeConstSlope)]);