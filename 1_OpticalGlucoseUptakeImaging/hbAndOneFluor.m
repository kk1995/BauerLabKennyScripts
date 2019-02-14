function [time,dataHb,dataFluor,dataFluorCorr,baseline] = hbAndOneFluor(fileNames,reader,...
    hbProc,fluorProc,hbSpecies,fluorSpecies)
% hbAndOneFluor reads and processes data into hb and fluor data. Intended
% for one trial (with potentially multiple files)

% get raw data
reader.TimeFrames = [];
[raw,time] = reader.read(fileNames);

% process hb
dataHb = hbProc.process(raw(:,:,hbSpecies,:));

% process fluor
if ~isempty(fluorSpecies)
    [dataFluorCorr, dataFluor] = fluorProc.process(raw(:,:,fluorSpecies,:),dataHb);
    baseline = fluorProc.baseline(raw(:,:,fluorSpecies,:));
else
    dataFluorCorr = [];
    dataFluor = [];
    baseline = [];
end
end
