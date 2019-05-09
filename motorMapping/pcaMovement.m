dataFile = 'D:\data\Kenny_Anesthetized.mat';
load(dataFile);

x = zeros(238,99*3);
for pix = 1:238
    x(pix,:) = disp{pix}(:);
end
[coeff,score,latent,~,explained,mu] = pca(x);

% plot 3d movement of principal components
figure;
for mInd = 1:3; m = coeff(:,mInd); m = reshape(m,99,3); plot3(m(:,1),m(:,2),m(:,3)); hold on; end;
xlabel('x'); ylabel('y'); zlabel('z');