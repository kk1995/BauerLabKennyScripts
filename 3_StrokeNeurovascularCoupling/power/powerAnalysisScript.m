fRange = [0.009 5];
badRuns = cell(56,1);
badRuns{48} = 2;
%     0.5 5]; % 1st col is minimum frequency
% tZone = [7; 2]; % in seconds


fileInd = 48;

badRuns = badRuns(fileInd);

powerStroke(fileInd,fRange,16.81,badRuns);