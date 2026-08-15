function M = load_dense_bin(filename)
    dims = readmatrix([filename, '.meta']);
    m = dims(1); n = dims(2);

    fid = fopen([filename, '.bin'], 'r');
    M = fread(fid, [m, n], 'double');  % 矩阵按列优先恢复
    fclose(fid);
end