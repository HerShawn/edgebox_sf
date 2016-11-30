%% 11-30
function textSegment(img,save_gBname,boxes,mserBBoxe,textIdx)
img=visualizeBoxes_11_29(img, boxes);
g = insertShape(img, 'Rectangle', mserBBoxe(:, 1:4),'LineWidth',1,'Color','r');
responses=boxes.responses;
figure;
subplot(2,1,1);imshow(g);
subplot(2,1,2);
plot(responses.response);
zero_y=zeros(1,size(responses.response,2));
hold on
plot(1:size(responses.response,2),zero_y,'r');
hold off
saveas(gcf,[save_gBname '-segment-' num2str(textIdx) '.bmp']);
close all
end

