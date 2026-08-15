function ax = Get_ax2(NumLine, NumColumn, LineSpacing, ColumnSpacing, LineEdge, ColumnEdge, FigureWidth, FigureHeight)
% 绘制子图
% ax = Get_ax2(NumLine, NumColumn, LineSpacing, ColumnSpacing, LineEdge,
% ColumnEdge, FigureWidth, FigureHeight)
% ax = Get_ax2(1, 2, 0.3, 0.3, [0.1 3.65], [1.3 0.1], 12.9, [4.3 3]);
% LineSpacing：行间距，当输入参数为标量时，行间距相等，当输入参数为向量时，向量长
% 度必须等于NumLine-1（即行间距的个数）
% ColumnSpacing：列间距，其它与LineSpacing同理
% LineEdge：上下边距
% ColumnEdge：左右边距
% FigureWidth：图窗宽度
% FigureHeight：坐标区高度与宽度的比例，至少需要两个数据，[坐标区高度，坐标区宽度]
% 可以输入多个比值，以设置不同比例的子图。
% 可以接收的矩阵大小包括（1，2），（1，2*NumColumn），（1*NumLine，2）
% （1*NumLine，2*NumColumn）
% 注：如果无法显示图窗，在figure中调整图窗的初始位置

% 固定坐标区长宽比，计算所需要的图窗高度(FigureHeight = [axHeight, axWidth])
axWidth = nan(NumLine, NumColumn);
axHeight = nan(size(axWidth));
HW_rate = nan(size(axHeight));

% 行列间距
if isscalar(LineSpacing)
    LineSpacing = repmat(LineSpacing, [NumLine-1 1]);
end
if isscalar(ColumnSpacing)
    ColumnSpacing = repmat(ColumnSpacing, [NumColumn-1 1]);
end

% FigureHeight包含两个数据（1*2）
if size(FigureHeight, 1) == 1 && size(FigureHeight, 2) == 2
    CurrentHW_Rate = FigureHeight(1) / FigureHeight(2);
    HW_rate(:, :) = CurrentHW_Rate;
% FigureHeight包含2n个数据（1*2n），此时n必须等于NumColumn
elseif size(FigureHeight, 1) == 1 && size(FigureHeight, 2) > 2
    for i = 1 : NumColumn
        CurrentHW_Rate = FigureHeight((i - 1)*2 + 1) / FigureHeight((i - 1)*2 + 2);
        HW_rate(:, i) = CurrentHW_Rate;
    end
% FigureHeight包含2n个数据（n*2），此时n必须等于NumLine
elseif size(FigureHeight, 1) > 1 && size(FigureHeight, 2) == 2
    for i = 1 : NumLine
        CurrentHW_Rate = FigureHeight(i, 1) / FigureHeight(i, 2);
        HW_rate(i, :) = CurrentHW_Rate;
    end
% FigureHeight包含2mn个数据（n*2m），此时n必须等于NumLine，m必须等于NumColumn
elseif size(FigureHeight, 1) > 1  && size(FigureHeight, 2) > 2
    for i = 1 : NumLine
        for j = 1 : NumColumn
            CurrentHW_Rate = FigureHeight(i, (j - 1)*2 + 1) / FigureHeight(i, (j - 1)*2 + 2);
            HW_rate(i, j) = CurrentHW_Rate;
        end
    end
else
    error('坐标区长宽比输入格式错误')
end

for i = 1 : NumLine
    for j = 1 : NumColumn
        axWidth(i, j) = (1/HW_rate(i, j)) / sum(ones(size(HW_rate(i, :))) ...
            ./ HW_rate(i, :)) * (FigureWidth - sum(ColumnSpacing) - sum(ColumnEdge));
        axHeight(i, j) = axWidth(i, j) * HW_rate(i, j);
    end
end

FigureHeight = sum(axHeight(:, 1)) + sum(LineEdge) + sum(LineSpacing);

% 在此处修改图窗的位置
figure('Units', 'centimeters', 'Position', [10, 5, FigureWidth, FigureHeight])

if isscalar(LineEdge)
    LineEdge = repmat(LineEdge, [1, 2]);
end
if isscalar(ColumnEdge)
    ColumnEdge = repmat(ColumnEdge, [1, 2]);
end

ax = cell(NumLine, NumColumn);
for i = 1 : NumLine
    for j = 1 : NumColumn
        CurrentX = ColumnEdge(1) + sum(axWidth(i, 1:j-1)) + sum(ColumnSpacing(1:j-1)); 
        CurrentY = FigureHeight - LineEdge(1) - sum(axHeight(1:i, j)) - sum(LineSpacing(1:i-1));
        ax{i, j} = axes('Units', 'centimeters', 'Position', [CurrentX CurrentY axWidth(i, j) axHeight(i, j)]);
    end
end