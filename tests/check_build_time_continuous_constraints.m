project_root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(project_root, 'functions'));

single_kernel_num = 3;
fig_num = 5;
cof_num = 20;

[T, Lt] = Build_Time_Continuous_Constraints(single_kernel_num, fig_num, cof_num);

assert(isequal(size(T), [single_kernel_num * fig_num, cof_num]));
assert(isequal(size(Lt), [single_kernel_num * fig_num, 1]));

nonzero_rows = find(any(T, 2));
expected_rows = ((single_kernel_num + 1):(single_kernel_num * (fig_num - 1)))';
assert(isequal(nonzero_rows, expected_rows));

expected = zeros(1, cof_num);
expected(4) = -1;
expected(7) = 1;
assert(isequal(T(4, :), expected));

expected = zeros(1, cof_num);
expected(6) = -1;
expected(9) = 1;
assert(isequal(T(6, :), expected));

expected = zeros(1, cof_num);
expected(10) = -1;
expected(13) = 1;
assert(isequal(T(10, :), expected));

assert(all(Lt == 0));
