function [E,N,U] = XYZ2ENU(XR,YR,ZR,XS,YS,ZS)

[B,L,~] = XYZ2BLH(XR,YR,ZR);

SINL = sin(L);
COSL = cos(L);
SINB = sin(B);
COSB = cos(B);
dx = XS-XR;
dy = YS-YR;
dz = ZS-ZR;
E = -SINL.*dx+COSL.*dy;
N = -SINB.*COSL.*dx-SINB.*SINL.*dy+COSB.*dz;
U = COSB.*COSL.*dx+COSB.*SINL.*dy+SINB.*dz;

