% cd('1_OpticalGlucoseUptakeImaging');
% cd('preprocess');
% 
% disp('Saving Hb and Fluor now');
% saveHbAndFluor;
% 
% clear all;
% 
% 
% cd('..');
% cd('..');

pauseDur = 60*60*1.2;

disp('Paused for 1 hours');

pause(pauseDur);

disp('Finished pausing');

cd('3_StrokeNeurovascularCoupling');

% regionalFCMultipleMice(15:56,[0.009 0.5],[66,33],'R_canonical');
regionalFCMultipleMice(50:56,[0.009 0.5],[66,96],'L_canonical');
regionalFCMultipleMice(1:56,[0.5 5],[66,33],'R_canonical');
regionalFCMultipleMice(1:56,[0.5 5],[66,96],'L_canonical');


