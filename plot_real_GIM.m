%Data = read_ionex3("E:\matlab\SRBF\DATA\OUTPUT\Ionex\srim0100.24i");%这里是绘制XUSG的图像
addpath('E:\matlab\SRBF\functions')
GIM_name=("uqrg0350.19i");
Data=read_ionex3(fullfile("E:\gnss_data\gims\analysis_center_daily\codg\2019\035",GIM_name));
Western_Edge  = -180;
Eastern_Edge  = 180;
Nothern_Edge  = 87.5;
Southern_Edge = -87.5;
Lon_Res = 5;
Lat_Res = 2.5;
addpath("E:\matlab\SRBF\functions");
% Generate global grid
[Lon, Lat] = meshgrid(Western_Edge : Lon_Res : Eastern_Edge, ...
        Nothern_Edge : -Lat_Res : Southern_Edge);
Data_Size = size(Lon);
Lon = reshape(Lon, [], 1);
Lat = reshape(Lat, [], 1);
figW = 12.9;                         % 宽度：12.7cm
figH = 7.62;                         % 高度：可以自己调，建议 7.62cm
char_name=char(GIM_name);
save_file=fullfile("E:\matlab\SH","GIM",char_name(1:4));
if ~exist(save_file,"dir")
    mkdir(save_file);
end

for i=1:size(Data,3)
        figure('Units','centimeters','Position',[25,25,figW,figH]);
        hold on;
       
        imagesc(Lon, Lat,Data(:,:,i));
        % clim([0, 85]);
        colormap(gca, turbo(256));              % 替换为更现代的 turbo 色带
        set(gca, 'YDir', 'normal');             % 保证y轴方向朝上
        % 把坐标轴扩到真实边界，避免裁切半格
        hold on;
        coast = load('coastlines');
        plot(coast.coastlon, coast.coastlat, 'k', 'LineWidth', 0.5);
        set(gca, ...
                'TickDir', 'in', ...               % 刻度朝外
                'LineWidth', 0.8, ...               % 坐标轴线条粗细
                'FontSize', 7.5, ...                  % 字体大小
                'FontName','Times New Roman');               % 字体类型（可选）
        xtickangle(0);
        xticks(-180:60:180);
        yticks(-90:30:90);
        cb = colorbar('eastoutside');

        cb.Label.String = 'VTEC (TECU)';
        title_name=sprintf("CODE-UT-%d-TEC-MAP",i-1);
        title(title_name,'FontName','Times New Roman','FontWeight', 'bold',FontSize=10);
        % === 自动调整边距防止裁剪 ===
        set(gca, 'LooseInset', [0.01, 0.01, 0.02, 0.01]);
        % === 设置输出尺寸与保存 SVG 图像 ===
        set(gcf, 'PaperUnits', 'centimeters');
        set(gcf, 'PaperPosition', [0, 0, figW, figH]);  % 宽12.7，高7.62（单位：cm）
        filename=title_name+'.png';
        print_file=fullfile(save_file,filename);
        print(gcf, print_file, '-dpng');  % 保存为 SVG 矢量图
        % 删除当前图像窗口
        close(gcf);

end
