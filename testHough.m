clear all
close all
clc
I=imread('img_3.jpg');
BW=im2bw(I);
BW=edge(BW,'canny');
figure(1)
imshow(BW);
% I=imdilate(I,strel('disk',8));
% I=imerode(I,strel('disk',8));
% BW=bwmorph(I,'thin',20);
%%

[H,T,R] = hough(BW);
figure(2)
imshow(H,[],'XData',T,'YData',R,...
'InitialMagnification','fit');
xlabel('\theta'), ylabel('\rho');
axis on, axis normal, hold on;
P = houghpeaks(H,1000,'threshold',ceil(0.3*max(H(:))));
x = T(P(:,2)); y = R(P(:,1));
plot(x,y,'s','color','white');
lines = houghlines(BW,T,R,P,'FillGap',5,'MinLength',7);
figure(3),imshow(BW), hold on
max_len = 0;
%%

for k = 1:length(lines)
xy = [lines(k).point1; lines(k).point2];
plot(xy(:,1),xy(:,2),'LineWidth',2,'Color','green');

% Plot beginnings and ends of lines
plot(xy(1,1),xy(1,2),'x','LineWidth',2,'Color','yellow');
plot(xy(2,1),xy(2,2),'x','LineWidth',2,'Color','red');
end