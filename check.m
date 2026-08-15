% 1. 获取文件名前缀
files = dir('D:\download\径向基建模\径向基建模\DATA2\Output\P4\GPS\24001\*.mat');
all_names = {files.name};
prefixes = cellfun(@(x) upper(x(1:4)), all_names, 'UniformOutput', false);  % 转为大写前缀

% 2. 初始化结果数组
stations = {};  % 用 cell 数组更灵活
fid = fopen("station.txt", "r");
if fid == -1
    error("station.txt 文件无法打开");
end

% 3. 遍历 station.txt 文件
while ~feof(fid)
    line = strtrim(fgetl(fid));  % 去除首尾空格
    if startsWith(line, 'G') && length(line) >= 6
        sation_line = upper(line(3:6));  % 提取站点码并大写
        if ~any(strcmp(sation_line, prefixes))
            stations{end+1,1} = sation_line;
        end
    end
end

fclose(fid);

% 4. 去重 + 显示
stations = unique(stations);
disp('没有匹配到的站点如下：');
disp(stations);
