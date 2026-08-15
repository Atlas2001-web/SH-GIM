function gpsSeconds = datetime2GPSs(time)
if nargin < 1
    time = datetime(1980, 1, 6, 1, 0, 0);
end
% 定义 GPS 时间起点
gpsEpoch = datetime(1980, 1, 6, 0, 0, 0);

% 计算时间差（秒）
timeDiff = time - gpsEpoch;

% 转换为秒数
gpsSeconds = seconds(timeDiff);

end
