% here, we are going to create 128^4 x 14 matrix. By doing this, variance
% between groups will be better understood.

saveFile = "L:\ProcessedData\ov-yvPCs_v2.mat";
saveFile2 = "L:\ProcessedData\od-ovPCs_v2.mat";

[lowerInd, upperInd] = mouse.conn.getTriangleInd(128^2);
input = [];
for i = 1:7
    disp(num2str(i));
    
    load(strcat("L:\ProcessedData\deborah\FC-YV",num2str(i),".mat"));
    fcMap = single(fcMap(lowerInd));
    input = cat(1,input,fcMap);
    
    clear fcMap;
    
    load(strcat("L:\ProcessedData\deborah\FC-OV",num2str(i),".mat"));
    fcMap = single(fcMap(lowerInd));
    input = cat(1,input,fcMap);
    
    clear fcMap;
end

badInd = sum(isnan(input),1) > 0;
goodMatrixInd = lowerInd(~badInd);
goodMatrixIndUpper = upperInd(~badInd);

input = input(:,~badInd);

[coeff, score, latent, tsquared, explained] = pca(input);

save(saveFile,'coeff','score','latent','tsquared','explained','goodMatrixInd','goodMatrixIndUpper','-v7.3');

[lowerInd, upperInd] = mouse.conn.getTriangleInd(128^2);
input = [];
for i = 1:7
    disp(num2str(i));
    
    load(strcat("L:\ProcessedData\deborah\FC-OV",num2str(i),".mat"));
    fcMap = single(fcMap(lowerInd));
    input = cat(1,input,fcMap);
    
    clear fcMap;
    
    load(strcat("L:\ProcessedData\deborah\FC-OD",num2str(i),".mat"));
    fcMap = single(fcMap(lowerInd));
    input = cat(1,input,fcMap);
    
    clear fcMap;
end

badInd = sum(isnan(input),1) > 0;
goodMatrixInd = lowerInd(~badInd);
goodMatrixIndUpper = upperInd(~badInd);

input = input(:,~badInd);

[coeff, score, latent, tsquared, explained] = pca(input);

save(saveFile2,'coeff','score','latent','tsquared','explained','goodMatrixInd','goodMatrixIndUpper','-v7.3');