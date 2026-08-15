% Step1 函数：读取精密星历并插值生成 30s 轨道数据
% ========================================================================
% 功能：读取指定时间段内的精密星历 (SP3 文件)，
%      通过拉格朗日或线性插值方法生成 30 秒分辨率的卫星轨道坐标并保存。
% 输入参数：
%   Start_Time    - 处理开始时间 (datetime)
%   End_Time      - 处理结束时间 (datetime)
%   Input_Folder  - 原始 SP3 文件根文件夹路径 (字符串)，按年/年-日 序组织
%   Output_Folder - 插值后 SP3 结果输出文件夹路径 (字符串)
%   IAACs         - 精密星历文件命名信息，如{'IGS','_ORB'} (元胞数组)
%   GNSS_Choose   - 要处理的 GNSS 系统及其标志 (元胞数组)，如{{'GPS','BDS','GAL'},{1,0,1}}
% 输出：
%   在 Output_Folder 中生成以日期命名的带插值轨道数据 (.sp3.mat) 文件，
%   同时在当前目录生成或更新 Sat_Info.mat，包含各系统最大卫星数。

function Step1(Start_Time, End_Time, Input_Folder, Output_Folder, IAACs, GNSS_Choose,sub_mat_Folder)
    % 解包 GNSS 系统名称与处理标志
    [GNSS, GNSS_Choose] = GNSS_Choose{:};

    % 如果输出文件夹不存在，则创建之
    if exist(Output_Folder, 'dir') == 0
        mkdir(Output_Folder);
    end

    % ------------------------------------------------------------------------
    % 1. 主循环：对每个处理日期，从前一天到后一天，保证插值区间完整
    for T = Start_Time - days(1) : End_Time + days(1)
        sate = struct();  % 初始化当天的插值轨道结果
        Data = cell(3, 1);  % 存储前一天、当天、后一天的 SP3 数据

        % --------------------------------------------------------------------
        % 2. 读取三天 SP3 文件：前一天、当天、后一天
        for i = -1 : 1
            Current_T = T + days(i);
            % 构造 SP3 文件所在文件夹：年\年-日\
            Current_Folder = fullfile(Input_Folder, sprintf('%02d', year(Current_T)), sprintf('%03d', day2doy(Current_T)));
            % 匹配文件名，如 IGS????_ORB*.SP3
            List = dir(fullfile(Current_Folder, [IAACs{1}, '????', IAACs{2}, '*.SP3']));
            if isempty(List)
                error('缺少 %s 的 %s %s 精密星历文件', string(Current_T,'uuuu-MM-dd'), IAACs{1}, IAACs{2});
            end
            Current_File = fullfile(List.folder, List.name);
            % 调用子函数 Read_Sp3，返回轨道数据结构和当日卫星数量
            [Data{i+2,1}, Current_Sat_Num] = Read_Sp3(Current_File);

            if  isfield(Current_Sat_Num, 'R')
                if Current_Sat_Num.R>24
                    Current_Sat_Num.R=24;
                    Data{i+2,1}.R.x(:,25:end)=[];
                    Data{i+2,1}.R.y(:,25:end)=[];
                    Data{i+2,1}.R.z(:,25:end)=[];
                end
            end
            % 汇总三天内各系统的卫星数量，后续取最大值用于插值矩阵初始化
            if ~exist('Sat_Num0','var')
                Sat_Num0 = Current_Sat_Num;
            else
                try
                    Sat_Num0 = [Sat_Num0, Current_Sat_Num];
                catch
                    % 如果字段不一致，则只保留共有字段
                    Field_Name = fieldnames(Current_Sat_Num);
                    for k = 1:numel(Field_Name)
                        if ~isfield(Sat_Num0, Field_Name{k})
                            Current_Sat_Num = rmfield(Current_Sat_Num, Field_Name{k});
                        end
                    end
                    Sat_Num0 = [Sat_Num0, Current_Sat_Num];
                end
            end
        end

        % --------------------------------------------------------------------
        % 3. 对每个选中的 GNSS 系统，进行轨道插值
        for i = 1 : numel(GNSS_Choose)
            if GNSS_Choose(i)
                % 提取三天原始轨道坐标
                x1 = Data{1}.(GNSS(i)).x;  y1 = Data{1}.(GNSS(i)).y;  z1 = Data{1}.(GNSS(i)).z;
                x2 = Data{2}.(GNSS(i)).x;  y2 = Data{2}.(GNSS(i)).y;  z2 = Data{2}.(GNSS(i)).z;
                x3 = Data{3}.(GNSS(i)).x;  y3 = Data{3}.(GNSS(i)).y;  z3 = Data{3}.(GNSS(i)).z;

                % 如果样本点个数不能整除 86400s，则去掉最后一个多余点
                if fix(86400/size(x1,1)) ~= 86400/size(x1,1)
                    x1 = x1(1:end-1,:); y1 = y1(1:end-1,:); z1 = z1(1:end-1,:);
                    x2 = x2(1:end-1,:); y2 = y2(1:end-1,:); z2 = z2(1:end-1,:);
                    x3 = x3(1:end-1,:); y3 = y3(1:end-1,:); z3 = z3(1:end-1,:);
                end

                % 动态确定最大卫星数，初始化插值网格
                numgps = max([size(x1,2), size(x2,2), size(x3,2)]);

                % 调用子函数 interpolation，生成 30s 分辨率插值结果
                [sate.(GNSS(i)).x, sate.(GNSS(i)).y, sate.(GNSS(i)).z] = ...
                    interpolation(numgps, x1, y1, z1, x2, y2, z2, x3, y3, z3);
            end
        end

        % --------------------------------------------------------------------
        % 4. 保存当天插值结果：文件名格式 'YYYYDDDs p3'
        File_Name = sprintf('%ssp3', string(T,'uuuuDDD'));
        File_path = fullfile(Output_Folder, File_Name);
        save(File_path, 'sate');
        fprintf('%s 的精密星历插值完成 (结束日期 %s)\n', string(T,'uuuu-MM-dd'), string(End_Time+days(1),'uuuu-MM-dd'));
    end

    % ------------------------------------------------------------------------
    % 5. 汇总三天内最大卫星数，保存到 Sat_Info.mat 以供后续函数使用
    Field = fieldnames(Sat_Num0);
    for i = 1 : numel(Field)
        Sat_Num.(Field{i}) = max([Sat_Num0(:).(Field{i})]);
    end
    save([sub_mat_Folder '/Sat_Info.mat'], 'Sat_Num');
end

%---------------- subfunction: 插值函数 -------------------------------------
function [interp_x2, interp_y2, interp_z2] = interpolation(sat_n, x1, y1, z1, x2, y2, z2, x3, y3, z3, interp_method)
    % 功能：对三天轨道坐标进行插值，返回 2880 个 30s 采样点
    % 输入：sat_n - 卫星数量；x1,y1,z1 - 前一天坐标；x2,y2,z2 - 当天；x3,y3,z3 - 后一天
    % interp_method: 'lagrange' (默认) 或其他（调用 interp1）
    if nargin < 11
        interp_method = 'lagrange';
    end
    epoch_num      = size(x1,1);  % 原始历元数量
    epoch_interval = 24*60*60/epoch_num;  % 历元间隔 (秒)

    % 确保三天数据矩阵列数一致，缺失用 0 填充
    padMatrix = @(M) padarray(M, [0, sat_n-size(M,2)], 0, 'post');
    x1 = padMatrix(x1); y1 = padMatrix(y1); z1 = padMatrix(z1);
    x2 = padMatrix(x2); y2 = padMatrix(y2); z2 = padMatrix(z2);
    x3 = padMatrix(x3); y3 = padMatrix(y3); z3 = padMatrix(z3);

    % 初始化插值结果矩阵：2880 × sat_n
    interp_x2 = zeros(2880, sat_n);
    interp_y2 = zeros(2880, sat_n);
    interp_z2 = zeros(2880, sat_n);

    % 为边界插值准备：在数据前后各添加 4 个历元
    x2 = [x1(end-3:end,:); x2; x3(1:5,:)];
    y2 = [y1(end-3:end,:); y2; y3(1:5,:)];
    z2 = [z1(end-3:end,:); z2; z3(1:5,:)];
    m_t = -epoch_interval*4/30 : epoch_interval/30 : 2880 + epoch_interval*4/30;  % 原始时间点

    % 根据 interpolation_method 选择插值方式
    if ~strcmp(interp_method, 'lagrange')
        all_epoch = 0:2879;
        interp_x2 = interp1(m_t, x2, all_epoch);
        interp_y2 = interp1(m_t, y2, all_epoch);
        interp_z2 = interp1(m_t, z2, all_epoch);
    else
        % 拉格朗日插值：10 点滑动窗口逐段插值
        for satIdx = 1:sat_n
            for j = 1:epoch_num
                % 取 10 个点进行插值
                tt = m_t(j:j+9);
                x = x2(j:j+9, satIdx)';  y = y2(j:j+9, satIdx)';  z = z2(j:j+9, satIdx)';
                interp_epoch_num = epoch_interval/30;
                t0 = linspace(m_t(j+4), m_t(j+5)-1, interp_epoch_num);
                interp_x2((interp_epoch_num*j-interp_epoch_num+1):interp_epoch_num*j, satIdx) = interp_lag(tt, x, t0)';
                interp_y2((interp_epoch_num*j-interp_epoch_num+1):interp_epoch_num*j, satIdx) = interp_lag(tt, y, t0)';
                interp_z2((interp_epoch_num*j-interp_epoch_num+1):interp_epoch_num*j, satIdx) = interp_lag(tt, z, t0)';
            end
        end
    end
end

%---------------- subfunction: 拉格朗日插值 ----------------------------------
function y0 = interp_lag(x, y, x0)
    % 功能：基于输入点 (x,y)，在新点 x0 上进行拉格朗日插值
    n = length(x);
    y0 = zeros(size(x0));
    for k = 1:n
        Lk = ones(size(x0));
        for i = 1:n
            if i ~= k
                Lk = Lk .* (x0 - x(i)) / (x(k) - x(i));
            end
        end
        y0 = y0 + Lk * y(k);
    end
end