function [B,L,H] = XYZ2BLH(X,Y,Z,varargin)
%WGS84,GSR80,CGCS2000,空间直角坐标转大地坐标

p = inputParser;
addParameter(p,'a',6378137);
addParameter(p,'ab',1/298.25722210103);
addParameter(p,'ref_ellipsoid','GSR80');
parse(p,varargin{:})

ref_ellipsoid = p.Results.ref_ellipsoid;
a = p.Results.a;
ab = p.Results.ab;

%计算椭球参数
if ref_ellipsoid == "GSR80"
    a=6378137;
    ab=1/298.25722210103;
end

if ref_ellipsoid == "WGS84"
    a = 6378137;
    ab=1/298.257223563;
end

if ref_ellipsoid == "CGCS2000"
    a = 6378137;
    ab = 1/298.25722210100;
end

b=a-a*ab;
e2=(a^2-b^2)/(a^2);
%计算经度
L=atan2(Y,X);
%计算纬度
B0 = atan(Z./((X.^2+Y.^2).^(1/2)));


while 1
   N = a./sqrt(1-e2*sin(B0).^2);
   B1 = atan((Z+e2.*N.*sin(B0))./sqrt(X.^2+Y.^2));

   if all(abs(B0-B1) < 1e-10)
       break
   end

   B0=B1;
end

B=B1;
H=sqrt(X.^2+Y.^2)./cos(B1)-N;

