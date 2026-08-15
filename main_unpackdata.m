function main_unpackdata(Ini_Switch, Step1_Switch, Step2_Switch, Step3_Switch, ...
    Step4_Switch)
clc;
dbstop if error;

sh_order = 15;                     % Spherical-harmonic order
TimeResolution = 1;                % Hours
Add_FigNum = 2;                    % Extra epochs for time continuity

unpackg = 1;
if nargin < 1
    Ini_Switch = 0;
    Step1_Switch = 1;
    Step2_Switch = 1;
    Step3_Switch = 1;
    Step4_Switch = 1;
end

Start_Time = datetime([2019, 1, 1]);
End_Time = datetime([2024, 1, 1]);
GNSS_Choose = {'GREC', [1, 1, 1, 1]};

Code_Group.G = {'1C', '2W'; '1C', '5X'};
Code_Group.R = {'1C', '2C'};
Code_Group.E = {'1X', '5X'; '1C', '5Q'};
Code_Group.C = {'2I', '7I'};

currentPath = pwd;
addpath(fullfile(currentPath, 'functions'));
addpath(fullfile(currentPath, 'sub_functions'));

Sp3File_Input_Folder = fullfile(currentPath, 'DATA', 'INPUT', 'SP3');
Sp3File_Output_Folder = fullfile(currentPath, 'DATA', 'OUTPUT', 'SP3_OUT');
Sp3_IAACs = {'COD', 'FIN'};
Ofile_Input_Folder = fullfile(currentPath, 'DATA', 'INPUT', 'obs');
Ofile_Output_Folder = fullfile(currentPath, 'DATA', 'OUTPUT', 'OBS_OUT');
Site_Folder = fullfile(currentPath, 'DATA', 'OUTPUT', 'Site_Info');
sub_mat_Folder = fullfile(currentPath, 'DATA', 'sub_mat');
P4_Folder = fullfile(currentPath, 'DATA', 'OUTPUT', 'P4');
SH_Folder = fullfile(currentPath, 'DATA', 'OUTPUT', 'SH_Coefficients');

R = 6371000;
Height = 506700;
Cutoff_Ele = 10;

if Add_FigNum > 24 / TimeResolution
    error('Add_FigNum cannot exceed %d.', 24 / TimeResolution);
end

packFilePath = 'D:\GNSS_Obs\GNSS-OBS';
stations_txt = 'E:\matlab\dowload2\stations_350.txt';
unpack_outdir = 'D:\GNSS_Obs\GNSS-OBS\unpack';

if Ini_Switch
    Initialize_Folder(Ofile_Output_Folder, Start_Time, End_Time, 'obs')
    Initialize_SP3(Sp3File_Output_Folder, Start_Time, End_Time, 'sp3')
    Initialize_SP3(Site_Folder, Start_Time, End_Time, 'site_info')
    Initialize_Folder(P4_Folder, Start_Time, End_Time, 'P4')
end

if Step1_Switch
    Step1(Start_Time, End_Time, Sp3File_Input_Folder, Sp3File_Output_Folder, ...
        Sp3_IAACs, GNSS_Choose, sub_mat_Folder)
end

for T = Start_Time : End_Time
    if unpackg == 1 && Step2_Switch
        tic;
        unpack_obs(packFilePath, stations_txt, Ofile_Input_Folder, unpack_outdir, T)
        fprintf('unpack_obs elapsed %.2f s\n', toc);
    end

    if Step2_Switch
        if isempty(gcp('nocreate'))
            parpool('local', feature('numCores'));
        end

        Step2(T, T, Ofile_Input_Folder, Ofile_Output_Folder, Site_Folder, ...
            GNSS_Choose, Code_Group, sub_mat_Folder)
    end

    if Step3_Switch
        GET_PP4(T, T, Ofile_Output_Folder, Sp3File_Output_Folder, Site_Folder, ...
            P4_Folder, Cutoff_Ele, GNSS_Choose, Code_Group, sub_mat_Folder, ...
            currentPath)
    end
end

if Step4_Switch
    if isempty(gcp('nocreate'))
        parpool('local', 16);
    end

    GET_NE(Start_Time, End_Time, TimeResolution, Site_Folder, P4_Folder, ...
        Sp3File_Output_Folder, GNSS_Choose, Code_Group, Add_FigNum, R, ...
        Height, sub_mat_Folder, currentPath, SH_Folder, sh_order, Cutoff_Ele)

    pool = gcp('nocreate');
    if ~isempty(pool)
        delete(pool)
    end
end
end
