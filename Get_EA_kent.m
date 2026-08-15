function [E, A] = Get_EA_kent(sx, sy, sz, x, y, z)
%GET_EA 计算站点到卫星的仰角（E）和方位角（A）
% 输入参数：
%   sx, sy, sz - 站点的地心坐标（ECEF）
%   x, y, z - 卫星的地心坐标（ECEF）
% 输出参数：
%   E - 仰角（单位：弧度）
%   A - 方位角（单位：弧度）

% 转换站点的地心坐标为地理坐标（经纬度和大地高）
[sb, sl] = XYZtoBLH_kent(sx, sy, sz);

% 构建从地心坐标到NEU（东北天）坐标的转换矩阵
T = [-sin(sb)*cos(sl), -sin(sb)*sin(sl), cos(sb);
    -sin(sl),          cos(sl),        0;
    cos(sb)*cos(sl),  cos(sb)*sin(sl), sin(sb)];

% 计算卫星相对于站点的位置差
deta_xyz = [x, y, z] - [sx, sy, sz];

% 将差向量转换到NEU坐标系
NEU = T * deta_xyz';

% 计算仰角（Elevation）
E = atan2(NEU(3), sqrt(NEU(1)^2 + NEU(2)^2)); % atan2 适用于防止除零

% 计算方位角（Azimuth）
A = atan2(NEU(2), NEU(1)); % atan2 自动处理象限

% 确保方位角为 [0, 2π]
if A < 0
    A = A + 2 * pi;
end

end