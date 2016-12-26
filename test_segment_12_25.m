

for indexImg = 58:58
    img_value = dir_img(indexImg).name;
    img_value = img_value(1:end-4);
    img_name = ['C:\Users\Administrator\Desktop\制作数据集\Challenge2_Test_Task12_Images\' img_value '.jpg'];
    I = imread(img_name);
    I = rgb2gray(I);
    
    figure;
    imshow(I);
    

    Icorrected = imtophat(I, strel('disk', 15)); 
    BW1 = imbinarize(Icorrected);
    
    figure;
    imshowpair(Icorrected, BW1, 'montage');

    
    marker = imerode(Icorrected, strel('line',10,0));
    Iclean = imreconstruct(marker, Icorrected);
    
    BW2 = imbinarize(Iclean);
    
    figure;
    imshowpair(Iclean, BW2, 'montage');
    
end

close all