% Step3 函数：数据预处理及平滑伪距计算
% ========================================================================
% 功能：对观测数据进行截止高度角筛选、周跳探测，并计算相位平滑伪距观测值 (P4)
% 输入参数：
%   Start_Time  - 处理开始时间 (datetime)
%   End_Time    - 处理结束时间 (datetime)
%   Obs_Folder  - 原始观测数据文件夹路径 (字符串)
%   Sp3_Folder  - 精密星历 (SP3) 文件夹路径 (字符串)
%   Site_Folder - 测站信息文件夹路径 (字符串)
%   P4_Folder   - 平滑伪距输出文件夹路径 (字符串)
%   Cutoff_Ele  - 截止高度角 (单位：度)
%   GNSS_Choose - 选择参与计算的GNSS系统及其类型 (元胞数组)
%   Code_Group  - 每个GNSS系统对应的观测码组合 (结构体)
% 输出：
%   在 P4_Folder 中生成按年月日子文件夹分类的 P4.mat 文件。

function GET_PP4(Start_Time, End_Time, Obs_Folder, Sp3_Folder, Site_Folder, P4_Folder, Cutoff_Ele, ...
    GNSS_Choose, Code_Group,sub_mat_Folder,currentPath, UsePadding)

    % 解包 GNSS 系统类型和选择标志
    [GNSS_Type, GNSS_Choose] = GNSS_Choose{:};

    if nargin < 12 || isempty(UsePadding)
        UsePadding = true;
    end

    % ------------------------------------------------------------------------
    % 1. 加载卫星频率信息 (GNSS_frequency_band.mat)
    load(fullfile(sub_mat_Folder,'GNSS_frequency_band.mat'), 'GNSS_Frequency')  % 读取各系统各频点频率

    % 2. 加载卫星数量信息 (Sat_Info.mat)，用于检查频点数量是否与卫星数量一致
    load(fullfile(sub_mat_Folder,'Sat_Info.mat'), 'Sat_Num')
    Sat_Num_GLONASS = Sat_Num.R;  % GLONASS 卫星数量
    Frequency_GLONASS_F1 = GNSS_Frequency.R.F1;
    Frequency_GLONASS_F2 = GNSS_Frequency.R.F2;
    F1_Len = length(Frequency_GLONASS_F1);
    F2_Len = length(Frequency_GLONASS_F2);

    % 根据卫星数量修整频率向量，确保后续处理不出错
    if F1_Len > Sat_Num_GLONASS || F2_Len > Sat_Num_GLONASS
        GNSS_Frequency.R.F1 = GNSS_Frequency.R.F1(1 : Sat_Num_GLONASS);
        GNSS_Frequency.R.F2 = GNSS_Frequency.R.F2(1 : Sat_Num_GLONASS);
    elseif F1_Len < Sat_Num_GLONASS || F2_Len < Sat_Num_GLONASS
        error('GLONASS频率信息不全，需要对文件.\GNSS_frequency_band.mat进行修改')
    end

    % ------------------------------------------------------------------------
    % 3. 按天循环处理：Start_Time - 1 日 到 End_Time + 1 日，以保证跨日数据也被处理
    if UsePadding
        Process_Start = Start_Time - days(1);
        Process_End = End_Time + days(1);
    else
        Process_Start = Start_Time;
        Process_End = End_Time;
    end

    for T = Process_Start : Process_End
        % 构造当前日期的 DOY (day-of-year) 字符串, 格式例如："25036" 表示2025年第36天
        Current_Date = sprintf('%02d%03d', Get_yearLastTwo(T), day2doy(T));
        Current_Folder = sprintf('%s\\%02d%03d', P4_Folder, Get_yearLastTwo(T), day2doy(T));
        if exist(Current_Folder, 'dir') == 0
            mkdir(Current_Folder);
        end
        Ready_File = fullfile(Current_Folder, 'p4_ready.flag');
        if exist(Ready_File, 'file')
            fprintf('P4 %s 已存在，跳过预处理\n', string(T, 'uuuu-MM-dd'));
            continue
        end
        % 当前观测数据文件夹路径
        Current_Obs_Path = fullfile(Obs_Folder, Current_Date);

        % 加载测站信息：Sites_Info 包含站点名称与坐标
        Site_File = sprintf('Sites_Info_%02d%03d.mat', Get_yearLastTwo(T), day2doy(T));
        Site_File_Path = fullfile(Site_Folder, Site_File);
        load(Site_File_Path, "Sites_Info");

        % 加载精密星历 SP3 文件 (sate 结构体)
        Sp3_File = sprintf('%d%03dsp3.mat', year(T), day2doy(T));
        Sp3_File_Path = fullfile(Sp3_Folder, Sp3_File);
        load(Sp3_File_Path, 'sate');

        fprintf('正在对 %s 的数据进行预处理...\n', string(T, 'uuuu-MM-dd'));

        % 获取该日所有观测文件列表，例如"ABCD25036.mat"
        File_List = dir(fullfile(Current_Obs_Path, ['????', Current_Date, '.mat']));
        File_Nums = numel(File_List);
        count = 0;  % 用于动态刷新命令行输出长度

        % --------------------------------------------------------------------
        % 4. 对当天每个测站的观测文件进行处理
        for i = 1 : File_Nums
            P4 = struct();  % 初始化 P4 结构体，用于存储不同系统的平滑伪距
            Current_File_Path = fullfile(File_List(i).folder, File_List(i).name);
            load(Current_File_Path, 'obs');  % 读取观测值 obs 结构体

            % 获取测站名称及其坐标
            Site_Name = File_List(i).name(1:4);
            Idx = strcmpi(Site_Name, Sites_Info.name);
            Site_Coor = Sites_Info.coor(Idx, :);
            if isempty(Site_Coor)||all(Site_Coor==0)
                continue;
            end
            % 5. 遍历每个选中的 GNSS 系统进行 P4 计算
            for j = 1 : numel(GNSS_Choose)
                % 跳过未选中色标或无此系统观测数据的情况
                if ~GNSS_Choose(j) || ~isfield(obs, GNSS_Type(j))
                    continue;
                end

                Current_Obs = obs.(GNSS_Type(j));       % 当前系统的观测数据
                Expect_Code = Code_Group.(GNSS_Type(j));% 预期的码型组合
                Sate_Coor = sate.(GNSS_Type(j));        % 卫星坐标
                Current_Fre = GNSS_Frequency.(GNSS_Type(j)); % 当前系统频率

                % 遍历所有期望的码型组合 (如 L1+C1, L2+C2 等)
                for k = 1 : size(Expect_Code, 1)
                    [F1, F2] = Expect_Code{k, :};

                    % 生成频率名称并提取具体频率值
                    F1_Name = ['F', F1(1)];
                    F2_Name = ['F', F2(1)];
                    F1_Fre = Current_Fre.(F1_Name);
                    F2_Fre = Current_Fre.(F2_Name);

                    % 生成观测量字段名 (相位 L?, 码长 C?)
                    L1 = ['L', F1];  P1 = ['C', F1];
                    L2 = ['L', F2];  P2 = ['C', F2];
                    L1_R2 = 'L1';   L2_R2 = 'L2';  % 备用名称

                    % 根据字段名判断 obs 中是否包含所需观测量
                    if all(isfield(Current_Obs, {L1, L2, P1, P2}))
                        Input_Obs.L1 = Current_Obs.(L1);
                        Input_Obs.L2 = Current_Obs.(L2);
                        Input_Obs.P1 = Current_Obs.(P1);
                        Input_Obs.P2 = Current_Obs.(P2);
                    elseif all(isfield(Current_Obs, {L1_R2, L2_R2, P1, P2}))
                        Input_Obs.L1 = Current_Obs.(L1_R2);
                        Input_Obs.L2 = Current_Obs.(L2_R2);
                        Input_Obs.P1 = Current_Obs.(P1);
                        Input_Obs.P2 = Current_Obs.(P2);
                    else
                        continue;  % 跳过缺少观测量的组合
                    end
                    if size(Input_Obs.L1,2)<size(Sate_Coor.x,2)
                        Sate_Coor.x(:,size(Input_Obs.L1,2)+1:end)=[];
                        Sate_Coor.y(:,size(Input_Obs.L1,2)+1:end)=[];
                        Sate_Coor.z(:,size(Input_Obs.L1,2)+1:end)=[];
                    end
                    % 调用自定义函数 Get_P4：进行截止角筛选、周跳探测，并输出 P4
                    P4_GNSS = Get_P4(Input_Obs, Site_Coor, Sate_Coor, Cutoff_Ele, F1_Fre, F2_Fre);
                    if ~isempty(P4_GNSS)
                        P4.(GNSS_Type(j)).([P1, P2]) = P4_GNSS;  % 保存到 P4 结构体中
                    end
                end  % End of Code_Group loop
            end  % End of GNSS_Choose loop

            % 如果 P4 结构体为空，则跳过并在命令行提示
            if isempty(fieldnames(P4))
                str = sprintf('%s 为空', File_List(i).name);
                disp([repmat(char(8), 1, count), str]);
                count = 0;
                continue;
            end

            % 保存 P4 结果：按日期子文件夹组织
            File_Path = fullfile(Current_Folder, [Site_Name, 'P4.mat']);
            save(File_Path, 'P4');

            % 更新命令行进度提示
            str = sprintf('已处理 %d 个站点 (%d)', i, File_Nums);
            disp([repmat(char(8), 1, count), str]);
            count = length(str) + 1;
        end  % End of stations loop
        fid = fopen(Ready_File, 'w');
        fclose(fid);
    end  % End of date loop
%删除前面所有的观测文件

end  % End of function Step3
