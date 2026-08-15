function Step2(Start_Time, End_Time, Input_Folder, Output_Folder, Site_Folder, GNSS_Choose, Code_Group,sub_mat_Folder, UsePadding)
% 三天解，因此需要读取开始时间前一天和结束时间后一天的数据

if nargin < 9 || isempty(UsePadding)
    UsePadding = true;
end

if exist(Site_Folder, 'dir') == 0
    mkdir(Site_Folder)
end

% 获取需求的观测值类型
GNSS = fieldnames(Code_Group);
Obs_Type.Rinex2 = {};
conver_strcut=fullfile(sub_mat_Folder,'Conversion_Struct.mat');
load(conver_strcut, 'Obs_Type_Conversion')
for i = 1 : numel(GNSS)
    Code = unique(Code_Group.(GNSS{i}));
    Obs_Type.Rinex3.(GNSS{i}) = [cellfun(@(x) ['C', x], Code, 'UniformOutput', false);
        cellfun(@(x) ['L', x], Code, 'UniformOutput', false)];

    for j = 1 : numel(Code)
        Current_Obs_Type = [GNSS{i}, Code{j}];
        if ~isfield(Obs_Type_Conversion.R3toR2, Current_Obs_Type)
            continue
        end
        [Code_R2, Phase_R2] = Obs_Type_Conversion.R3toR2(:).(Current_Obs_Type);

        if ~ismember(Code_R2, Obs_Type.Rinex2)
            Obs_Type.Rinex2 = [Obs_Type.Rinex2, Code_R2];
        end
        if ~ismember(Phase_R2, Obs_Type.Rinex2)
            Obs_Type.Rinex2 = [Obs_Type.Rinex2, Phase_R2];
        end
    end
end

% 读取根据星历文件获取的卫星数量
load([sub_mat_Folder '/Sat_Info.mat'], 'Sat_Num')

if UsePadding
    Process_Start = Start_Time - days(1);
    Process_End = End_Time + days(1);
else
    Process_Start = Start_Time;
    Process_End = End_Time;
end

for T = Process_Start : Process_End
    Current_Folder = sprintf('%d\\%03d\\', year(T), day2doy(T));
    Current_Folder = fullfile(Input_Folder, Current_Folder);

    List = [dir(fullfile(Current_Folder, '*.*o'));
        dir(fullfile(Current_Folder, '*.rnx'))];
    len = numel(List);

    if isempty(List) && (T == Start_Time - days(1) || T == End_Time + days(1))
        error('三天解缺少数据')
    elseif isempty(List)
        error('文件夹为空')
    end

    doy = sprintf('%02d%03d', Get_yearLastTwo(T), day2doy(T));

    Storage_Folder = fullfile(Output_Folder, doy);
    if exist(Storage_Folder, 'dir') == 0
        mkdir(Storage_Folder)
    end
    Ready_File = fullfile(Storage_Folder, 'obs_ready.flag');
    Site_Info_File = fullfile(Site_Folder, ['Sites_Info_', doy, '.mat']);
    if exist(Ready_File, 'file') && exist(Site_Info_File, 'file')
        fprintf('观测值 %s 已存在，跳过读取\n', string(T, 'uuuu-MM-dd'));
        continue
    end
    % ---------------------------------------------------------------------
    Coor = zeros(len, 3);
    name = cell(len, 1);

    % 创建进度条
    String = sprintf('正在读取%s的Rinex文件', string(T, 'uuuu-MM-dd'));
    parfor_progress(len, String);
    parfor (i = 1 : len)%117
        obsn = List(i).name;
        Current_File = fullfile(List(i).folder, obsn);
        File_Name = [lower(obsn(1:4)), doy];
        File_Path = fullfile(Storage_Folder, File_Name);
        coor = Read_Station(Current_File, GNSS_Choose, ...
            File_Path, Obs_Type_Conversion, Sat_Num, Obs_Type);

        Coor(i, :) = coor;
        name{i} = lower(obsn(1:4));

        parfor_progress;
    end
    % 删除进度条
    parfor_progress(0);

    idx = find(~any(Coor, 2));
    Coor(idx,:)=[];
    name(idx,:)=[];
    Sites_Info.coor = Coor;
    Sites_Info.name = name;



    save(Site_Info_File, 'Sites_Info')
    fid = fopen(Ready_File, 'w');
    fclose(fid);

end

end

function coor = Read_Station(Current_File, GNSS_Choose, ...
    File_Path, Obs_Type_Conversion, Sat_Num, Obs_Type)

[obs, coor, Rinex_Version] = Read_Rinex_Ver2(Current_File, GNSS_Choose, Obs_Type, 0, 30, Sat_Num);
% [obs, coor] = Read_Rinex(Current_File, GNSS_Choose, Obs_Type, 0, 30, Sat_Num);
if isempty(obs)|| all(coor == 0)
    return
end

% 转换Rinex2数据的观测值名称
if Rinex_Version < 3
    % 删除Rinex2数据中除了GPS和GLONASS的数据
    Obs_GNSS = fieldnames(obs);
    for i = 1 : length(Obs_GNSS)
        if all(Obs_GNSS{i} ~= 'GR')
            obs = rmfield(obs, Obs_GNSS{i});
        end
    end

    % 重新命名Rinex2数据中的观测值类型
    GNSS = fieldnames(obs);
    for i = 1 : numel(GNSS)
        Code = fieldnames(obs.(GNSS{i}));
        for j = 1 : numel(Code)
            New_Code_Name = Obs_Type_Conversion.R2toR3.([GNSS{i}, Code{j}]);
            if strcmp(New_Code_Name, Code{j})
                continue
            end
            obs.(GNSS{i}).(New_Code_Name) = obs.(GNSS{i}).(Code{j});
            obs.(GNSS{i}) = rmfield(obs.(GNSS{i}), Code{j});
        end
    end
end

% 删除没有数据的频段
obs = Delete_Empty_Data(obs);

save(File_Path, 'obs')
end

function obs = Delete_Empty_Data(obs)
GNSS = fieldnames(obs);
for i = 1 : length(GNSS)
    obs_GNSS = obs.(GNSS{i});
    Code = fieldnames(obs_GNSS);

    for j = 1 : length(Code)
        if all(obs_GNSS.(Code{j}) == 0, 'all')
            obs.(GNSS{i}) = rmfield(obs.(GNSS{i}), Code{j});
        end
    end
end

end


