function txtSegment(g,IntraTextBboxs,textBBoxes,bbox,txtBBoxes,img_value)

txtNum=size(txtBBoxes,1);

for ii=1:txtNum
    bBox=txtBBoxes(ii,:);
    img=g(bBox(2):bBox(2)+bBox(4)-1,bBox(1):bBox(1)+bBox(3)-1,:);
    save_gBname=[img_value '-' num2str(ii) ];
    txtsplit(img,save_gBname)
    
end

end