function textRefine(g,img_value,textBBoxes,mserBBoxes)

textBBoxesNum=size(textBBoxes,1);
for ii=1:textBBoxesNum
    if textBBoxes(ii,5)==0
        continue
    end
    gBbox=g(textBBoxes(ii,2):textBBoxes(ii,2)+textBBoxes(ii,4)-1,:,:);
    mserBBox=textMser(gBbox);
    boxes=runDetector_refine_11_29(gBbox,img_value,mserBBox,ii);
    
end
end