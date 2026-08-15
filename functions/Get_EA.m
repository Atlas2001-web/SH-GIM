function [elevation_angle , azimuth_angle] =  ...
         Get_EA(Xr, Yr, Zr, Xs, Ys, Zs)

[E, N, U] = XYZ2ENU(Xr, Yr, Zr, Xs, Ys, Zs);

elevation_angle = atan(U./sqrt(E.^2+N.^2));

azimuth_angle = atan(abs(E./N));

azimuth_angle(N>0 & E<=0)  = 2*pi - azimuth_angle(N>0 & E<=0);
azimuth_angle(N<=0 & E>0)  = pi - azimuth_angle(N<=0 & E>0);
azimuth_angle(N<=0 & E<=0) = pi + azimuth_angle(N<=0 & E<=0);

end