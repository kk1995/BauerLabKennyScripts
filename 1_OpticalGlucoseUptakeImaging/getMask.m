function [isbrain,xform_isbrain,affineMarkers,WL] = getMask(fileNames,reader,rgbOrder)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
import mouse.*

badDataInd = unique([reader.DarkFrameInd reader.InvalidInd]);
realDataStart = max(badDataInd) + 1;
reader.TimeFrames = 1:realDataStart;
[raw,~] = reader.read(fileNames);
raw = raw(:,:,:,size(raw,4));
raw = single(raw);
WL = process.getWL(raw,rgbOrder);
affineMarkers = process.getLandmarks(WL);
isbrain = process.getMask(WL);
xform_isbrain = process.affineTransform(isbrain,affineMarkers);
end