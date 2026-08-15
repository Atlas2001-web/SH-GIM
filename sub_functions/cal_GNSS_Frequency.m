clear
clc

k = [1, -4, 5, 6, 1, -4, 5, 6, -2, -7, 0, -1, -2, -7, 0, -1, 4, -3, 3, 2, 4, -3, 3, 2, -5, -6];
F1 = zeros(26, 1)';
F2 = zeros(26, 1)';
for i = 1 : numel(F1)
    F1(i) = (1602 + 0.5625*k(i))*1e+6;
    F2(i) = (1246 + 0.4375*k(i))*1e+6;
end
current_file=pwd;

load([current_file "/DATA/sub_mat/GNSS_Frequency_band.mat"], 'GNSS_Frequency')
GNSS_Frequency.R.F1 = F1;
GNSS_Frequency.R.F2 = F2;

save([current_file "/DATA/sub_mat/GNSS_Frequency_band.mat"], 'GNSS_Frequency')
