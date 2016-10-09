
function g=sfMask(g,E1)




g1=g(:,:,1);
g2=g(:,:,2);
g3=g(:,:,3);
g1(find(E1==0))=255;
g2(find(E1==0))=255;
g3(find(E1==0))=255;
g(:,:,1)=g1;
g(:,:,2)=g2;
g(:,:,3)=g3;
end