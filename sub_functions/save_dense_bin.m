function save_dense_bin(filename, M)
    % 保存 dense 实矩阵为 .bin 文件，并写入尺寸元数据
    fid = fopen([filename, '.bin'], 'w');
    fwrite(fid, M, 'double');  % 默认按列主序（column-major）
    fclose(fid);

    % 保存尺寸
    [m, n] = size(M);
    writematrix([m, n], [filename, '.meta'], 'Delimiter', 'tab');
end