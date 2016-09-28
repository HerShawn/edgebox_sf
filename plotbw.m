

function h = plotbw(img1)

img2 =bwareaopen(img1,6,8);       %���հ���ͨ���򣬽����С��6����ͨ�����˳���

[L,num] = bwlabel(img2,8);      % ����img2�İ���ͨ����LΪ���صĴ����ͼ�񣬳ߴ���img2��ͬ��numΪ��ͨ������Ŀ��

% PS��������̬ѧ�˲����룺
% 
SE1=strel('square',3);

img2= imerode(img2,SE1,'same');
% 
 img2=imdilate(img2,SE1,'same');
% 


%          Ȼ�󣬾�Ҫ����ͬ����ͨ�����ò�ͬ����ɫ��ʶ������

[m,n] = size(img2);

img_color = zeros(m,n,3);   % ��ʾͼ����ͨ����

img_color_tmp =reshape(img_color,m*n,3);  % ���ɶ�ά�ģ�����find��������Ϊfind�ҵ���һά�������±ꣻ

%% Ϊ����ɫ��ʾ���ӷḻ���ҵ�����4����ɫģ�飬ÿһ����ʾ64����ɫ��(�ɲο��ղص�CSDN���ͣ��и������ɫģ����Ϣ)

color_map1 = colormap(cool(64));     % ��ɫģ��1

color_map2 = colormap(hot(64));     % ��ɫģ��2

color_map3 = colormap(hsv(64));     % ��ɫģ��3

color_map4 = colormap(pink(64));     % ��ɫģ��4

color_map =[color_map1;color_map2;color_map3;color_map4];        % ����ɫģ��ƴ������������һ��256����ɫ��color_map������Ϊ��ͨ������ĿС��256��

power = floor(256/num);     % ��Ȩ��Ϊ�˽���ɫ���ֵĸ���������Ļ���ɫ̫�ӽ�����ʾ�������
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

h=figure;imagesc(img_color);  % ��ʾͼ��

end