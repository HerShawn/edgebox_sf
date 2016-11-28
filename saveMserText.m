function saveMserText(mserBBoxes,textBBoxes,img_value)
mserBBoxesName=[ img_value '-mser.mat' ];
save(mserBBoxesName,'mserBBoxes');
textBBoxesName=[ img_value '-text.mat' ];
save(textBBoxesName,'textBBoxes');
end