function t = parExample(iter)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

if nargin == 0, iter = 16; end

disp('Start sim');

t0 = tic;
parfor idx = 1:iter
    A(idx) = idx;
    pause(2);
end
t = toc(t0);

disp('Sim completed.');
end

