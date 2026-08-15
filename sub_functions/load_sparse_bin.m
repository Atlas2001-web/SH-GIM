function S = load_sparse_bin(filename)
% 从 .bin 和 .meta 文件中加载稀疏矩阵
% 返回重建后的 sparse 矩阵

    % 读取尺寸信息
    dims = readmatrix([filename, '.meta']);
    m = dims(1); n = dims(2);

    % 读取三元组数据
    fid = fopen([filename, '.bin'], 'r');
    data = fread(fid, [3, Inf], 'double');
    fclose(fid);

    % 构造稀疏矩阵
    S = sparse(data(1,:), data(2,:), data(3,:), m, n);
end