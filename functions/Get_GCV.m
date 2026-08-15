function N = Get_GCV(B_Final, L_Final,V_Final,SV_Final)
% 验证输入
% 初始化计时
tic;
% 初始化并行池

% 计算矩阵条件数
cond_N = condest(B_Final);
fprintf('矩阵的条件数量是：%.6e\n', cond_N);

% 选择正则化参数范围
if cond_N > 1e12
max_eig = normest(B_Final);   % 近似最大特征值
min_eig = normest(inv(B_Final)); min_eig = 1/min_eig;  % 近似最小特征值
if min_eig<1e-10
    min_eig=1e-5;
end
    lambda_range = logspace(log10(min_eig*10000), log10(max_eig), 10);
elseif cond_N > 1e6
    lambda_range = logspace(-10, 6, 10);
elseif cond_N < 1e3
    lambda_range = logspace(-6, -2, 10);
else
    lambda_range = logspace(-4, 2, 10);
end

num_lambda = length(lambda_range);
gcv_values = zeros(num_lambda, 1);

p = size(B_Final, 1);  % 假设 N 是 n×n 的矩阵
n = SV_Final; % 样本数
parfor (i = 1:length(lambda_range),5)
    lambda = lambda_range(i);

    % 计算 (X^T X + lambda I)^(-1) X^T y
    N_lambda = B_Final + lambda * eye(p); % X^T X + lambda I
    beta_lambda = N_lambda \ L_Final; % 解 (X^T X + lambda I) beta = X^T y

    % 计算残差平方和：||y - X beta_lambda||^2
    % = y^T y - 2 beta_lambda^T (X^T y) + beta_lambda^T (X^T X) beta_lambda
    res = V_Final - 2 * beta_lambda' * L_Final + beta_lambda' * B_Final * beta_lambda;

    % 计算影响矩阵的迹
    % trace(X (X^T X + lambda I)^(-1) X^T) = trace((X^T X + lambda I)^(-1) X^T X)
    trace_term = trace(N_lambda \ B_Final);
    denom = (1 - trace_term / n)^2; % 分母

    % GCV 值
    gcv_values(i) = res / denom;
end
%%进行第二次循环遍历
[~, min_idx] = sort(gcv_values,'ascend');
lambda_opt1 = lambda_range(min_idx(1));
lambda_opt2 = lambda_range(min_idx(2));

lambda_range2 = logspace(log10(min(lambda_opt1, lambda_opt2)/2), log10(max(lambda_opt1, lambda_opt2)*2), 10);
gcv_values2 = zeros(length(lambda_range2), 1);
parfor (i = 1:length(lambda_range2),5)
    lambda = lambda_range2(i);

    % 计算 (X^T X + lambda I)^(-1) X^T y
    N_lambda = B_Final + lambda * eye(p); % X^T X + lambda I
    beta_lambda = N_lambda \ L_Final; % 解 (X^T X + lambda I) beta = X^T y

    % 计算残差平方和：||y - X beta_lambda||^2
    % = y^T y - 2 beta_lambda^T (X^T y) + beta_lambda^T (X^T X) beta_lambda
    res = V_Final - 2 * beta_lambda' * L_Final + beta_lambda' * B_Final * beta_lambda;
    res = res / n; % 均方误差

    % 计算影响矩阵的迹
    % trace(X (X^T X + lambda I)^(-1) X^T) = trace((X^T X + lambda I)^(-1) X^T X)
    trace_term = trace(N_lambda \ B_Final);
    denom = (1 - trace_term / n)^2; % 分母
    % GCV 值
    gcv_values2(i) = res / denom;
end

[~, min_idx] = min(gcv_values2);
lambda_opt = lambda_range2(min_idx);
fprintf('最后选择的最优GCV参数是:%.6e\n',lambda_opt);


% 计算最终的正则化矩阵 N
N = B_Final + lambda_opt * eye(p);
cond_N2 = condest(N);
fprintf('优化后的矩阵条件数为：%.6e\n', cond_N2);


end