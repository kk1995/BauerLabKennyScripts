function [preFileName,postFileName] = getFileNames_Probe(rawLoc,recDate,mouse)
%getFileNames_Probe Get file names for probe data
%   Detailed explanation goes here
D = dir(fullfile(rawLoc,recDate)); D(1:2) = [];
preFileName = {};
preFileName{1} = fullfile(rawLoc,recDate,[recDate,'-', mouse, 'Pre.tif']);
postFileName = {};
for file = 1:numel(D)
    if ~isempty(strfind(D(file).name,[recDate,'-', mouse]))
        if isempty(strfind(D(file).name,'Pre'))
            postFileName = [postFileName; {fullfile(rawLoc,recDate,D(file).name)}];
        end
    end
end
end

