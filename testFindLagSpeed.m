% x = rand(5000,100); a = zeros(100);
% for i = 1:100
%     for j = 1:100
%         [l,a(i,j)] = mouse.conn.findLag(x(:,i),x(:,j),'corrThr',0,'quadFitUse',true,'validRange',30);
%     end
% end

%%
x = rand(5000,200);
tic;
[l,a] = mouse.conn.findLag(x,'corrThr',0,'quadFitUse',false,'validRange',30);
toc
imagesc(a)