function [LowerIdx, UpperIdx] = findAdjacentIndices(x0, x)
% 二分法找出某个数据在升序数组中相邻的两个数据
% 输入：
% x0：已排序的数组（升序）
% x：目标值
% 输出：
% LowerIdx：x0 中小于 x 的最大值索引
% UpperIdx：x0 中大于或等于 x 的最小值索引

% 初始化边界
left = 1;
right = numel(x0);

while left <= right
    mid = floor((left + right) / 2);
    if x0(mid) < x
        left = mid + 1; % 搜索右半部分
    else
        right = mid - 1; % 搜索左半部分
    end
end

% 结果
LowerIdx = max(1, right); % 确保索引有效
UpperIdx = min(numel(x0), left); % 确保索引有效
end