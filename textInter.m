function textInter(g,img_value,textBBoxes,mserBBoxes)
textBBoxes=textBBoxes(textBBoxes(:,5)>0,:);
[interBBoxes,interBBoxeScore,interBBoxesIdx]=selectStrongestBbox(textBBoxes(:,1:4),textBBoxes(:,5)+textBBoxes(:,6),'RatioType','Min','OverlapThreshold',0.9);
for ii=1:size(interBBoxes,1)
    if ii>1
        g=aftertext;
    end
    if textBBoxes(interBBoxesIdx(ii),5)==1
        aftertext = insertShape(g, 'Rectangle', interBBoxes(ii,:),'LineWidth',3,'Color','red');
    elseif textBBoxes(interBBoxesIdx(ii),5)==2
        aftertext = insertShape(g, 'Rectangle', interBBoxes(ii,:),'LineWidth',3,'Color','yellow');
    else
        aftertext = insertShape(g, 'Rectangle', interBBoxes(ii,:),'LineWidth',3,'Color','green');
    end
    aftertext = insertShape(aftertext, 'Rectangle', mserBBoxes(mserBBoxes(:,5)==interBBoxesIdx(ii),1:4),'LineWidth',1,'Color','cyan');
    aftertext= insertText(aftertext,interBBoxes(ii,1:2),num2str(ii),'FontSize',12,'BoxOpacity',0,'TextColor','red');
end
save_name=[img_value '-inter-' num2str(ii) '.bmp'];
imwrite(aftertext,save_name);
end