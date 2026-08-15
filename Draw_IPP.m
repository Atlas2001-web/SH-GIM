%%这里给他修改了，让他可以变得计算IPP也可以计算路透社网格点

function Draw_IPP(Time,start_time,end_time,one_time,currentfile,EARTH)
%设置开始时间，结束时间，时间间隔 EARTH表示的是是选择太阳固定坐标系还是地球固定坐标系
close all
if nargin < 1
    Time = datetime([2024, 1, 2]);
end
if nargin < 2
    start_time = 1;
end
if nargin < 3
    end_time = 2880;
end
if nargin < 4
    one_time = 120;
end
if nargin < 4
    currentfile = 'E:\matlab\SRBF';
end
if nargin<5
    EARTH=1;
end
addpath(fullfile(currentfile,'functions\Tools\m_map'));
addpath('E:\matlab\SRBF\sub_functions')
savefile=fullfile(currentfile,'DATA','IPP');
P4_Folder = ['E:\matlab\SRBF\DATA\OUTPUT\' sprintf('P4\\%02d%03d\\*.mat', ...
    year(Time)-round(year(Time), -3), day2doy(Time))];
P4_FileList = dir(P4_Folder);

sp3_FileName =['E:\matlab\SRBF\DATA\OUTPUT\' sprintf('SP3_OUT\\%d%03dsp3.mat', year(Time), day2doy(Time))];
load(sp3_FileName, 'sate')

SiteFile = ['E:\matlab\SRBF\DATA\OUTPUT\' sprintf('Site_Info\\Sites_Info_%02d%03d.mat', ...
    year(Time)-round(year(Time), -3), day2doy(Time))];
load(SiteFile, 'Sites_Info')
figure('Color','w', 'Position',[100 100 700 400]);
if EARTH==1
    % 绘制全球地图
    m_proj('miller', 'lon', [-180 180], 'lat', [-90 90]);  % 使用 Miller 投影
else
    m_proj('miller', 'lon', [-360 360], 'lat', [-90 90]);  % 使用 Miller 投影
end
m_coast('patch', [0.8 0.8 0.8], 'edgecolor', 'k');      % 使用浅灰色填充海岸线，边缘颜色为黑色
m_grid('box', 'fancy', 'tickdir', 'in', 'linestyle', '-', ...
    'linewidth', 1.5, 'fontsize', 14);               % 添加网格，调整线条粗细和字体大小

% 保持当前图形
hold on;
%这里设置时间信息，然后遍历时间阶段，最后绘制出来IPP点位置，这样就可以绘制固定时间段的IPP点
fig=(end_time-start_time+1)/one_time;
for t=1:fig
    ep1=start_time+(t-1)*one_time;
    ep2=start_time*one_time;
    for i = 1 : numel(P4_FileList)
        load(fullfile(P4_FileList(i).folder, P4_FileList(i).name), 'P4')

        SiteName = P4_FileList(i).name(1:4);
        Indice = find(strcmpi(Sites_Info.name, SiteName));

        rx = Sites_Info.coor(Indice, 1);
        ry = Sites_Info.coor(Indice, 2);
        rz = Sites_Info.coor(Indice, 3);

        [Rec_Lat, Rec_Lon] = XYZ2BLH(rx, ry, rz);

        GNSS = fieldnames(P4);
        for m = 1 : numel(GNSS)
            sx0 = sate.(GNSS{m}).x(ep1:ep2,:);
            sy0 = sate.(GNSS{m}).y(ep1:ep2,:);
            sz0 = sate.(GNSS{m}).z(ep1:ep2,:);

            Code = fieldnames(P4.(GNSS{m}));
            for n = 1 : numel(Code)

                Indice = find(P4.(GNSS{m}).(Code{n})(ep1:ep2,:) ~= 0);
                temp_time=(ep1:ep2)';
                time_mairx=repmat(temp_time,1,size(sx0,2));
                % Find valid indices (non-zero P4 values)
                time_line=time_mairx(Indice);


                if isempty(Indice)
                    continue;
                end
                sx = sx0(Indice);
                sy = sy0(Indice);
                sz = sz0(Indice);


                [E, A] = Get_EA(repmat(rx, size(sx)), ...
                    repmat(ry, size(sy)), ...
                    repmat(rz, size(sz)), ...
                    sx*1000, sy*1000, sz*1000);
                if EARTH==1
                    [IPP_Lat, IPP_Lon] = Get_IPP(E, A, ...
                        repmat(Rec_Lat, size(E)), ...
                        repmat(Rec_Lon, size(E)), ...
                        450000, 6378137);
                else
                    t_r = 30 * (time_line - 1) * pi / 43200;
                    [IPP_Lat, IPP_Lon] = Get_IPP_T_r(E, A, ...
                        repmat(Rec_Lat, size(E)), ...
                        repmat(Rec_Lon, size(E)), ...
                        450000, 6378137,t_r);

                end
                IPP_Lon = rad2deg(IPP_Lon);
                IPP_Lat = rad2deg(IPP_Lat);

                hold on

agle = deg2rad(20);

% 获取经纬度信息
[latitudes, longitudes] = Get_Reters(agle);


% 转换为度数
latitudes = rad2deg(latitudes);
longitudes = rad2deg(longitudes);

m_scatter(longitudes, latitudes, 15, 'r', 'filled'); % 修正参数顺序



                %scatter(IPP_Lon, IPP_Lat, 1, 'b', 'filled');
                m_scatter(IPP_Lon, IPP_Lat, 5, 'b','filled', 'MarkerFaceAlpha', 0.7);  % 点大小和透明度调整
                m_scatter(rad2deg(Rec_Lon), rad2deg(Rec_Lat), 25, 'r', 'filled', 'diamond');
            end
        end
    end
    if one_time==120
        t_hour = (ep1 - 1) * 30 / 3600;  % 每 epoch 是30秒 → 换算为小时

        % ==== 构建图片标题和文件名 ====
        pic_title = sprintf('Ionospheric Piercing Point (IPP) at %.2f UTC', t_hour);
        fig_name = sprintf('IPP_%.2f_UTC.jpg', t_hour);
        title(pic_title, 'FontSize', 12);
        saveas(gcf, fullfile(savefile, fig_name));
    else
        pic_title = sprintf('Ionospheric Piercing Point (IPP) from %d to %d UTC', ep1,ep2);
        fig_name = sprintf('IPP_%d-%d_UTC.jpg', ep1,ep2);
        title(pic_title, 'FontSize', 12);
        saveas(gcf, fullfile(savefile, fig_name));
    end
end
end





function [latitudes, longitudes] = Get_Reters(agle)
    % 输入:
    %   agle: 纬度间隔，以弧度为单位
    % 输出:
    %   latitudes: 纬度（弧度，列向量）
    %   longitudes: 经度（弧度，列向量）
addpath('E:\matlab\TOOL_GIM\TOOL_GIM\m_map')
    c = pi / agle; % 纬度划分数量

    % 初始化网格点
    latitudes = [];
    longitudes = [];

    % 生成Reuter网格点
    for j = 1:c-1
        % 当前纬度角
        phi_j = j * pi / c;

        % 计算经度间距，避免超出 [-1,1] 导致 NaN
        cos_val = (cos(pi / c) - cos(phi_j)^2) / (sin(phi_j)^2);
        cos_val = min(max(cos_val, -1), 1);
        delta_lambda_j = acos(cos_val);

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
    longitudes = [longitudes; 0; 0]; % 或者 [NaN; NaN] 以表示极点无固定经度

    % 将经度转换到 [-180, 180] 范围
    longitudes(longitudes > 180) = longitudes(longitudes > 180) - 360;

    % 输出结果转为弧度
    longitudes = deg2rad(longitudes);
    latitudes = deg2rad(latitudes);
end