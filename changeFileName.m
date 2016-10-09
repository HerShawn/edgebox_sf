
clear;
close all;
clc;
before_dir = 'C:\Users\Administrator\Desktop\�������ݼ�\2016-10-1���ݼ�\ground\images';
after_dir = 'C:\Users\Administrator\Desktop\�������ݼ�\2016-10-1���ݼ�\ground\';

imgIds=dir(before_dir); imgIds=imgIds([imgIds.bytes]>0);
imgIds={imgIds.name}; ext=imgIds{1}(end-2:end);
nImgs=length(imgIds);
for i=1:nImgs, 
    img=imread([before_dir '\' imgIds{i}]);
    imshow(img);
    imgIds{i}=imgIds{i}(1:end-4);
%     imgIds{i}= num2str(i);
    imwrite(img,[after_dir '\' imgIds{i} '.bmp' ]);
end

