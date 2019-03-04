function data = getDatDataFromOneFolder(folderDir,ind,flipDim)
%getDatDataFromOneFolder Summary of this function goes here
%   Detailed explanation goes here

iniFile = fullfile(folderDir,"acquisitionmetadata.ini");

tempdir=dir(folderDir);
tempdir2=tempdir(3:end-3, 1);% exclude . .. and ini modifieddata sifx
framenums=zeros(size(tempdir2, 1), 1);
for i=1:size(tempdir2, 1)
    tempframe=tempdir2(i).name(1:10);
    tempframe=str2double(fliplr(tempframe))+1; % flip num order
    framenums(i)=tempframe;
end
[~, frameidx]=sort(framenums);
tempdir2=tempdir2(frameidx);

tempdir2 = tempdir2(ind);

fileList = [];
for i = 1:numel(tempdir2)
    fileList = [fileList string(fullfile(tempdir2(i).folder,tempdir2(i).name))];
end

reader = mouse.read.DatVideoReader();
reader.FlipDim = flipDim;
reader = reader.getParameters(iniFile);

readers = mouse.read.VideosReader();
readers.ReaderObject = reader;

data = readers.read(fileList);

end

