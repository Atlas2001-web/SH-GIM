% 生成路透网格的函数
function [latitudes, longitudes,R] = Get_Reters(agle)
    % 输入:
    %   agle: 纬度间隔，以弧度为单位
    % 输出:
    %   latitudes: 纬度（弧度，列向量）
    %   longitudes: 经度（弧度，列向量）

    c = pi / agle; % 纬度划分数量

    % 初始化网格点
    latitudes = [];
    longitudes = [];

    % 生成Reuter网格点
    for j = 1:c-1
        % 当前纬度角
        phi_j = j * pi / c;

        % 计算经度间距
        delta_lambda_j = acos((cos(pi / c) - cos(phi_j)^2) / sin(phi_j)^2);

        % 当前纬度圈的点数
        cj = floor(2 * pi / delta_lambda_j);

        % 计算每个点的经纬度
        for i = 0:cj-1
            lambda_ij = 0.5 * delta_lambda_j + 2 * pi * i / cj;
            latitudes = [latitudes; rad2deg(phi_j) - 90];  % 转换为度数并添加到列表
            longitudes = [longitudes; rad2deg(lambda_ij)]; % 转换为度数并添加到列表
        end
    end

    % 添加极点
    latitudes = [latitudes; 90; -90];
    longitudes = [longitudes; 0; 0];

    % 将经度转换到 [-180, 180] 范围
    longitudes(longitudes > 180) = longitudes(longitudes > 180) - 360;

    % 输出结果转为弧度
    longitudes = deg2rad(longitudes);
    latitudes = deg2rad(latitudes);
    R=ones(length(latitudes),1)*(6371000+450000);
end

