project_root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(project_root, 'sub_functions'));

tmp_file = [tempname, '.24i'];
cleanup_obj = onCleanup(@() local_cleanup(tmp_file));

GIMs.VTEC = reshape(1:16, [2, 4, 2]);
GIMs.RMS = reshape(101:116, [2, 4, 2]);
DCB_S = struct();
DCB_R = struct();
Time = datetime(2024, 1, 1, 0, 0, 0);

Write_Ionex(tmp_file, GIMs, DCB_S, DCB_R, Time, 3600, 2, ...
    10, 2.5, 5, 6371000, 450000, -180, 180, 87.5, -87.5);

lines = readlines(tmp_file);
lines = string(lines);

tec_start = find(contains(lines, "START OF TEC MAP"));
tec_end = find(contains(lines, "END OF TEC MAP"));
rms_start = find(contains(lines, "START OF RMS MAP"));
rms_end = find(contains(lines, "END OF RMS MAP"));

assert(numel(tec_start) == 2);
assert(numel(tec_end) == 2);
assert(numel(rms_start) == 2);
assert(numel(rms_end) == 2);

assert(tec_start(1) < tec_end(1));
assert(tec_end(1) < tec_start(2));
assert(rms_start(1) < rms_end(1));
assert(rms_end(1) < rms_start(2));

function local_cleanup(tmp_file)
if exist(tmp_file, 'file') ~= 0
    delete(tmp_file);
end
end
