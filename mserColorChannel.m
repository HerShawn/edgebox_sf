
clear
close
dir_img = dir('C:\Users\Administrator\Desktop\制作数据集\Challenge2_Test_Task12_Images\*.jpg');
num_img = length(dir_img);

for indexImg = 1:num_img
    img_value = dir_img(indexImg).name;
    img_value = img_value(1:end-4);
    img_name = ['C:\Users\Administrator\Desktop\制作数据集\Challenge2_Test_Task12_Images\' img_value '.jpg'];
    img = imread(img_name);
    r = img(:,:,1);
    [mserRegions, mserConnComp] = detectMSERFeatures(r, ...
        'RegionAreaRange',[50 8000],'ThresholdDelta',2);
    
    figure
    imshow(r)
    hold on
    plot(mserRegions, 'showPixelList', true,'showEllipses',false)
    title('MSER regions')
    hold off
end