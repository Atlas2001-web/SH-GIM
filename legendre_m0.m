function P = legendre_m0(cos_theta_flat, order, normalize)
% LEGENDRE_M0 计算 m=0 的 Legendre 多项式，可选完全归一化
%
%   P = legendre_m0(cos_theta_flat, order, normalize)
%   normalize=true 时，对第 n 行乘以 sqrt((2*n+1)/2)

    cos_theta_flat = cos_theta_flat(:).';
    N = numel(cos_theta_flat);
    P = zeros(order+1, N);

    % 初值
    P(1, :) = 1;
    if order >= 1
        P(2, :) = cos_theta_flat;
    end

    % 三项递推
    for n = 2:order
        coef1 = (2*n - 1) / n;
        coef2 = (n - 1) / n;
        P(n+1, :) = coef1 .* cos_theta_flat .* P(n, :) ...
                    - coef2 .* P(n-1, :);
    end

    % —— 向量化完全归一化 ——  
    if normalize
        % 生成 [sqrt((2*0+1)/2); sqrt((2*1+1)/2); …; sqrt((2*order+1)/2)]
        n_vec = (0:order).';
        norm_factor = sqrt((2*n_vec + 1)/2);
        % 将每行乘以对应的归一化因子
        P = norm_factor .* P;
    end
end