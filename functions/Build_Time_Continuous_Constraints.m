function [T, Lt] = Build_Time_Continuous_Constraints(single_kernel_num, fig_num, cof_num)
T = zeros(single_kernel_num * fig_num, cof_num);
k = single_kernel_num;
for i = 1 : fig_num - 2
    for j = 1 : single_kernel_num
        k = k + 1;
        idx_prev = i * single_kernel_num + j;
        idx_next = (i + 1) * single_kernel_num + j;
        T(k, idx_prev) = -1;
        T(k, idx_next) = 1;
    end
end

Lt = zeros(single_kernel_num * fig_num, 1);
end
