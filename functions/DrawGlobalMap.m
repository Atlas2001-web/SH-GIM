function DrawGlobalMap(landColor, landAlpha)
if nargin < 1 
    landColor = [0.7, 0.7, 0.7];
end
if nargin < 2
    landAlpha = 1;
end

% 加载海岸线数据
landAreas = shaperead("landareas.shp");
hold on 
for i = 1:length(landAreas)
    % 获取当前多边形的 X 和 Y 数据
    x = landAreas(i).X;
    y = landAreas(i).Y;
    
    % 找到 NaN 的分割位置，分别填充每个子多边形
    nanIdx = isnan(x);
    startIdx = [1, find(nanIdx) + 1];
    endIdx = [find(nanIdx) - 1, length(x)];
    
    for j = 1:length(startIdx)
        fill(x(startIdx(j):endIdx(j)), y(startIdx(j):endIdx(j)), landColor, 'FaceAlpha', landAlpha);
    end
end
hold off

end