function y = interpolationLagrange(x0, y0, x, n)
% x0  - 从小到大排列
% y0
% x   - 待插值点
% n   - 数据点个数

Idx = zeros(size(x, 1), n);
for i = 1 : numel(x)
    Idx(i, :)= FindIdx(x0, x(i), n);
end

[Idx_u, Ind] = unique(Idx, "rows");
y = zeros(size(x));
for i = 1 : size(Idx_u, 1)
    StartIdx = Ind(i);
    if i ~= size(Idx_u, 1)
        EndIdx = Ind(i+1)-1;
    else
        EndIdx = numel(x);
    end

    Idx_C = Idx_u(i, :);
    Idx_C(Idx_C > numel(x0)) = [];
    Idx_C = unique(Idx_C);

    y(StartIdx : EndIdx) = ...
        interp_lag(x0(Idx_C), y0(Idx_C), x(StartIdx : EndIdx));
end

end

function y0 = interp_lag(x, y, x0)
%lagrange插值
n=length(x);
y0=zeros(size(x0));
for k=1:n
    t=1;
    for i=1:n
        if i~=k
            t=t.*(x0-x(i))/(x(k)-x(i));
        end
    end
    y0=y0+t*y(k);
end
end

function Idx = FindIdx(x0, x, n)

% LowerIdx = findAdjacentIndices(x0, x);
LowerIdx = find(x0 < x, 1, 'last');
% 无跳跃或重复数据时使用
UpperIdx = LowerIdx + 1;
UpperIdx = min(UpperIdx, numel(x0));
% UpperIdx = find(x0 >= x, 1, 'first');
% % 二分法找出相邻的两个数据
% [LowerIdx, UpperIdx] = findAdjacentIndices(x0, x);

if rem(n, 2) == 0
    LowerIdxs = LowerIdx - n/2 + 1 : LowerIdx;
    UpperIdxs = UpperIdx : UpperIdx + n/2 - 1;
else
    if x0(UpperIdx) - x > x - x0(LowerIdx)
        LowerIdxs = LowerIdx - floor(n/2) : LowerIdx;
        UpperIdxs = UpperIdx : UpperIdx + floor(n/2) - 1;
    else
        LowerIdxs = LowerIdx - floor(n/2) + 1 : LowerIdx;
        UpperIdxs = UpperIdx : UpperIdx + floor(n/2);
    end
end

Idx = [LowerIdxs, UpperIdxs];

end


