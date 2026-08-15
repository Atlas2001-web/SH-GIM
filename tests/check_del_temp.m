project_root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(project_root, 'functions'));

test_root = fullfile(tempdir, ['ap_rbf_del_temp_', char(java.util.UUID.randomUUID)]);
mkdir(test_root);

cleanup_obj = onCleanup(@() cleanup_test_root(test_root));

create_file(fullfile(test_root, 'DATA', 'OUTPUT', 'Normal_Equation', '24001', 'a.mat'));
create_file(fullfile(test_root, 'DATA', 'OUTPUT', 'OBS_OUT', '24001', 'a.mat'));
create_file(fullfile(test_root, 'DATA', 'OUTPUT', 'Site_Info', 'Sites_Info_24001.mat'));
create_file(fullfile(test_root, 'DATA', 'INPUT', 'obs', '2024', '001', 'a.rnx'));
create_file(fullfile(test_root, 'DATA', 'OUTPUT', 'P4', '23365', 'a.mat'));
create_file(fullfile(test_root, 'DATA', 'OUTPUT', 'P4', '24001', 'a.mat'));
create_file(fullfile(test_root, 'DATA', 'OUTPUT', 'SP3_OUT', '2023365sp3.mat'));
create_file(fullfile(test_root, 'DATA', 'OUTPUT', 'SP3_OUT', '2024001sp3.mat'));

DEL_temp(test_root, datetime([2024, 1, 1]), datetime([2024, 1, 2]));

assert(~isfolder(fullfile(test_root, 'DATA', 'OUTPUT', 'Normal_Equation', '24001')));
assert(~isfolder(fullfile(test_root, 'DATA', 'OUTPUT', 'OBS_OUT', '24001')));
assert(isfile(fullfile(test_root, 'DATA', 'OUTPUT', 'Site_Info', 'Sites_Info_24001.mat')));
assert(~isfolder(fullfile(test_root, 'DATA', 'INPUT', 'obs', '2024', '001')));
assert(isfolder(fullfile(test_root, 'DATA', 'OUTPUT', 'P4', '23365')));
assert(isfile(fullfile(test_root, 'DATA', 'OUTPUT', 'SP3_OUT', '2023365sp3.mat')));
assert(isfolder(fullfile(test_root, 'DATA', 'OUTPUT', 'P4', '24001')));
assert(isfile(fullfile(test_root, 'DATA', 'OUTPUT', 'SP3_OUT', '2024001sp3.mat')));

create_file(fullfile(test_root, 'DATA', 'OUTPUT', 'P4', '24002', 'a.mat'));
create_file(fullfile(test_root, 'DATA', 'OUTPUT', 'SP3_OUT', '2024002sp3.mat'));

DEL_temp(test_root, datetime([2024, 1, 2]), datetime([2024, 1, 2]));

assert(isfolder(fullfile(test_root, 'DATA', 'OUTPUT', 'P4', '24001')));
assert(isfolder(fullfile(test_root, 'DATA', 'OUTPUT', 'P4', '24002')));
assert(isfile(fullfile(test_root, 'DATA', 'OUTPUT', 'SP3_OUT', '2024001sp3.mat')));
assert(isfile(fullfile(test_root, 'DATA', 'OUTPUT', 'SP3_OUT', '2024002sp3.mat')));

function create_file(file_path)
folder_path = fileparts(file_path);
if ~exist(folder_path, 'dir')
    mkdir(folder_path);
end
fid = fopen(file_path, 'w');
fclose(fid);
end

function cleanup_test_root(test_root)
if exist(test_root, 'dir')
    rmdir(test_root, 's');
end
end
