function [mserBBoxes,textBBoxes]=textInter_2(g,img_value,textBBoxes,mserBBoxes)
[~,~,interBBoxesIdx]=selectStrongestBbox(textBBoxes(:,1:4),textBBoxes(:,5)+textBBoxes(:,6),'RatioType','Min','OverlapThreshold',0.9);
textBBoxesNum=size(textBBoxes,1);
removeIdx=(setdiff(1:textBBoxesNum,(interBBoxesIdx)'))';
textBBoxes(removeIdx,5)=0;
for ii=1:length(removeIdx)
    mserBBoxes(mserBBoxes(:,5)==removeIdx(ii),:)=[];
end
%ÏÔÊ¾Çø
% greenCnt=0;
% yellowCnt=0;
% redCnt=0;
% for ii=1:textBBoxesNum
%     if ii>1
%         g=aftertext;
%     end
%     if textBBoxes((ii),5)==1
%         aftertext = insertShape(g, 'Rectangle', textBBoxes(ii,1:4),'LineWidth',3,'Color','red');
%         redCnt=redCnt+1;
%     elseif textBBoxes(ii,5)==2
%         aftertext = insertShape(g, 'Rectangle',  textBBoxes(ii,1:4),'LineWidth',3,'Color','yellow');
%         yellowCnt=yellowCnt+1;
%     elseif textBBoxes(ii,5)==0
%         if ii==1
%             aftertext=g;
%         end
%         continue
%     else
%         aftertext = insertShape(g, 'Rectangle',  textBBoxes(ii,1:4),'LineWidth',3,'Color','green');
%         greenCnt=greenCnt+1;
%     end
%     aftertext = insertShape(aftertext, 'Rectangle', mserBBoxes(:,1:4),'LineWidth',1,'Color','cyan');
%     aftertext= insertText(aftertext,textBBoxes(ii,1:2),num2str(ii),'FontSize',12,'BoxOpacity',0,'TextColor','red');
% end
% save_name=[img_value '-inter- (' num2str(greenCnt) '-' num2str(yellowCnt) '-' num2str(redCnt) ').bmp'];
% imwrite(aftertext,save_name);
%
end