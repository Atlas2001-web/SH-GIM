function unpack_obs(packFilePath,stations_txt,Ofile_Input_Folder,unpack_outdir,t)

if nargin<1
    packFilePath='D:\GNSS_Obs\GNSS-OBS';
end

if nargin<2
    stations_txt='E:\matlab\dowload2\stations_350.txt';
end

if nargin<3
    Ofile_Input_Folder='E:\matlab\SRBF2\DATA\INPUT\obs';
end

if nargin<4
    unpack_outdir='D:\GNSS_Obs\GNSS-OBS\unpack';
end


if nargin<5
    t=datetime(2022,01,02);
end



for T = t - days(1) : t + days(1)
%%创建一个转化的目标文件夹
data_year=year(T);
data_doy=day2doy(T);
tPath=sprintf('%d/%03d',data_year,data_doy);
targetPath=fullfile(Ofile_Input_Folder,tPath);
if ~exist(targetPath,'dir')
    mkdir(targetPath)
else
    fprintf('\n我现在要跳过%s的文件处理咯,嘿嘿嘿',targetPath);
    continue;
end

%%读取需要的测站的txt目录
stations=readlines(stations_txt);
stations = strtrim(stations);        % 去掉每行的首尾空白字符
stations = stations(stations ~= ""); % 删除空行（包括原来就是空行或全是空格的）

%%读取压缩包里面的文件，找到对方的文件
packFilePath_rar=fullfile(packFilePath,tPath);
packFiles=dir(packFilePath_rar);
packFiles = packFiles(~[packFiles.isdir]); % 去掉 . 和 ..（只保留文件）
packFiles_names={packFiles.name}';
first4 = cellfun(@(x) x(1:4), packFiles_names, 'UniformOutput', false);  % 取前4位
pool = gcp('nocreate');  % 如果存在并行池就返回池对象，否则返回空
if isempty(pool)
    parpool("Processes");   % 如果没有并行池，则创建一个进程池
end

parfor i = 1:length(stations)
    stationName = stations(i);
    stationName4 = extractBefore(stationName,5); % 取前4字符（更安全）
    % 找到匹配的文件索引
    idx = find(strcmpi(first4, stationName4));
    % parfor 不允许 matchedFiles = packFiles(idx)
    % 所以必须逐个处理 idx(k)
    for k = 1:length(idx)
        fileIdx = idx(k); % 文件的真正 index
        fileName = packFiles_names{fileIdx};
        srcPath = fullfile(packFilePath_rar, fileName);
        fprintf("Worker %d 正在处理文件：%s\n", i, fileName);
        % 这里的 gunzip 每次只处理一个文件，线程安全
        gunzip(srcPath, unpack_outdir);
    end
end

%这里开始进行o文件的转化
crx2rnx_path='E:\matlab\SRBF2\functions\Tools\CRX2RNX\crx2rnx.exe';
crxFiles = dir(fullfile(unpack_outdir, '*.crx'));  % 所有crx文件  
crdFiles = dir(fullfile(unpack_outdir, '*.??d'));  % 有的叫.21d .22d  
allFiles = [crxFiles; crdFiles];
parfor i = 1:length(allFiles)
    srcFile = fullfile(unpack_outdir, allFiles(i).name);
    cmd = sprintf('"%s" "%s"', crx2rnx_path, srcFile);
    system(cmd);
    fprintf("Worker 转换: %s\n", allFiles(i).name);
end

% ====== 移动转换后生成的 RINEX 文件到目标目录 ======
rnxFiles = [dir(fullfile(unpack_outdir, '*.rnx'));
            dir(fullfile(unpack_outdir, '*.??o'))];
parfor i = 1:length(rnxFiles)
    srcRnx = fullfile(unpack_outdir, rnxFiles(i).name);
    destRnx = fullfile(targetPath, rnxFiles(i).name);

    movefile(srcRnx, destRnx);  % 直接移动文件
    fprintf("移动到目标目录: %s\n", rnxFiles(i).name);
end

%删除目标文件夹的文件
parfor i = 1:length(allFiles)
    srcFile = fullfile(unpack_outdir, allFiles(i).name);
    delete(srcFile);
end


% %%这里将获取的格式为2的转化为3的格式
% obs_V2=dir([char(targetPath) '\*.*o']);
% gfz_F ='E:\matlab\SRBF2\functions\Tools\GFZRNX\gfzrnx.exe';
% parfor i=1:length(obs_V2)
% V2_File = fullfile(targetPath, obs_V2(i).name);
% fout = V2_File;  % 输出文件与输入文件同名，用于覆盖  
%     cmd = sprintf('"%s" -finp "%s" -fout "%s" -vo 3.02 -f', gfz_F, V2_File, fout);  % 构建覆盖命令  
%     system(cmd);  % 执行覆盖转换  
% end



end
end