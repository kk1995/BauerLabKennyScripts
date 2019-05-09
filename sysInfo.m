function info = sysInfo(systemType)
%session2procInfo Making OIS preprocess info from session type
%   Input:
%       sessiontype = char array showing type of systemtype ('fcOIS1','fcOIS2')
%   Output:
%       info = struct with info such as rgb indices
%           rgb = 1x3 vector specifying indices for red, green, and blue
%           numLEDs = number of leds
%           LEDFiles = string array containing name of text files showing
%           LED spectra
%           readFcn = function handle for reading from raw file (tiff, dat)
%           invalidFrameInd = any temporal frame index that should be
%           removed prior to processing (these are any indices that are not
%           dark frames yet still need to be removed)
%           gbox = gaussian filter box size for smoothing image
%           gsigma = gaussian filter sigma for smoothing image

if strcmp(systemType,'fcOIS1')
    info.rgb = [1 3 4];
    info.numLEDs = 4;
    info.invalidFrameInd = 1;
    info.gbox = 5;
    info.gsigma = 1.2;
elseif strcmp(systemType,'fcOIS2')
    info.rgb = [4 2 1];
    info.numLEDs = 4;
    info.LEDFiles = {'150917_TL_470nm_Pol.txt',...
        '150917_Mtex_530nm_Pol.txt',...
        '150917_TL_590nm_Pol.txt'...
        '150917_TL_628nm_Pol.txt'};
    info.invalidFrameInd = 1;
    info.gbox = 5;
    info.gsigma = 1.2;
elseif strcmp(systemType,'fcOIS2_Fluor')
    info.rgb = [4 2 NaN];
    info.numLEDs = 4;
    info.LEDFiles = {'150917_TL_470nm_Pol.txt',...
        '150917_Mtex_530nm_Pol.txt',...
        '150917_TL_590nm_Pol.txt'...
        '150917_TL_628nm_Pol.txt'};
    info.invalidFrameInd = 1;
    info.gbox = 5;
    info.gsigma = 1.2;
elseif strcmp(systemType,'fcOIS2_Fluor2')
    info.rgb = [4 2 NaN];
    info.numLEDs = 4;
    info.LEDFiles = {'150917_TL_470nm_Pol.txt',...
        '131029_Mightex_530nm_NoBPFilter.txt',...
        '140801_ThorLabs_590nm_NoPol.txt'...
        '140801_ThorLabs_625nm_NoPol.txt'};
    info.readFcn = @mouse.read.readTiff;
    info.invalidFrameInd = 1;
    info.gbox = 5;
    info.gsigma = 1.2;
elseif strcmp(systemType,'fcOIS3')
    info.rgb = [4 2 1];
    info.numLEDs = 4;
    info.LEDFiles = {'150917_TL_470nm_Pol.txt',...
        '150917_Mtex_530nm_Pol.txt',...
        '150917_TL_590nm_Pol.txt'...
        '150917_TL_628nm_Pol.txt'};
    info.invalidFrameInd = 1;
    info.gbox = 5;
    info.gsigma = 1.2;
elseif strcmp(systemType,'EastOIS1')
    info.rgb = [4 NaN 1];
    info.numLEDs = 4;
    info.LEDFiles = {'East3410OIS1_TL_470_Pol.txt', ...
        'East3410OIS1_TL_590_Pol.txt', ...
        'East3410OIS1_TL_617_Pol.txt', ...
        'East3410OIS1_TL_625_Pol.txt'};
    info.invalidFrameInd = 1;
    info.gbox = 5;
    info.gsigma = 1.2;
elseif strcmp(systemType,'EastOIS1+laser')
    info.rgb = [4 NaN 1];
    info.numLEDs = 5;
    info.LEDFiles = {'East3410OIS1_TL_470_Pol.txt', ...
        'East3410OIS1_TL_590_Pol.txt', ...
        'East3410OIS1_TL_617_Pol.txt', ...
        'East3410OIS1_TL_625_Pol.txt'};
    info.invalidFrameInd = 1;
    info.gbox = 5;
    info.gsigma = 1.2;
elseif strcmp(systemType,'EastOIS1_Fluor')
    info.rgb = [4 2 NaN];
    info.numLEDs = 4;
    info.LEDFiles = {'M470nm_SPF_pol.txt', ...
        'TL_530nm_515LPF_Pol.txt', ...
        'East3410OIS1_TL_617_Pol.txt', ...
        'East3410OIS1_TL_625_Pol.txt'};
    info.invalidFrameInd = 1;
    info.gbox = 5;
    info.gsigma = 1.2;
elseif strcmp(systemType,'EastOIS2_Fluor')
    info.rgb = [4 3 NaN];
    info.numLEDs = 4;
    info.LEDFiles = {'M470nm_SPF_pol.txt', ...
        'TL530nm_pol.txt', ...
        'East3410OIS1_TL_617_Pol.txt', ...
        'East3410OIS1_TL_625_Pol.txt'};
    info.invalidFrameInd = 1;
    info.gbox = 5;
    info.gsigma = 1.2;
end
end

