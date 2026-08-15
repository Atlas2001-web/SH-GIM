function save_sparse_bin(filename, S)
% 将稀疏矩阵 S 保存为二进制 .bin 文件，格式为 [i, j, v] 三元组
% 同时保存一个 .meta 文件记录矩阵尺寸

    if ~issparse(S)
        error('输入必须为稀疏矩阵');
    end

    [i, j, v] = find(S);  % 提取非零元素
    data = [i(:), j(:), v(:)]';  % 3 x N 数组

    fid = fopen([filename, '.bin'], 'w');
    fwrite(fid, data, 'double');
    fclose(fid);

    % 保存尺寸信息
    dims = size(S);
    writematrix([filename, '.meta'], dims, 'delimiter', '\t');
end