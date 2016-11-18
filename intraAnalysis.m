function intraAnalysis(img_value,componentIndices,fusionBBox,g)
% ����refine�ñ�bbox��ţ�bbox���ĵ�ĺᡢ�����꣬bbox�ĸ߶�
refine_matrix=zeros(size(fusionBBox,1),3);
refine_matrix(:,1)=fusionBBox(:,1)+fusionBBox(:,3)/2;
refine_matrix(:,2)=fusionBBox(:,2)+fusionBBox(:,4)/2;
refine_matrix(:,3)=fusionBBox(:,4);
% intra:�����쳣ֵ���ų�
figure(1);
axis([0 size(g,2) 0 size(g,1)]);
set(gca, 'YDir','reverse');
hold on
intra_matrix=[];
for i=1:max(componentIndices)
    txtGroup=find(componentIndices==i);
    %11-15����txtGroup��������������
    [~,I]=sort(refine_matrix(txtGroup,1));
    txtGroup=txtGroup(I);
    %
    %11-15-2: ��intra�﷢���쳣ֵ : �Ƕȡ�ƫ�ơ�H֮�ȡ�
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
            %11-15-2: ��intra�﷢���쳣ֵ : �Ƕȡ�ƫ�ơ�H֮��
            %��1���ڼ���
            intra_set(ii,1)=i;
            %��2������������
            intra_set(ii,2)=LX(2)-LX(1);
            %intra_set(ii,2)=sqrt((LX(2)-LX(1)).^2+(LY(2)-LY(1)).^2);
            %��3���Ƕ�
            intra_set(ii,3)=(LY(2)-LY(1))/(LX(2)-LX(1));
            %��4��ƫ����
            yTop=max(LY(1)-refine_matrix(txtGroup(1,ii-1),3)/2,LY(2)-refine_matrix(j,3)/2);
            yBottom=min(LY(1)+refine_matrix(txtGroup(1,ii-1),3)/2,LY(2)+refine_matrix(j,3)/2);
            yH=max(refine_matrix(txtGroup(1,ii-1),3),refine_matrix(j,3));
            intra_set(ii,4)=abs(yBottom-yTop)/yH;
            %��5��H֮��
            intra_set(ii,5)=min(refine_matrix(txtGroup(1,ii-1),3),refine_matrix(j,3))/yH;
            %
            plot(LX,LY,'-o',...
                'LineWidth',0.5,...
                'MarkerSize',2,...
                'MarkerEdgeColor','b');
        end
        HY=[]; HX=[]; LY=[]; LX=[];
    end
    %�ظ�ֵ����ɸ��ţ�ȥ���ظ�ֵ
    if (isempty(find(intra_set(:,2)>10)))
        removeIdx=(1:size(intra_set,1))';
    else
        removeIdx=find(intra_set(:,2)<median(intra_set(intra_set(:,2)>10,2))/2);
    end
    intra_set(removeIdx,1)=i;
    intra_set(removeIdx,2)=0;intra_set(removeIdx,3)=0;intra_set(removeIdx,4)=0;intra_set(removeIdx,5)=0;
    intraH=figure(2);
    set(intraH,'name',['��' num2str(i) '��'],'Numbertitle','off');
    subplot(4,1,1);
    barX=1:size(txtGroup,2);
    bar(barX,intra_set(:,2)');
    title('����');
    subplot(4,1,2);
    bar(barX,intra_set(:,3)');
    title('�Ƕ�');
    subplot(4,1,3);
    bar(barX,intra_set(:,4)');
    title('ƫ����');
    subplot(4,1,4);
    bar(barX,intra_set(:,5)');
    title('H֮��');
    intra_matrix=[ intra_matrix ; intra_set];
    close figure 2
end
hold off
saveas(gcf,[img_value  '-intra.bmp']);
close all
end

