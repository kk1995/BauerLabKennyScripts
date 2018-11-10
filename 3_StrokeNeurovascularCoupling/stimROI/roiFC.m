function roiFC(data,roi,mask,varargin)

if isempty(varargin)
    varargin{1} = false;
end
doGsr = varargin{1};

% determine roi
fcDataHbO = [];
fcDataHbR = [];
fcDataHbT = [];
fcDataGCaMP = [];
disp(['  Run # ' num2str(run)]);
% load data

% gsr
if doGsr
    data = gsr(data,maskRun);
end


% fc analysis
fcDataRun = regionalFC(dataHbO,fRange,sR,maskRun,roi);
fcDataRun = mean(fcDataRun,1);
fcDataRunMouse = nan(128,128);
fcDataRunMouse(maskRun(:)) = fcDataRun;
fcDataHbO = cat(3,fcDataHbO,fcDataRunMouse);

fcDataRun = regionalFC(dataHbR,fRange,sR,maskRun,roi);
fcDataRun = mean(fcDataRun,1);
fcDataRunMouse = nan(128,128);
fcDataRunMouse(maskRun(:)) = fcDataRun;
fcDataHbR = cat(3,fcDataHbR,fcDataRunMouse);

fcDataRun = regionalFC(dataHbT,fRange,sR,maskRun,roi);
fcDataRun = mean(fcDataRun,1);
fcDataRunMouse = nan(128,128);
fcDataRunMouse(maskRun(:)) = fcDataRun;
fcDataHbT = cat(3,fcDataHbT,fcDataRunMouse);

fcDataRun = regionalFC(dataGCaMP,fRange,sR,maskRun,roi);
fcDataRun = mean(fcDataRun,1);
fcDataRunMouse = nan(128,128);
fcDataRunMouse(maskRun(:)) = fcDataRun;
fcDataGCaMP = cat(3,fcDataGCaMP,fcDataRunMouse);
