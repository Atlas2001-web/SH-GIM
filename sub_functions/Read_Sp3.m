function [Pos, Sat_Num] = Read_Sp3(File_Path) % 读取 SP3 轨道文件，输出每个 GNSS 系统的卫星坐标矩阵 Pos 和各系统最大 PRN 号 Sat_Num
%在这里面计算的时候，如果某一颗卫星不存在，那么这颗卫星就是默认为0； % 说明：矩阵预分配为 0，未填值的卫星即默认为 0
if nargin < 1 % 如果未提供文件路径参数
    File_Path = "F:\podTEC\GNSS\sp3\2024\152\COD0MGXFIN_20241520000_01D_05M_ORB.SP3"; % 使用默认示例路径
end % 结束 if

Lines = readlines(File_Path); % 将文件按行读入为字符串数组 Lines

% 读取头文件信息 % 下面解析头部，直到遇到首个历元行（以 * 开头）
l = 0; % 行号计数器初始化
while 1 % 无限循环，遇到首个历元行后 break
    l = l + 1; Line = Lines{l}; % 前进一行并取出当前行文本
    if Line(1) == "#" && Line(2) ~= '#' % 匹配以单个 # 开头的头信息行（不是 ##）
        Pos_Num = sscanf(Line(36:39), '%f'); % 第 36-39 列为当天位置记录数（历元数）
        Resolution = 86400/(Pos_Num - 1); % 根据记录数得到时间分辨率（秒）
    end % 结束 if（# 行）

    if Line(1:2) == "+ " % 匹配以 "+ " 开头的卫星清单段（后续若干行，每行至多 17 颗）
        Sat_Num = sscanf(Line(4:6), '%d'); % 第 4-6 列为卫星总数（跨系统）
        Sat_Lines_Num = ceil(Sat_Num / 17); % 计算需要读取的清单行数（每行 17 颗）
        Sat_Lines = Lines(l : l + Sat_Lines_Num - 1); % 取出这几行原始文本
        Sat_Lines = cellfun(@(x) x(10:60), Sat_Lines, 'UniformOutput', false); % 每行截取 10-60 列（含系统与 PRN）
        Sat_Lines = horzcat(Sat_Lines{:}); % 将多行内容横向拼接成一串
        Sat_GNSS = Sat_Lines(1:3:end); % 每 3 字符一组：第 1 个字符为系统标识（G/R/E/C/...）
        Sat_GNSS = Sat_GNSS(1:Sat_Num); % 仅保留前 Sat_Num 个系统标识
        Prn = zeros(Sat_Num, 1); % 为每颗卫星的 PRN 预分配数组
        for i = 1 : Sat_Num % 遍历每颗卫星
            Sat_Prn = Sat_Lines(2 + 3*(i-1) : 3*i) - '0'; % 取两位 PRN 字符并转为数字 0..9
            Sat_Prn(Sat_Prn > 9 | Sat_Prn < 0) = 0; % 非数字位置归零（防御）
            Prn(i) = Sat_Prn * [10; 1]; % 两位组合为十进制 PRN
        end % 结束 for
        GNSS = unique(Sat_GNSS); % 提取出现过的 GNSS 系统集合
        Sat_Num = struct(); % 重用变量名为结构体：记录各系统的最大 PRN 号
        for i = 1 : numel(GNSS) % 遍历每个 GNSS 系统
            Idx = Sat_GNSS == GNSS(i); % 属于该系统的布尔索引
            Num = max(Prn(Idx)); % 该系统出现的最大 PRN（用于列数）
            Sat_Num.(GNSS(i)) = Num; % 保存到结构体字段（字段名为系统字符）
            Pos.(GNSS(i)).x = zeros(Pos_Num, Num); % 为该系统分配 X 坐标矩阵（历元数×最大 PRN）
            Pos.(GNSS(i)).y = zeros(Pos_Num, Num); % 为该系统分配 Y 坐标矩阵
            Pos.(GNSS(i)).z = zeros(Pos_Num, Num); % 为该系统分配 Z 坐标矩阵
        end % 结束 for
            l = l + Sat_Lines_Num - 1; % 跳过已读的卫星清单行
    end % 结束 if（+ 段）

    if Line(1) == '*' % 首次遇到历元标记行（* yyyy mm dd hh mm ss）
        break % 结束头解析循环
    end % 结束 if（* 行）
end % 结束 while

End_Idx = find(cellfun(@(x) contains(x, 'EOF'), Lines(end-1 : end))); % 在最后两行中查找 EOF 所在的行索引（1 或 2）
Data_Lines = Lines(l : end-(2 - End_Idx) - 1); % 取从当前行到 EOF 之前的所有数据行（不含 EOF 行）

Idx = cellfun(@(x) x(1) == '*', Data_Lines); % 标记哪些行是历元行（以 * 开头）
Epoch_Lines = vertcat(Data_Lines{Idx}); % 将所有历元行竖向拼接为字符矩阵
Epoch_Lines = Epoch_Lines(:, 15:31); % 截取历元行中时分秒相关的列（15-31）

Hour_Epoch = 3600/Resolution; % 每个历元对应的小时增量（按分辨率折算）
Minute_Epoch = 60/Resolution; % 每个历元对应的分钟增量
Second_Epoch = 1/Resolution; % 每个历元对应的秒增量

Ex_Array = [10, 1, zeros(1, 15); ... % 权重矩阵第 1 行：小时的十位与个位
    zeros(1, 3), 10, 1, zeros(1, 12); ... % 第 2 行：分钟的十位与个位
    zeros(1, 6), 10, 1, 0, logspace(-1, -8, 8)]'; % 第 3 行：秒的十位与个位及小数位（1e-1..1e-8）
Epoch_Lines = Epoch_Lines - '0'; % 将字符 '0'..'9' 转为数值 0..9
Epoch_Lines(Epoch_Lines > 9 | Epoch_Lines < 0) = 0; % 非数字位置归零
Epoch = Epoch_Lines*Ex_Array*[Hour_Epoch; Minute_Epoch; Second_Epoch] + 1; % 结合权重与分辨率计算线性历元索引，从 1 开始

if Epoch(1) ~= Epoch(end) % 若首末历元索引不同（不等距/异常）
    warning('文件格式不兼容') % 发出格式不兼容警告
else % 否则认为最后一条需要顺延修正
    Epoch(end) = Epoch(end-1) + 1; % 将最后一个历元索引修正为前一值加 1
end % 结束 if

% 处理数据中的异常（COD 的 SP3 某一行可能包含额外字符导致长度超限） % 下面尝试拼接坐标行，失败则先裁剪再拼接
try % 尝试直接拼接所有非历元行
    Pos_Lines = vertcat(Data_Lines{~Idx}); % 非历元行（卫星坐标行）拼成字符矩阵
catch % 若有行长度不一致导致失败
    maskLong = cellfun(@(x) length(x) > 60, Data_Lines); % 找出长度超过 60 的行
    Data_Lines(maskLong) = cellfun(@(x) x(1:60), Data_Lines(maskLong), 'UniformOutput', false); % 将超长行裁剪到前 60 列
    Pos_Lines = vertcat(Data_Lines{~Idx}); % 再次尝试拼接坐标行
end % 结束 try-catch

% 计算数据所属的历元 % 通过行索引映射每条坐标记录到最近的上一条历元
Idx_Data = find(~Idx); % 非历元行的行号（在 Data_Lines 中）
Idx_Epoch = find(Idx); % 历元行的行号（在 Data_Lines 中）

Pos_GNSS = Pos_Lines(:, 2); % 坐标行第 2 列为 GNSS 系统标识（G/R/E/C/...）

Ex_Array = [10, 1, zeros(1, 42); ... % 权重矩阵第 1 行：PRN 两位
    zeros(1, 2), logspace(6, 0, 7), 0, logspace(-1, -6, 6), zeros(1, 28); ... % 第 2 行：X 的整数与小数位权重
    zeros(1, 16), logspace(6, 0, 7), 0, logspace(-1, -6, 6), zeros(1, 14); ... % 第 3 行：Y
    zeros(1, 30), logspace(6, 0, 7), 0, logspace(-1, -6, 6)]'; % 第 4 行：Z
Pos_Lines = Pos_Lines(:, 3:46); % 从坐标行中截取 PRN 与 X/Y/Z 的字符区域
Pos_Lines = Pos_Lines - '0'; % 将字符转换为 0..9（'-' 会变成 -3，用于记录负号）

% 计算负值的位置 % 通过检测 -3（即 '-' - '0'）定位负号所在字段
Idx = find(Pos_Lines == -3); % 找到所有负号位置
[Row_Num, Column_Num] = ind2sub(size(Pos_Lines), Idx); % 转为行列下标
Idx_Column = ceil((Column_Num - 2) / 14); % 将列号映射为字段编号（1=PRN,2=X,3=Y,4=Z；每字段约 14 列）
Idx_Row = Row_Num; % 保留行号以便回填符号
Pos_Lines(Pos_Lines > 9 | Pos_Lines < 0) = 0; % 清理非数字（包括负号处）为 0
Pos_All = Pos_Lines * Ex_Array; % 利用权重矩阵拼装出数值矩阵（PRN, X, Y, Z）
Pos_SatPrn = Pos_All(:, 1); % 取 PRN 列
Pos_Data = Pos_All(:, 2:4); % 取 X/Y/Z 三列数据（此时为非负数）
Idx = sub2ind(size(Pos_Data), Idx_Row, Idx_Column); % 将负号的 (行,字段) 映射为线性索引
Pos_Data(Idx) = -Pos_Data(Idx); % 在相应位置取负号，恢复带符号的坐标

for i = 1 : size(Pos_All, 1) % 遍历每条坐标记录
    Current_Epoch = Epoch(find(Idx_Data(i) > Idx_Epoch, 1, "last")); % 找到该坐标行对应的最近上一条历元索引
    Pos.(Pos_GNSS(i)).x(Current_Epoch, Pos_SatPrn(i)) = Pos_Data(i, 1); % 写入 X 到对应系统/历元/PRN 的位置
    Pos.(Pos_GNSS(i)).y(Current_Epoch, Pos_SatPrn(i)) = Pos_Data(i, 2); % 写入 Y
    Pos.(Pos_GNSS(i)).z(Current_Epoch, Pos_SatPrn(i)) = Pos_Data(i, 3); % 写入 Z
end % 结束 for

end % 函数结束
