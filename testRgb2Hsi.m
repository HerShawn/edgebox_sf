clear
close all
dir_img = dir('C:\Users\Administrator\Desktop\�������ݼ�\Challenge2_Test_Task12_Images\*.jpg');
num_img = length(dir_img);

for indexImg = 83:83
    img_value = dir_img(indexImg).name;
    img_value = img_value(1:end-4);
    img_name = ['C:\Users\Administrator\Desktop\�������ݼ�\Challenge2_Test_Task12_Images\' img_value '.jpg'];
    g = imread(img_name);
    R=g(:,:,1);
    testColorMser(R);
    G=g(:,:,2);
    testColorMser(G);
    B=g(:,:,3);
    testColorMser(B);
    [H,S,V]=rgb2hsv(g);
    testColorMser(H);
    testColorMser(S);
    testColorMser(V);
    close all
    
    %
    %     figure;
    %     imshow(rgb2gray(g));title('�Ҷ�ͼ��');
    %     figure;
    %     subplot(1,3,1);imshow(R);title('R����ͼ��');
    %     subplot(1,3,2);imshow(G);title('G����ͼ��');
    %     subplot(1,3,3);imshow(B);title('B����ͼ��');
end