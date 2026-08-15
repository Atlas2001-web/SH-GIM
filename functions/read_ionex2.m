function [Data, RMS] = read_ionex2(FileName, TimeResolution, ReadRMS)

if nargin < 1
    FileName = "F:\MIT\IGS VTEC\igsg0010.20i";
end
if nargin < 2
    TimeResolution = 3600;
end
if nargin < 3
    ReadRMS = 0;
end

n = 0; % 行位置定位

% 设定经纬度网格大小，目前的GIMs均为2.5°×5°
lat_resolution = 2.5;
lon_resolution = 5;

%计算每组数据个数
lon_num = 360 / lon_resolution + 1;
lat_num = 180 / lat_resolution - 1;

% 计算同一纬度下的数据个数
DataLines = ceil(lon_num/16);

map_num = 24*60*60/TimeResolution + 1; 

Lines = readlines(FileName);

while 1
    n = n + 1;
    if contains(Lines(n), 'START OF TEC MAP')
        break
    end
end

% 生成数据转换矩阵
WeightArray = zeros(80, lon_num);
for i = 1 : lon_num 
    WeightArray(1 + 5*(i - 1) : 5*i, i) = logspace(3, -1, 5);
end

Data = zeros(lat_num, lon_num, map_num);
for i = 1 : map_num
    n = n + 3;

    for j = 1 : lat_num
        CLine = horzcat(Lines{n : n + DataLines - 1});
        CLine = CLine - '0';
        CLine(366:end) = [];
        CLine(CLine > 9 | CLine < 0) = 0;
        Data(j, :, i) = CLine*WeightArray;

        n = n + DataLines + 1;
    end
end

% 根据需求读取RMS
if ReadRMS

    RMS = zeros(lat_num, lon_num, map_num);
    for i = 1 : map_num
        n = n + 3;

        for j = 1 : lat_num
            CLine = horzcat(Lines{n : n + DataLines - 1});
            CLine = CLine - '0';
            CLine(366:end) = [];
            CLine(CLine > 9 | CLine < 0) = 0;
            RMS(j, :, i) = CLine*WeightArray;

            n = n + DataLines + 1;
        end
    end

end

end