function Compare_SHCof()
%这里是将自己计算的球鞋系数与code官方的球鞋系数进行对比处理
close all

set(groot, 'defaultAxesFontSize', 10)
set(groot, 'defaultTextFontSize', 10)
set(groot, 'defaultConstantLineFontSize', 10)
set(groot, 'DefaultAxesFontName', 'Times New Roman');
set(groot, 'DefaultTextFontName', 'Times New Roman');
set(groot, 'DefaultAxesBox', 'on')
set(groot, 'DefaultAxesXGrid', 'on')
set(groot, 'DefaultAxesYGrid', 'on')
set(groot, 'DefaultAxesGridLineStyle', '--')

Time = datetime([2024, 6, 4]);
order = 15;
CofNum = (order+1)^2;

load(sprintf('.\\SH Coefficients\\SH_%02d%03d.mat', ...
             year(Time)-round(year(Time), -3), day2doy(Time)), 'IONC')
SHCof_byH = IONC;

FileName = sprintf('F:\\ION\\COD0OPSFIN_%d%03d0000_01D_01H_GIM.ION', ...
                   year(Time), day2doy(Time));
SHCof_byCODE = read_SHCof(FileName);

FigNum = numel(SHCof_byH)/CofNum;
ax = Get_ax(ceil(FigNum/3), 3, 0.6, 0.4, [0.1 1], [1.25 0.5], 20, [2 3]);

for i = 1 : numel(SHCof_byH)/CofNum
    axes(ax{i})
    SHCof_byH1 = SHCof_byH((i-1)*CofNum+1 : CofNum*i);
    SHCof_byCODE1 = SHCof_byCODE{(i-1)*2+1};
    scatter(1:CofNum, SHCof_byH1, 10, 'filled')
    hold on
    scatter(1:CofNum, SHCof_byCODE1, 10, 'filled')
    hold off
    
    ylim([-20, 40])

    if i > 4
        yticklabels({})
    end
    if mod(i, 4) ~= 0
        xticklabels({})
    end

    legend('M\_DCB-H', 'CODE')
end
for i = 1 : numel(ax)
    set(ax{i}, 'Units', 'normal.l; b n.//。，mnblized')
end

print(gcf, '.\SH_Compare.jpg', '-djpeg', '-r600')

winopen('.\SH_Compare.jpg')