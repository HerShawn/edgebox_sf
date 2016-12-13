function textMserRefine(g,IntraTextBbox,textBBoxes,bbox)

for ii=1:size(textBBoxes,1)
    
    while(1)
        %1.扩展text,得到tmp
        tmp_x=max(1,textBBoxes(ii,1)-textBBoxes(ii,4));
        tmp_x2=min(textBBoxes(ii,1)+textBBoxes(ii,3)+textBBoxes(ii,4),size(g,2));
        tmp_w=tmp_x2-tmp_x;
        tmp=[tmp_x textBBoxes(ii,2) tmp_w textBBoxes(ii,4)];
        %2.求与tmp有overlap的mser bbox
        tmpBboxRatio=bboxOverlapRatio(tmp,bbox(:,1:4));
        isempty(find(tmpBboxRatio))
        break
    end
    
end

end