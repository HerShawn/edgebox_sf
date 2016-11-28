function croppedSample(g,textBBoxes,img_value)
textBBoxesNum=size(textBBoxes,1);
for ii=1:textBBoxesNum
    if textBBoxes(ii,5)==0
        continue
    end
    gBbox=g(textBBoxes(ii,2):textBBoxes(ii,2)+textBBoxes(ii,4)-1,textBBoxes(ii,1):textBBoxes(ii,1)+textBBoxes(ii,3)-1,:);
    score=num2str(textBBoxes(ii,5)+textBBoxes(ii,6));
    save_name=[img_value '-' num2str(ii) '-' score '.bmp'];
    imwrite(gBbox,save_name);
end
end