function [Data, RMS] = read_ionex3(FileName, ReadRMS)
if nargin < 1
    FileName = "E:\matlab\AP_RBF\DATA\OUTPUT\Ionex\srim0010.24i";
end

if nargin < 2
    ReadRMS = 0;
end

n = 0;
lat_resolution = 2.5;
lon_resolution = 5;
lon_num = 360 / lon_resolution + 1;
lat_num = 180 / lat_resolution - 1;
data_lines = ceil(lon_num / 16);

Lines = readlines(FileName);

while true
    n = n + 1;
    if contains(Lines(n), 'INTERVAL')
        break
    end
end
TimeResolution = str2double(Lines{n}(2:6));
map_num = 24 * 60 * 60 / TimeResolution + 1;

while true
    n = n + 1;
    if contains(Lines(n), 'START OF TEC MAP')
        break
    end
end

WeightArray = zeros(80, lon_num);
for i = 1 : lon_num
    WeightArray(1 + 5 * (i - 1) : 5 * i, i) = logspace(3, -1, 5);
end

Data = zeros(lat_num, lon_num, map_num);
for i = 1 : map_num
    n = n + 3;
    for j = 1 : lat_num
        Current_Line = horzcat(Lines{n : n + data_lines - 1});
        Current_Line = Current_Line - '0';
        Current_Line(366:end) = [];
        Current_Line(Current_Line > 9 | Current_Line < 0) = 0;
        Data(j, :, i) = Current_Line * WeightArray;
        n = n + data_lines + 1;
    end
end

if ~ReadRMS
    RMS = [];
    return
end

RMS = zeros(lat_num, lon_num, map_num);
for i = 1 : map_num
    n = n + 3;
    for j = 1 : lat_num
        Current_Line = horzcat(Lines{n : n + data_lines - 1});
        Current_Line = Current_Line - '0';
        Current_Line(366:end) = [];
        Current_Line(Current_Line > 9 | Current_Line < 0) = 0;
        RMS(j, :, i) = Current_Line * WeightArray;
        n = n + data_lines + 1;
    end
end
end
