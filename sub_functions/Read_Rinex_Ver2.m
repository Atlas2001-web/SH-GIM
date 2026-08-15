function [obs, coor, rinex_version] = Read_Rinex_Ver2(File_Name, GNSS_choose, Obs_Type, ...
    only_coor, Required_Resolution, Sat_Num)

% --- 1. 参数初始化 ---
if nargin < 1
    File_Name = "E:\matlab\SRBF2\DATA\INPUT\obs\2024\005\gol20050.24o";
end
if nargin < 2 || isempty(GNSS_choose)
    GNSS_choose = {'GREC', [1, 1, 1, 0]};
end
if nargin < 3
    Obs_Type.Rinex2 = {'L1', 'L2', 'C1', 'C2', 'P1', 'P2'};
    Obs_Type.Rinex3.G = {'L1C', 'L2W', 'C1C', 'C2W'};
    Obs_Type.Rinex3.R = {'L1C', 'L2C', 'C1C', 'C2C'};
    Obs_Type.Rinex3.E = {'L1X', 'L5X', 'C1C', 'C2Q'};
end
if nargin < 4
    only_coor = 0;
end
if nargin < 5
    Required_Resolution = 30;
end
if nargin <6
    Sat_Num.C=48;
    Sat_Num.E=36;
    Sat_Num.G=32;
    Sat_Num.J=4;
    Sat_Num.R=24;
end

rinex_version=0;
obs=struct();

% 将需求的观测值类型转换为Ascii
Asc_Obs_Type.Rinex2 = cellfun(@double, Obs_Type.Rinex2, 'UniformOutput', false);
Asc_Obs_Type.Rinex2 = vertcat(Asc_Obs_Type.Rinex2{:});
GNSS = fieldnames(Obs_Type.Rinex3);
for i = 1 : numel(GNSS)
    Asc_Obs_Type.Rinex3.(GNSS{i}) = cellfun(@double, Obs_Type.Rinex3.(GNSS{i}), 'UniformOutput', false);
    Asc_Obs_Type.Rinex3.(GNSS{i}) = vertcat(Asc_Obs_Type.Rinex3.(GNSS{i}){:});
end

%-------------------declare variables-----------
[GNSS_Name, GNSS_choose] = GNSS_choose{:};
% 测站坐标
coor = linspace(0, 0, 3);
% 电离层观测值名称
obst_n = 0;
obst0 = cell(numel(find(GNSS_choose)), 4);
% 数据转换矩阵
Time_Array = [10, 1, zeros(1, 14);
    zeros(1, 3), 10, 1, zeros(1, 11);
    zeros(1, 6), 10, 1, 0, 0.1, 0.01, 0.001, 0.0001, 0.00001, 0.000001, 0.0000001];
% 计算时间转换参数
Ex_Hour = 3600/Required_Resolution;
Ex_Minute = 60/Required_Resolution;
Ex_Second = 1/Required_Resolution;
Ex_Time = [Ex_Hour, Ex_Minute, Ex_Second];
% 计算预分配的空间大小
Epoch_Num = 86400/Required_Resolution;

% =========================================================================
% --- 2. 文件读取与映射 ---
Memmap = memmapfile(File_Name);
Data = double(Memmap.Data);
% 根据换行符定位每一行
Line_Idx = find(Data == 10);
End_Idx = Line_Idx - 2;
Start_Idx = [1; Line_Idx(1 : end-1) + 1];
n = 0;
l = 0;

% --- 3. 头文件解析 ---
while 1
    l = l + 1;
    if l > numel(End_Idx)
        obs = [];
        break
    end
    Line = Data(Start_Idx(l) : End_Idx(l));

    % 版本号
    if numel(Line) > 79 && all(Line(61:80) == single(('RINEX VERSION / TYPE')'))
        rinex_version = [1, 0, 1e-1, 1e-2] * (Line(6:9) - 48);
    end

    % 概略坐标
    if numel(Line) > 78 && all(Line(61:79) == single(('APPROX POSITION XYZ')'))
        Ex_Array = [logspace(8, 0, 9), 0, logspace(-1, -4, 4)];
        Coor_Data = Line(1:42) - 48;
        Coor_Data(Coor_Data > 9 | Coor_Data < 0) = 0;
        % 处理正负号
        if any(Line(1:14) == 45); s1=-1; else; s1=1; end
        if any(Line(15:28) == 45); s2=-1; else; s2=1; end
        if any(Line(29:42) == 45); s3=-1; else; s3=1; end
        coor(1) = s1 * (Ex_Array * Coor_Data(1:14));
        coor(2) = s2 * (Ex_Array * Coor_Data(15:28));
        coor(3) = s3 * (Ex_Array * Coor_Data(29:42));
        if only_coor
            obs = [];
            return
        end
    end

    % =====================================================================
    % --- 4. RINEX 2.x 处理逻辑 ---
    % =====================================================================
    if rinex_version < 3
        if length(Line) > 78 && all(Line(61:79) == single(('# / TYPES OF OBSERV')'))
            % 观测类型数量
            Current_Data = Line(5:6) - 48;
            Current_Data(Current_Data > 9 | Current_Data < 0) = 0;
            obst_n = [10, 1] * Current_Data;
            obst = zeros(obst_n, 2);
            obst_lines = ceil(obst_n/9);
            for i = 1 : obst_lines
                if i == obst_lines
                    line_end = obst_n - 9*(obst_lines-1);
                else
                    line_end = 9;
                end
                for j= 1 : line_end
                    current_pos = (i-1)*9 + j;
                    obst(current_pos, :) = Line(5+6*j : 6+6*j);
                end
                if i ~= obst_lines
                    l = l + 1;
                    Line = Data(Start_Idx(l) : End_Idx(l));
                end
            end
            % 观测值位置
            [Idx, loc] = ismember(Asc_Obs_Type.Rinex2, obst, 'rows');
            loc(loc == 0) = [];
            if isempty(loc)
                obs = struct();
                return
            end
            obst_name = Obs_Type.Rinex2(Idx);
        end

        % 开始读取数据体
        if length(Line) > 72 && all(Line(61:73) == single(('END OF HEADER')'))
            obst_lines_num = ceil(obst_n/5);
            % 预分配
            Sat_Num_R2 = zeros(size(GNSS_choose));
            for i = 1 : numel(GNSS_choose)
                if ~GNSS_choose(i); continue; end
                Sat_Num_R2(i) = Sat_Num.(GNSS_Name(i));
                for j = 1 : numel(obst_name)
                    obs.(GNSS_Name(i)).(obst_name{j}) = zeros(Epoch_Num, Sat_Num_R2(i));
                end
            end

            GNSS_Exist = zeros(1, 4);
            Logic = logical(GNSS_choose);
            GNSS_Required = GNSS_Name(Logic);
            GNSS_Required2 = GNSS_Required;
            Sat_Num_R2 = Sat_Num_R2(Logic);

            % --- 构建 Obs_Array (包含对齐 LLI 的逻辑) ---
            Obs_Array = cell(obst_lines_num, 1);
            for i = 1 : obst_lines_num
                % 每行标准长度80 (16*5)，哪怕最后一行数据不够，我们也按标准位置映射
                if i == obst_lines_num
                    Current_Length = 16 * (obst_n - 5*(obst_lines_num-1));
                else
                    Current_Length = 80;
                end
                Obs_Array{i} = zeros(Current_Length, numel(loc));
            end
            Obs_Array = vertcat(Obs_Array{:});

            % 填充权重：只填充前14位 (数据位)，第15位(LLI)权重保持为0
            for i = 1 : numel(loc)
                Start_Pos = 1 + (loc(i)-1)*16;
                End_Pos   = Start_Pos + 13; % 长度14
                Obs_Array(Start_Pos : End_Pos, i) = ...
                    [logspace(9, 0, 10), 0, 0.1, 0.01, 0.001];
            end
            Obs_Array = Obs_Array';

            while 1
                l = l + 1;
                if l > numel(End_Idx)
                    % 清理不存在的GNSS字段
                    for i = 1 : numel(GNSS_Required2)
                        obs = rmfield(obs, GNSS_Required2(i));
                    end
                    return;
                end
                Line = Data(Start_Idx(l) : End_Idx(l));

                % 识别历元行
                if length(Line)>32 && any(Line(33) == [71, 69, 83, 82, 32]) && ...
                        Line(19) == 46 && Line(1) == 32
                    Time = Line(11:26) - 48;
                    Time(Time < 0 | Time > 9) = 0;
                    ep = Ex_Time * Time_Array* Time  + 1;
                else
                    continue;
                end

                nsat = Line(31:32) - 48;
                nsat(nsat > 9 | nsat < 0) = 0;
                nsat = [10, 1] * nsat;
                lines_num = ceil(nsat/12);
                if ep ~= fix(ep)
                    total_lines = lines_num + obst_lines_num*nsat - 1;
                    l = l + total_lines;
                    continue
                end

                % 读取卫星列表
                Sat_Line = cell(lines_num, 1);
                for i = 1 : lines_num
                    Current_Line = Line(33 : end);
                    if numel(Current_Line) > 36; Current_Line = Current_Line(1 : 36); end
                    Sat_Line{i} = Current_Line;
                    if i ~= lines_num
                        l = l + 1;
                        Line = Data(Start_Idx(l) : End_Idx(l));
                    end
                end
                Sat_Line = vertcat(Sat_Line{:});
                sv_type = char(Sat_Line(1:3:end));
                Sat_Line(1:3:end) = [];
                Sat_Line = Sat_Line - 48;
                Sat_Line(Sat_Line > 9 | Sat_Line < 0) = 0;
                sv_GNSS=linspace(0,0,nsat);
                for i = 1 : nsat
                    sv_GNSS(i) = [10, 1] * Sat_Line(1+(i-1)*2 : 2*i);
                end

                % 标记存在的GNSS
                GNSS_Required2_Idx = false(size(GNSS_Required2));
                for i = 1 : numel(GNSS_Required2)
                    if any(GNSS_Required2(i) == sv_type)
                        GNSS_Exist(GNSS_Required == GNSS_Required2(i)) = 1;
                        GNSS_Required2_Idx(i) = true;
                    end
                end
                GNSS_Required2(GNSS_Required2_Idx) = [];

                % 读取观测值数据
                for i = 1 : nsat
                    Indices = sv_type(i) == GNSS_Required;
                    if ~any(Indices)
                        l = l + obst_lines_num;
                        continue
                    end
                    if sv_GNSS(i) > Sat_Num_R2(Indices)
                        continue
                    end

                    Data_Lines = cell(obst_lines_num, 1);
                    for j = 1 : obst_lines_num
                        Line = Data(Start_Idx(l + j) : End_Idx(l + j));
                        if j ~= obst_lines_num; Data_Num = 5; else; Data_Num = obst_n - 5*(obst_lines_num - 1); end
                        Current_Length = 16 * Data_Num;
                        True_Length = length(Line);
                        if True_Length < Current_Length
                            Line = [Line; repmat(48, Current_Length - True_Length, 1)];
                        elseif True_Length > Current_Length
                            Line = Line(1:Current_Length);
                        end
                        Data_Lines{j} = Line;
                    end
                    Data_Lines = vertcat(Data_Lines{:});
                    Data_Lines = Data_Lines - 48;
                    % 保留空格(-16)用于判断LLI，其他非法字符转0
                    Data_Lines(Data_Lines > 9 | (Data_Lines < 0 & Data_Lines ~= -16)) = 0;

                    % 计算观测值 (只算前14位，忽略第15位LLI)
                    Current_Obs = round(Obs_Array * Data_Lines, 3); % 强制保留3位小数

                    % === LLI 过滤 ===
                    for j = 1 : numel(Current_Obs)
                        lli_idx = (loc(j)-1)*16 + 15;
                        lli_val = 0;
                        if lli_idx <= length(Data_Lines)
                            lli_val = Data_Lines(lli_idx);
                        end
                        % 如果 LLI 不是 0 且不是空格(-16)，则删除
                        if lli_val ~= 0 && lli_val ~= -16
                            Current_Obs(j) = 0;
                        end
                        obs.(sv_type(i)).(obst_name{j})(ep, sv_GNSS(i)) = Current_Obs(j);
                    end
                    l = l + obst_lines_num;
                end
            end
        end

        % =====================================================================
        % --- 5. RINEX 3.x 处理逻辑 ---
        % =====================================================================
    else
        if length(Line) > 78 && all(Line(61:79) == single(('SYS / # / OBS TYPES')'))
            GNSS_type = char(Line(1));
            Current_Data = Line(5:6) - 48;
            Current_Data(Current_Data > 9 | Current_Data < 0) = 0;
            obst_n = [10, 1] * Current_Data;
            obst_lines = ceil(obst_n/13);

            GNSS_Idx = GNSS_Name == GNSS_type;
            if all(~GNSS_Idx) || ~GNSS_choose(GNSS_Idx)
                for i = 1 : obst_lines-1; l = l + 1; end
                continue
            end

            Current_Sat_Num = Sat_Num.(GNSS_type);
            obst_name = Asc_Obs_Type.Rinex3.(GNSS_type);
            n = n + 1;
            obst0{n, 2} = GNSS_type;

            obst = zeros(obst_n, 3);
            for i = 1 : obst_n
                if i > 13 && rem(i , 13) == 1
                    l = l + 1;
                    Line = Data(Start_Idx(l) : End_Idx(l));
                end
                line_n = ceil(i/13);
                column_n = i - (line_n-1)*13;
                obst_pos = 8+(column_n-1)*4 : 10+(column_n-1)*4;
                obst(i, :) = Line(obst_pos);
            end
            [Idx, loc] = ismember(obst_name, obst, 'rows');
            loc(loc == 0) = [];

            Obs_Array = zeros(16*obst_n, numel(loc));
            for i = 1 : numel(loc)
                Obs_Array(1+(loc(i)-1)*16 : loc(i)*16-2, i) = ...
                    [logspace(9, 0, 10), 0, 0.1, 0.01, 0.001];
            end
            obst0{n, 4} = Obs_Array(1:end-2, :)';
            obst0{n, 1} = Obs_Type.Rinex3.(GNSS_type)(Idx);
            obst0{n, 3} = loc;
            obst0{n, 5} = Current_Sat_Num;
            if isempty(Obs_Array); obst0(n, :) = []; end
            continue;
        end

        if length(Line)>72 && all(Line(61:73) == single(('END OF HEADER')'))
            for i = 1 : size(obst0, 1)
                for j = 1 : size(obst0{i, 1}, 1)
                    obs.(obst0{i, 2}).(char(obst0{i, 1}(j,:))) = zeros(Epoch_Num, obst0{i, 5});
                end
            end
            Obs_GNSS = vertcat(obst0{:, 2});
            obst0(cellfun(@isempty , obst0(: , 2)) , :) = [];
            if ~any(cellfun(@(x) any(x), obst0(:, 3))); return; end

            while 1
                l = l + 1;
                if l > numel(Start_Idx); return; end
                Line = Data(Start_Idx(l) : End_Idx(l));

                if Line(1) == 62 && ~all(Line(3:21) == 32)
                    Time = Line(14:29) - 48;
                    Time(Time < 0 | Time > 9) = 0;
                    ep = Ex_Time * Time_Array * Time + 1;
                else
                    continue
                end

                nsat = Line(34:35) - 48;
                nsat(nsat > 9 | nsat < 0) = 0;
                nsat = [10, 1] * nsat;
                if ep ~= fix(ep); l = l + nsat; continue; end

                for i = 1 : nsat
                    l = l + 1;
                    if l>length(Start_Idx); return; end
                    Line = Data(Start_Idx(l) : End_Idx(l));

                    if numel(Line) < 3; continue; end % 防止行太短报错
                    sat_type = char(Line(1));

                    % --- 修改开始：增加了对空格的处理 ---
                    prn_vec = Line(2:3) - 48;
                    prn_vec(prn_vec < 0 | prn_vec > 9) = 0; % 将空格(-16)变成0
                    sat_prn = [10, 1] * prn_vec;
                    % --- 修改结束 ---

                    % 错误行跳过 (增加 <= 0 判断)
                    if sat_prn <= 0
                        continue
                    end

                    Sat_Type_Ind = find(sat_type == Obs_GNSS, 1);
                    if isempty(Sat_Type_Ind) || sat_prn > obst0{Sat_Type_Ind, 5}
                        continue
                    end

                    Ex_Array = obst0{Sat_Type_Ind, 4};
                    Line_Asc = Line(4:end) - 48;

                    % 保留原始副本用于检测 LLI (-16表示空格)
                    Line_Raw = Line_Asc;

                    Line_Asc(Line_Asc < 0 | Line_Asc > 9) = 0;
                    if size(Ex_Array, 2) > numel(Line_Asc)
                        Ex_Array(:, numel(Line_Asc)+1 : end) = [];
                    elseif size(Ex_Array, 2) < numel(Line_Asc)
                        Line_Asc(size(Ex_Array, 2)+1 : end) = [];
                    end

                    Current_Obs = round(Ex_Array * Line_Asc, 3); % 强制3位小数
                    Data_Name = obst0{Sat_Type_Ind, 1};
                    loc = obst0{Sat_Type_Ind, 3};

                    for j = 1 : size(Data_Name, 1)
                        % === LLI 过滤 ===
                        lli_idx = (loc(j)-1)*16 + 15;
                        lli_val = 0;
                        if lli_idx <= numel(Line_Raw)
                            lli_val = Line_Raw(lli_idx);
                        else
                            lli_val = -16;
                        end
                        if lli_val ~= 0 && lli_val ~= -16
                            Current_Obs(j) = 0;
                        end
                        obs.(sat_type).(Data_Name{j})(ep, sat_prn) = Current_Obs(j);
                    end
                end
            end
        end
    end
end
end