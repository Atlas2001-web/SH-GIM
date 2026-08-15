function MLat = Get_MLat(geoLat, geoLon)
if nargin < 1
    geoLat = 10;
    geoLon = 10;
end

[LonGrid, LatGrid] = meshgrid(-180:180, 89:-1:-89);
load('E:\matlab\FYTEC\mat_data\inclination.mat', 'inclination_grid')

MLat = interp2(LonGrid, LatGrid, inclination_grid, geoLon, geoLat);

end