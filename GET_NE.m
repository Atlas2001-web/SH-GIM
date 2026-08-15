function GET_NE(Start_Time, End_Time, TimeResolution, Site_Folder, ...
    P4_Folder, Sp3_Folder, GNSS_Choose, Code_Group, Add_FigNum, R, Height, ...
    sub_mat_Folder, currentPath, SH_Folder, sh_order, Cutoff_Ele)

Lat_Res = 2.5;
Lon_Res = 5;
Ionex_Folder = fullfile(currentPath, 'DATA', 'OUTPUT', 'Ionex');

for T = Start_Time : End_Time
    fprintf('Processing SH model %s\n', datestr(T));
    [Sites_Info, Sate_Coor] = load_solver_context(T, Site_Folder, Sp3_Folder);

    Get_SHBackground(T, Sites_Info, Sate_Coor, Add_FigNum, sh_order, ...
        TimeResolution, P4_Folder, SH_Folder, GNSS_Choose, Code_Group, ...
        R, Height, sub_mat_Folder)
    GET_I_SH(T, SH_Folder, sh_order, TimeResolution, Lat_Res, Lon_Res, ...
        Ionex_Folder, Cutoff_Ele, R, Height)

    DEL_temp(currentPath, T, End_Time)
end
end

function [Sites_Info, Sate_Coor] = load_solver_context(T, Site_Folder, Sp3_Folder)
sate_cell = cell(3, 1);
for i = -1 : 1
    Current_Time = T + days(i);
    Sp3_File = sprintf('%d%03dsp3.mat', year(Current_Time), day2doy(Current_Time));
    Sp3_File = fullfile(Sp3_Folder, Sp3_File);
    temp_sp3 = load(Sp3_File, 'sate');
    sate_cell{i + 2} = temp_sp3.sate;
end

sate_field = cellfun(@fieldnames, sate_cell, 'UniformOutput', false);
sate_field_num = cellfun(@numel, sate_field);
if numel(unique(sate_field_num)) > 1
    error('Satellite ephemeris is incomplete.');
end

sate_field = sate_field{1};
for i = 1 : numel(sate_field)
    field_name = sate_field{i};
    Sate_Coor.(field_name).x = cellfun(@(x) x.(field_name).x, sate_cell, ...
        'UniformOutput', false);
    Sate_Coor.(field_name).x = vertcat(Sate_Coor.(field_name).x{:});
    Sate_Coor.(field_name).y = cellfun(@(x) x.(field_name).y, sate_cell, ...
        'UniformOutput', false);
    Sate_Coor.(field_name).y = vertcat(Sate_Coor.(field_name).y{:});
    Sate_Coor.(field_name).z = cellfun(@(x) x.(field_name).z, sate_cell, ...
        'UniformOutput', false);
    Sate_Coor.(field_name).z = vertcat(Sate_Coor.(field_name).z{:});
end

Site_File = sprintf('Sites_Info_%02d%03d.mat', Get_yearLastTwo(T), day2doy(T));
Site_File = fullfile(Site_Folder, Site_File);
temp_site = load(Site_File, 'Sites_Info');
Sites_Info = temp_site.Sites_Info;
end
