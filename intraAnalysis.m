function intraAnalysis(img_value,componentIndices,fusionBBox,g)
% 构造refine用表：bbox序号，bbox中心点的横、纵坐标，bbox的高度
refine_matrix=zeros(size(fusionBBox,1),3);
refine_matrix(:,1)=fusionBBox(:,1)+fusionBBox(:,3)/2;
refine_matrix(:,2)=fusionBBox(:,2)+fusionBBox(:,4)/2;
refine_matrix(:,3)=fusionBBox(:,4);
% intra:组内异常值的排除
figure(1);
axis([0 size(g,2) 0 size(g,1)]);
set(gca, 'YDir','reverse');
hold on
intra_matrix=[];
for i=1:max(componentIndices)
    txtGroup=find(componentIndices==i);
    %11-15：对txtGroup按横坐标重排序
    [~,I]=sort(refine_matrix(txtGroup,1));
    txtGroup=txtGroup(I);
    %
    %11-15-2: 在intra里发现异常值 : 角度、偏移、H之比、
    intra_set=zeros(size(txtGroup,2),5);
    intra_set(1,1)=i;
    %
    for ii=1:size(txtGroup,2)
        j=txtGroup(1,ii);
        HY=refine_matrix(j,2)-refine_matrix(j,3)/2:refine_matrix(j,2)+refine_matrix(j,3)/2;
        HX=refine_matrix(j,1)*ones(1,length( HY));
        plot(HX,HY);
        if ii>1
            LY=[refine_matrix(txtGroup(1,ii-1),2) refine_matrix(j,2)];
            LX=[refine_matrix(txtGroup(1,ii-1),1) refine_matrix(j,1)];
            %11-15-2: 在intra里发现异常值 : 角度、偏移、H之比
            %（1）第几组
            intra_set(ii,1)=i;
            %（2）横坐标间距离
            intra_set(ii,2)=LX(2)-LX(1);
            %intra_set(ii,2)=sqrt((LX(2)-LX(1)).^2+(LY(2)-LY(1)).^2);
            %（3）角度
            intra_set(ii,3)=(LY(2)-LY(1))/(LX(2)-LX(1));
            %（4）偏移量
            yTop=max(LY(1)-refine_matrix(txtGroup(1,ii-1),3)/2,LY(2)-refine_matrix(j,3)/2);
            yBottom=min(LY(1)+refine_matrix(txtGroup(1,ii-1),3)/2,LY(2)+refine_matrix(j,3)/2);
            yH=max(refine_matrix(txtGroup(1,ii-1),3),refine_matrix(j,3));
            intra_set(ii,4)=abs(yBottom-yTop)/yH;
            %（5）H之比
            intra_set(ii,5)=min(refine_matrix(txtGroup(1,ii-1),3),refine_matrix(j,3))/yH;
            %
            plot(LX,LY,'-o',...
                'LineWidth',0.5,...
                'MarkerSize',2,...
                'MarkerEdgeColor','b');
        end
        HY=[]; HX=[]; LY=[]; LX=[];
    end
    %重复值会造成干扰，去掉重复值
    if (isempty(find(intra_set(:,2)>10)))
        removeIdx=(1:size(intra_set,1))';
    else
        removeIdx=find(intra_set(:,2)<median(intra_set(intra_set(:,2)>10,2))/2);
    end
    intra_set(removeIdx,1)=i;
    intra_set(removeIdx,2)=0;intra_set(removeIdx,3)=0;intra_set(removeIdx,4)=0;intra_set(removeIdx,5)=0;
    intraH=figure(2);
    set(intraH,'name',['第' num2str(i) '组'],'Numbertitle','off');
    subplot(4,1,1);
    barX=1:size(txtGroup,2);
    bar(barX,intra_set(:,2)');
    title('距离');
    subplot(4,1,2);
    bar(barX,intra_set(:,3)');
    title('角度');
    subplot(4,1,3);
    bar(barX,intra_set(:,4)');
    title('偏移量');
    subplot(4,1,4);
    bar(barX,intra_set(:,5)');
    title('H之比');
    intra_matrix=[ intra_matrix ; intra_set];
    close figure 2
end
hold off
saveas(gcf,[img_value  '-intra.bmp']);
close all
end

