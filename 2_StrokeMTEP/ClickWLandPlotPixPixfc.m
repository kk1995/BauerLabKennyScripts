fcvals=diffMTEP_PT_minus_Veh_PT; % only those in the mask


[SeedsUsed]=CalcRasterSeedsUsed(symisbrainall);
idx=find(symisbrainall==1);
length=size(SeedsUsed,1);
map=[(1:2:length-1) (2:2:length)];
NewSeedsUsed(:,1)=SeedsUsed(map, 1);
NewSeedsUsed(:,2)=SeedsUsed(map, 2);

for n=1:size(NewSeedsUsed,1)
    idx_inv(n)=sub2ind([128,128], NewSeedsUsed(n,2), NewSeedsUsed(n,1)); % get the indices of the Seed coordinates used to organize the Pix-Pix matrix
    idx_inv=idx_inv';
end

fcvalsNew = nan(128*128);
[x,y] = meshgrid(idx_inv,idx_inv);
ind = (y(:)-1)*128*128+x(:);
fcvalsNew(ind) = fcvals;


% pixels=find(symisbrainall==1);
% length=size(fcvals,1);
% map=[(1:2:length-1) (2:2:length)]; % All the right Seeds first, then the left.
%fcvals(map,map)=fcvals;

fwl=figure;
subplot(1,3,1)
image(zeros(128,128,3));
axis image off;
hold on; 
rectangle('Position',[64.5-27,64.5-30,15,38],...
          'Curvature',[0.8,0.4],...
         'LineWidth',2,'LineStyle','--', 'EdgeColor', [1 1 1])

while 1
    [x, y]=ginput(1);
    x=round(x);
    y=round(y);
    
    idx=sub2ind([128,128],y,x);
%     mapnum=find(pixels==idx);
%     fcmap=zeros(128);
    
    fcmap=fcvalsNew(idx,:);
    fcmap = reshape(fcmap,128,128);
    subplot(1,3,2)
    ax = gca;
    imagesc(fcmap, [-0.5 0.5]);
    
    s4Pos = get(ax,'position');
    colorbar;
    set(ax,'Position',s4Pos);
    colormap('jet');
    axis image off
    
%     subplot(1,3,3)
%     imagesc(tanh(tempim2),[-1.5 1.5]);
%     axis image off;    
    
end


figure;
%% fcMap
fclims=2;
tempim=fcmap;

mask=zeros(128);
idx=tempim>0.6;
mask(idx)=1;

subplot(1,3,2)
Im2=overlaymouse(tanh(tempim), xform_WL, mask,'jet', -fclims, fclims);
imagesc(Im2(12:124, 9:119,:), [-fclims fclims]);
axis image off;
hold on;
rectangle('Position',[64.5-27-10,64.5-30-8,15,38],...
          'Curvature',[0.8,0.4],...
         'LineWidth',2,'LineStyle','--', 'EdgeColor', [1 1 1]);
     
subplot(1,3,3)

Im2=overlaymouse(tanh(tempim2), xform_WL, mask,'jet', -fclims, fclims);
Im2=reshape(Im2,128*128,3);
Im2(idxn,:)=1;
Im2=reshape(Im2,128,128,3);
imagesc(Im2(12:124, 9:119,:), [-fclims fclims]);
axis image off;
hold on;
rectangle('Position',[64.5-27-10,64.5-30-8,15,38],...
          'Curvature',[0.8,0.4],...
         'LineWidth',2,'LineStyle','--', 'EdgeColor', [1 1 1])
     
     
     
% tempim2=squeeze(MeanOptoECMaps(:,:,3,9));
% 
% mask=zeros(128);
% idx=tempim2>0.4;
% mask(idx)=1;
% mask(:,65:end)=0;
% 
% subplot(1,3,3)
% Im2=overlaymouse(tempim2, xform_WL, mask,'jet', -fclims, fclims);
% imagesc(Im2(12:124, 9:119,:), [-fclims fclims]);
% axis image off;
% hold on;
% rectangle('Position',[64.5-27-10,64.5-30-8,15,38],...
%           'Curvature',[0.8,0.4],...
%          'LineWidth',2,'LineStyle','--', 'EdgeColor', [1 1 1])
%      

