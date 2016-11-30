function g=visualizeBoxes_11_29(img, response,thresh)
if ~exist('thresh')
    thresh = 0.5;
end
bboxes = response.bbox;
spaces = response.spaces;
chars  = response.chars;
if isempty(bboxes)
    g=img;
    return
end
for i=1:size(bboxes, 1)
    if bboxes(i,5) > thresh && bboxes(i,3) > 0 && bboxes(i,4) > 0
        if i>1
            img=g;
        end
        g = insertShape(img, 'Rectangle', bboxes(i, 1:4),'LineWidth',2,'Color','g');
        spaceLocations = sort(spaces(i).locations);
        for j=1:length(spaceLocations)
            g = insertShape(g, 'Rectangle', [bboxes(i,1) + spaceLocations(j), bboxes(i,2), 2, bboxes(i,4)],'LineWidth',1,'Color','blue');
        end
        charsLocations = sort(chars(i).locations);
        for j=1:length(charsLocations)
            g = insertShape(g, 'Rectangle', [bboxes(i,1) + charsLocations(j), bboxes(i,2), 1, bboxes(i,4)],'LineWidth',1,'Color','black');
        end
    else
        g=img;
    end
end



