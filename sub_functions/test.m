% 生成地磁赤道线
clear all; close all;

% 创建全球经纬度网格
lon = deg2rad(-180:1:180); % 经度从-180°到180°，步长2°
lat = deg2rad(-30:1:30);   % 纬度从-30°到30°，步长2°（地磁赤道通常在赤道附近）
[Lon, Lat] = meshgrid(lon, lat);

% 调用 geo2mag 函数计算地磁纬度
[Mlat, Mlon] = geo2mag(Lat, Lon);

% 找到地磁赤道（Mlat ≈ 0）
threshold = deg2rad(0.5); % 阈值，例如0.5°
equator_idx = abs(Mlat) < threshold; % 找到 |Mlat| < threshold 的点
equator_lon = rad2deg(Lon(equator_idx)); % 对应的地理经度
equator_lat = rad2deg(Lat(equator_idx)); % 对应的地理纬度

% 保存地磁赤道数据
save('M_equator.mat', 'equator_lon', 'equator_lat');

% 绘制地磁赤道线
figure;
worldmap('World'); % 使用世界地图

title('Geomagnetic Equator Line');
geoshow('landareas.shp', 'FaceColor', [0.8 0.8 0.8]); % 添加陆地轮廓
plotm(equator_lat, equator_lon, 'r-', 'LineWidth', 2); % 绘制地磁赤道线