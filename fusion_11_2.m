
clear
clc

dir_img = dir('C:\Users\Administrator\Desktop\制作数据集\Challenge2_Test_Task12_Images\*.jpg');
num_img = length(dir_img);
for indexImg = 1:64
    img_value = dir_img(indexImg).name;
    img_value = img_value(1:end-4);
    img_name = ['C:\Users\Administrator\Desktop\制作数据集\Challenge2_Test_Task12_Images\' img_value '.jpg'];
    g = imread(img_name);
    load([img_value '-fusion.mat']);
    fusionAfterClassify = insertShape(g, 'Rectangle', fusionBbox(:,1:4),'LineWidth',1);
    fusionAfterClassifyNum=size(fusionBbox,1);
    if fusionAfterClassifyNum~=0
        for ii=1:fusionAfterClassifyNum
            text_str{ii} =[ '(' num2str(ii) ')' '#' num2str(fusionBbox(ii,5))];
        end
        fusionAfterClassify = insertText(fusionAfterClassify,fusionBbox(:,1:2),text_str,'FontSize',12,'BoxOpacity',0,'TextColor','red');
        clear text_str
        save_name=[img_value '-fusion' '.bmp'];
        imwrite(fusionAfterClassify,save_name);       
    else
        save_name=[img_value '-fusion' '.bmp'];
        imwrite(g,save_name);      
        
    end   
end