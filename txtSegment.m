function response=txtSegment(g,IntraTextBboxs,textBBoxes,bbox,txtBBoxes,img_value)

txtNum=size(txtBBoxes,1);
response={};
response.bbox=[];
response.spaces.locations=[];
response.spaces.scores=[];
flag=1;
for ii=1:txtNum
    bBox=txtBBoxes(ii,:);
    img=g(bBox(2):bBox(2)+bBox(4)-1,bBox(1):bBox(1)+bBox(3)-1,:);
    save_gBname=[img_value '-' num2str(ii) ];
    boxes=txtsplit(img,save_gBname);
    if isempty(boxes.bbox)
        continue
    end
    boxes.bbox(:,2)=boxes.bbox(:,2)+bBox(1,2);
    response.bbox=[response.bbox ; boxes.bbox];
    if flag==1
        n1=0;
    else
        n1=length(response.spaces);
    end
    n2=length(boxes.spaces);
    for j=1:n2
    response.spaces(n1+j).locations=boxes.spaces(j).locations;
    response.spaces(n1+j).scores=boxes.spaces(j).scores;
    flag=0;
    end
end

end