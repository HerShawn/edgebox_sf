

function h = plotbw(img1)

img2 =bwareaopen(img1,6,8);       %按照八连通规则，将面积小于6的连通区域滤除；

[L,num] = bwlabel(img2,8);      % 计算img2的八连通区域，L为返回的带标记图像，尺寸与img2相同，num为连通区域数目；

% PS：附上形态学滤波代码：
% 
SE1=strel('square',3);

img2= imerode(img2,SE1,'same');
% 
 img2=imdilate(img2,SE1,'same');
% 


%          然后，就要将不同的连通区域用不同的颜色标识出来：

[m,n] = size(img2);

img_color = zeros(m,n,3);   % 显示图像，三通道；

img_color_tmp =reshape(img_color,m*n,3);  % 拉成二维的，用于find函数，因为find找的是一维向量的下标；

%% 为了颜色显示更加丰富，我调用了4个颜色模块，每一个表示64种颜色；(可参考收藏的CSDN博客，有更多的颜色模板信息)

color_map1 = colormap(cool(64));     % 颜色模块1

color_map2 = colormap(hot(64));     % 颜色模块2

color_map3 = colormap(hsv(64));     % 颜色模块3

color_map4 = colormap(pink(64));     % 颜色模块4

color_map =[color_map1;color_map2;color_map3;color_map4];        % 将颜色模板拼接起来，构成一个256种颜色的color_map，我认为连通区域数目小于256；

power = floor(256/num);     % 加权，为了将颜色区分的更开，否则的话颜色太接近，显示不清楚；
if power==0
    power=1
    num=255
end
for i = 1:1:num
    
    img_color_tmp(find(L == i),1)= color_map(i*power,1);
    
    img_color_tmp(find(L == i),2)= color_map(i*power,2);
    
    img_color_tmp(find(L == i),3)= color_map(i*power,3);
    
    img_color =reshape(img_color_tmp, m, n, 3);
    
end

h=figure;imagesc(img_color);  % 显示图像；

end