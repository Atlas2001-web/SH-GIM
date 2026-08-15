function plot_TEC_kent(fig, latlim, lonlim, Pname_D, VTEC_Diff, lat1, lat2, lon1, lon2,savefile,currentPath)
%% Plot_TEC: 绘制全球或区域的电离层图
% 输入参数说明：
% fig: 产品的组数（分时段绘制多个地图）
% latlim, lonlim: 纬度和经度的分辨率
% Pname: 绘制的图像的前缀名称
% PaintData: 包含需要绘制的纬度、经度和TEC数据的矩阵
% lat1, lat2: 纬度范围（lat2为最小纬度，lat1为最大纬度）
% lon1, lon2: 经度范围（lon1为最小经度，lon2为最大经度）
% limmin, limmax: 色条（colorbar）的上下限值
warning off; % 关闭警告信息，避免不必要的警告输出
addpath(fullfile(currentPath,'functions','Tools','m_map'))
x=repmat((lon1:lonlim:lon2)',71,1);
y=repelem((lat1:-latlim:lat2)',73,1);
if exist(savefile, 'dir') == 0
    mkdir(savefile)
end
%% 循环绘制每一组数据对应的地图
for i = 1:fig

    %获取这个时间段的经纬度和具体的数值信息
    % 提取当前时间段的数据
    z_ = (VTEC_Diff(:,:,i))';
    z=z_(:);% 总电子含量（TEC）
    %这里的z是对数值进行提取操作，这里计算的RMS也是插值点的RMS，在后面评估的时候也是使用这个
    % 使用 griddata 对数据进行插值，生成更平滑的网格数据
    [X, Y, Z] = griddata(x, y, z, linspace(lon1, lon2, 101)', linspace(lat2, lat1, 101), 'v4');

    % 绘制插值结果的轮廓图
    contourf(X, Y, Z);

    % 构建均匀的网格
    lat = lat2:((lat1 - lat2) / 100):lat1; % 纬度网格
    lon = lon1:((lon2 - lon1) / 100):lon2; % 经度网格
    [Plg, Plt] = meshgrid(lon, lat); % 构建经纬度网格

    % 使用 M_Map 工具进行地图绘制，设置投影方式
    m_proj('Miller Cylindrical', 'longitudes', [lon1 lon2], 'latitudes', [lat2 lat1]);

    % 使用伪彩图（pcolor）绘制插值结果
    m_pcolor(Plg, Plt, Z);

    % 设置图像属性
    set(gca, 'FontSize', 14); % 设置坐标轴字体大小
    hold on; % 保持当前绘图窗口，方便叠加其他内容

    % 绘制海岸线
    m_coast('line', 'color', 'k', 'linewidth', 0.5); % 黑色线条表示海岸线

    % 添加经纬度网格
    m_grid('xaxis', 'bottom'); % 显示经纬度网格线
    shading interp; % 使图像颜色平滑

    % 设置颜色映射和色条
    colormap(jet); % 使用 jet 颜色映射
    h = colorbar; % 添加色条
    set(get(h, 'Title'), 'string', 'TECU'); % 为色条添加标题
    %caxis([limmin, limmax]); % 设置色条的上下限，加了没什吊用
    clim([min(Z(:)), max(Z(:))]); % 表示色条的最大值和最小值

    % 标题设置
    flag(i) = (i - 1) * (24 / (fig-1)); % 计算当前地图对应的时间
    set(gca, 'FontSize', 14); % 再次设置坐标轴字体大小
    title([Pname_D, num2str(flag(i)), ' : 00'], 'FontSize', 16); % 设置图像标题

    % 调整坐标轴以适应图像
    axis tight;

    % 设置下一次绘图时替换当前内容
    set(gca, 'nextplot', 'replacechildren');

    % 保存当前帧，用于生成动画或保存图像
   

    % 保存当前图像为 .fig 文件
    picname = [Pname_D, num2str(i), '.png'];
    saveas(gcf, [savefile '/' picname]);

    % 显示进度信息
    disp(['--------> [ ', num2str(i), ' / ', num2str(fig), ' ] ionospheric maps have been plotted!']);
end

% 关闭所有绘图窗口
close all;
end