function GET_I_SH(T, SH_Folder, order, TimeResolution, Lat_Res, Lon_Res, ...
    Ionex_Folder, Cutoff_Ele, R, Height)

if exist(Ionex_Folder, 'dir') == 0
    mkdir(Ionex_Folder)
end

Western_Edge = -180;
Eastern_Edge = 180;
Nothern_Edge = 87.5;
Southern_Edge = -87.5;

[Lon, Lat] = meshgrid(Western_Edge:Lon_Res:Eastern_Edge, ...
    Nothern_Edge:-Lat_Res:Southern_Edge);
Data_Size = size(Lon);
Lon = reshape(Lon, [], 1);
Lat = reshape(Lat, [], 1);

File_Name = sprintf('SH_%02d%03d.mat', Get_yearLastTwo(T), day2doy(T));
File_Name = fullfile(SH_Folder, File_Name);
temp_sh = load(File_Name, 'SHC', 'DCB_S', 'DCB_R', 'order');
SHC = temp_sh.SHC;
DCB_S = temp_sh.DCB_S;
DCB_R = temp_sh.DCB_R;

if nargin >= 3 && ~isempty(order) && temp_sh.order ~= order
    error('GET_I_SH:OrderMismatch', ...
        'Solution order %d does not match expected order %d.', ...
        temp_sh.order, order);
end

available_vars = who('-file', File_Name);
if any(strcmp(available_vars, 'D'))
    temp_cov = load(File_Name, 'D');
    D = temp_cov.D;
elseif any(strcmp(available_vars, 'D_diag'))
    temp_cov = load(File_Name, 'D_diag');
    D = temp_cov.D_diag;
else
    warning('GET_I_SH:MissingCovariance', ...
        'File %s is missing covariance. RMS is set to zero.', File_Name);
    D = sparse(numel(SHC), numel(SHC));
end

Time = 0 : TimeResolution : 24;
sig_time = TimeResolution * 3600;
FigNum = numel(Time);
Single_SHCofNum = (temp_sh.order + 1) ^ 2;

if fix(numel(SHC) / FigNum) ~= numel(SHC) / FigNum || ...
        numel(SHC) / FigNum ~= Single_SHCofNum
    error('GET_I_SH:InvalidCoefficientCount', ...
        'The spherical-harmonic coefficient count is inconsistent with the requested time resolution.');
end

GIMs.VTEC = zeros(Data_Size(1), Data_Size(2), FigNum);
GIMs.RMS = zeros(Data_Size(1), Data_Size(2), FigNum);

for i = 1 : FigNum
    Current_Time = Time(i);
    Idx = Single_SHCofNum * (i - 1) + 1 : Single_SHCofNum * i;
    Current_ION = SHC(Idx);
    Current_D = slice_layer_covariance(D, Idx);

    [VTEC, RMS] = Get_SH_VTEC(Current_ION, Lat, Lon, Current_Time, Current_D);
    GIMs.VTEC(:, :, i) = reshape(VTEC, Data_Size);
    GIMs.RMS(:, :, i) = reshape(RMS, Data_Size);
end

Ionex_File_Name = sprintf('srim%03d0.%02di', day2doy(T), mod(year(T), 100));
Ionex_File_Name = fullfile(Ionex_Folder, Ionex_File_Name);
Write_Ionex(Ionex_File_Name, GIMs, DCB_S, DCB_R, T, sig_time, FigNum, ...
    Cutoff_Ele, Lat_Res, Lon_Res, R, Height, Western_Edge, Eastern_Edge, ...
    Nothern_Edge, Southern_Edge)
end

function Current_D = slice_layer_covariance(D, Idx)
if isvector(D)
    Current_D = D(Idx);
else
    Current_D = D(Idx, Idx);
end
end
