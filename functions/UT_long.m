function [longitudes_new,latitudes]=UT_long(longitudes,latitudes,fig)
%这里计算出来的值元胞数据是从1开始一直到24截至的
%这里的作用是直接获取这三天的径向基函数点位信息
    if fig <= 0
        error('fig must be greater than 0');
    end
    figt = 2880 / fig;
  longitudes_new=cell(fig,1);
    for i    = 1:fig
        ep = (i-1) * figt;
        UT = ep * 30 / 3600; % 将时间点转换为 UT
        longitudes_new{i} = longitudes + (UT - 12) * 15 * pi / 180; % 调整经度
    end

end
