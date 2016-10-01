
clear;
close all;
clc;
before_dir = 'C:\Users\Administrator\Desktop\制作数据集\正样本集\svt10_test_words';
after_dir = 'C:\Users\Administrator\Desktop\制作数据集\正样本集\svt10_test_words2';

imgIds=dir(before_dir); imgIds=imgIds([imgIds.bytes]>0);
imgIds={imgIds.name}; ext=imgIds{1}(end-2:end);
nImgs=length(imgIds);
for i=1:nImgs, 
    img=imread([before_dir '\' imgIds{i}]);
    imshow(img);
    imgIds{i}=imgIds{i}(1:end-4);
    imgIds{i}= num2str(i+2041);
    imwrite(img,[after_dir '\' imgIds{i} '.bmp' ]);
end

