function Get_sp3(StartTime, EndTime, Folder)

if nargin < 1
    StartTime = datetime([2024, 1, 3]);
    EndTime = datetime([2024, 1, 3]);
end
if nargin < 3
    Folder = 'F:\GNSS-sp3\';
end

URL = cell(days(EndTime - StartTime) + 1, 1);
n = 1;
for i = StartTime : EndTime
    GPSWeek = UTC2GPSweek(i);
    URL{n} = sprintf(['/pub/igs/products/%4d/' ...
        'COD0MGXFIN_%d%03d0000_01D_05M_ORB.SP3.gz'], ...
        GPSWeek, year(i), day2doy(i));

    n = n + 1;
end

link = ftp_connect('igs.ign.fr', [], [], 'ftp');
download_file(URL, repmat({Folder}, size(URL)), [], link)
close(link)

fileName = split(URL, '/');
if size(fileName, 2) == 1
    fileName = fileName(end);
else
    fileName = fileName(:, end);
end
fileName = fullfile(Folder, fileName);
isExist = cellfun(@(x) exist(x, 'file'), fileName);
if all(isExist == 2)
    fprintf('文件下载完成\n现在开始解压文件\n')
end

for i = 1 : numel(fileName)
    system(['echo u | 7z x ', fileName{i}, ' -o', Folder])
    delete(fileName{i})
end

fprintf('解压完成\n')

end