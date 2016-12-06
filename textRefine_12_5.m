function textRefine_12_5(g,img_value,textBBoxes)
[textBBoxes,~,~]=selectStrongestBbox(textBBoxes(:,1:4),textBBoxes(:,5),'RatioType','Min','OverlapThreshold',0.9);
txtOverlapRatio=txtOverlap(textBBoxes,textBBoxes);
n = size(txtOverlapRatio,1);
txtOverlapRatio(1:n+1:n^2) = 0;
gh = graph(txtOverlapRatio);
componentIndices = conncomp(gh);
ymin=textBBoxes(:,2);
ymax = ymin + textBBoxes(:,4) - 1;
ymin = accumarray(componentIndices', ymin, [], @min);
ymax = accumarray(componentIndices', ymax, [], @max);
txtBBoxes=[ones(length(ymin),1)*3  ymin   ones(length(ymin),1)*size(g,2)-4  ymax-ymin+1 ];
color=cell(1,size(txtBBoxes,1));
for ii=1:size(txtBBoxes,1)
    idx=mod(ii,7);
    switch idx
        case 1
            str='blue';
        case 2
            str='green';
        case 3
            str='red';
        case 4
            str='cyan';
        case 5
            str='magenta';
        case 6
            str='yellow';
        case 0
            str='black';
    end
    color(1,ii)={str};
end
clear str
aftertxtBBoxes = insertShape(g, 'Rectangle', txtBBoxes,'LineWidth',2, 'color', color);
aftertxtBBoxes = insertShape(aftertxtBBoxes, 'FilledRectangle', textBBoxes(:,1:4), 'color', 'white','Opacity',0.5);
save_name=[img_value '-txt.bmp'];
imwrite(aftertxtBBoxes,save_name);
end