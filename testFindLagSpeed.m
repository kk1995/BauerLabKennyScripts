% x = rand(5000,100); a = zeros(100);
% for i = 1:100
%     for j = 1:100
%         [l,a(i,j)] = mouse.conn.findLag(x(:,i),x(:,j),'corrThr',0,'quadFitUse',true,'validRange',30);
%     end
% end

%%
data = [];
for i = 1:200
    data(i,:) = sin(2*pi*(linspace(0,3,1024) - rand()));
%     data1(i,:) = awgn( data1(i,:) , 10 ); 
end
data = data+repmat(rand(1,size(data,2)),size(data,1),1);
tic;
[l,a] = mouse.conn.projLag(data,3,32);
toc
figure;
subplot(1,2,1);
imagesc(l);
subplot(1,2,2);
imagesc(a,[0.5 1])