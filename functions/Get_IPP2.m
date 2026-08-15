function [IPP_Lat, IPP_Lon] = Get_IPP2(SitePos, SatellitePos, ShellHeight)

SiteHeight = sqrt(sum(SitePos.^2, 2));
SatelliteHight = sqrt(sum(SatellitePos.^2, 2));

SiteToSatellite = sqrt(sum((SitePos - SatellitePos).^2, 2));
cosEle = (SiteToSatellite.^2 + SiteHeight.^2 - SatelliteHight.^2) ./ (2.*SiteToSatellite.*SiteHeight);
Ele = acos(cosEle);

SinZ_ = SiteHeight .* cosEle ./ (SiteHeight + ShellHeight);
Z_ = asin(SinZ_);

Scale = SiteHeight.*sin(pi/2 - Ele - Z_) ./ SinZ_ ./ SiteToSatellite;

dPos = (SatellitePos - SitePos) .* Scale;
IPP_Pos = SitePos + dPos;

[IPP_Lat, IPP_Lon] = XYZ2BLH(IPP_Pos(:, 1), IPP_Pos(:, 2), IPP_Pos(:, 3));
IPP_Lat = rad2deg(IPP_Lat);
IPP_Lon = rad2deg(IPP_Lon);
end