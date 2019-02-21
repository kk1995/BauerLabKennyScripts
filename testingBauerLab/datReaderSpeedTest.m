% moral of the story is that when reading multiple files, the back and
% forth time is important, and thus for dat files, it is recommended to
% move the data to local drive first before reading.

%%

dataDir = 'D:\data\190208-R1M2142KET-cam1-fc1';
dataFileDir = dir(dataDir); dataFileDir(1:2) = [];
dataFileDir(end-2:end) = [];
framenums = zeros(size(dataFileDir, 1), 1);
for i=1:size(dataFileDir, 1)
    tempframe=dataFileDir(i).name(1:10);
    tempframe=str2double(fliplr(tempframe))+1; % flip num order
    framenums(i) = tempframe;
end
[~, frameidx] = sort(framenums);
dataFileDir = dataFileDir(frameidx);

reader = mouse.read.DatVideoReader;
reader.SpeciesNum = 4;
reader = reader.getParameters(fullfile(dataDir,'acquisitionmetadata.ini'));
readers.ReaderObject = reader;

fileNames = [];
for i = 1:400; fileNames = [fileNames string(fullfile(dataFileDir(i).folder,dataFileDir(i).name))]; end

%%
data = readers.read(fileNames);

%%
plot(squeeze(data(250,250,1,:)));