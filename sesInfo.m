function info = sesInfo(sessiontype)
%session2procInfo Making OIS preprocess info from session type
%   Input:
%       sessiontype = string showing type of session ('6-nbdg','gcamp6f')
%   Output:
%       info = struct with info such as framerate, freqout, lowpass,
%       highpass. Should be inputted into procOIS.m function

% framerate is the sampling rate of your data acquisition method (Hz)
% freqout is the output frequency during processing. Usually downsampling
% is done to reduce the data size.
% lowpass is the frequency at which low pass filter should be implemented
% highpass is the frequency at which high pass filter should be implemented

if strcmp(sessiontype,'none')
    info.extCoeffFile = "prahl_extinct_coef.txt";
    info.framerate = 16.8;
    info.freqout = 16.8;
    info.hbSpecies = 1:4;
    info.probeSpecies = [];
    info.probeExcitationFile = "fad_excitation.txt";
    info.probeEmissionFile = "fad_emission.txt";
    info.detrendSpatially = false;
    info.detrendTemporally = true;
elseif strcmp(sessiontype,'fad')
    info.extCoeffFile = "prahl_extinct_coef.txt";
    info.framerate = 16.8;
    info.freqout = 16.8;
    info.hbSpecies = 2:4;
    info.probeSpecies = 1;
    info.probeExcitationFile = "fad_excitation.txt";
    info.probeEmissionFile = "fad_emission.txt";
    info.detrendSpatially = false;
    info.detrendTemporally = true;
elseif strcmp(sessiontype,'6-nbdg')
    info.extCoeffFile = "prahl_extinct_coef.txt";
    info.framerate = 16.8;
    info.freqout = 16.8;
    info.hbSpecies = 2:4;
    info.probeSpecies = 1;
    info.probeExcitationFile = "6-nbdg_excitation.txt";
    info.probeEmissionFile = "6-nbdg_emission.txt";
    info.detrendSpatially = false;
    info.detrendTemporally = false;
elseif strcmp(sessiontype,'gcamp6f')
    info.extCoeffFile = "prahl_extinct_coef.txt";
    info.framerate = 16.8;
    info.freqout = 16.8;
    info.hbSpecies = 2:4;
    info.probeSpecies = 1;
    info.probeExcitationFile = "gcamp6f_excitation.txt";
    info.probeEmissionFile = "gcamp6f_emission.txt";
    info.detrendSpatially = false;
    info.detrendTemporally = true;
elseif strcmp(sessiontype,'gcamp6f-rcamp')
    info.extCoeffFile = "prahl_extinct_coef.txt";
    info.framerate = 16.8;
    info.freqout = 16.8;
    info.hbSpecies = 3:4;
    info.probeSpecies = 1:2;
    info.probeExcitationFile = ["gcamp6f_excitation.txt" "rcamp_excitation.txt"];
    info.probeEmissionFile = ["gcamp6f_emission.txt" "rcamp_excitation.txt"];
    info.detrendSpatially = false;
    info.detrendTemporally = true;
else % if nothing else fits
    info.extCoeffFile = "prahl_extinct_coef.txt";
    info.framerate = 16.8;
    info.freqout = 16.8;
    info.hbSpecies = 2:4;
    info.probeSpecies = 1;
    info.probeExcitationFile = "fad_excitation.txt";
    info.probeEmissionFile = "fad_emission.txt";
    info.detrendSpatially = false;
    info.detrendTemporally = true;
end
