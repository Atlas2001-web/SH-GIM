function downloadIonex(StartTime, EndTime, Folder, DataType)

if nargin < 1
    StartTime = datetime([2024, 1, 1]);
    EndTime = datetime([2024, 12, 31]);
end
if nargin < 3
    Folder = 'F:\MIT\';
end
if nargin < 4
    DataType = 'uqr';
end

DataType = upper(DataType);
switch DataType
    case 'CAS'
        TimeRes = '30M';
    case {'IGS', 'JPL', 'ESA'}
        TimeRes = '02H';
    case {'UPC', 'UQR'}
        TimeRes = '';
end

Folder = [Folder, DataType, ' VTEC'];
if exist(Folder, 'dir') == 0
    mkdir(Folder)
end

URL = cell(days(EndTime - StartTime) + 1, 1);
n = 1;
for i = StartTime : EndTime
    if i >= datetime([2024, 1, 1]) && ~isempty(TimeRes)
        URL{n} = sprintf(['https://cddis.nasa.gov/archive/gnss/products/' ...
            'ionosphere/%d/%03d/%s0OPSFIN_%d%03d0000_01D_%s_GIM.INX.gz'], ...
            year(i), day2doy(i), DataType, year(i), day2doy(i), TimeRes);
    else
        URL{n} = sprintf(['https://cddis.nasa.gov/archive/gnss/products/' ...
            'ionosphere/%d/%03d/%sg%03d0.%02di.Z'], ...
            year(i), day2doy(i), lower(DataType), ...
            day2doy(i), year(i)-round(year(i), -3));
    end
    n = n + 1;
end

fid = fopen('E:\python_code\urlList.txt', 'w+');
urlStr = strjoin(URL, '\n');
fprintf(fid, urlStr);
fclose(fid);

fileName = split(URL, '/');
if size(fileName, 2) == 1
    fileName = fileName(end);
else
    fileName = fileName(:, end);
end
fileName = fullfile(Folder, fileName);

cookie = get_address_1_cookie(1);
options = weboptions('HeaderFields' , {'Cookie' , cookie}, 'Timeout', 15);
download_file(URL, fileName, options)

isExist = cellfun(@(x) exist(x, 'file'), fileName);
if all(isExist == 2)
    fprintf('文件下载完成\n现在开始解压文件\n')
else
    fprintf('%s下载失败\n', fileName(isExist == 0))
end

for i = 1 : numel(fileName)
    system(['echo u | 7z x "', fileName{i}, '" -o"', Folder, '"'])
    delete(fileName{i})
end

fprintf('解压完成\n')

end



function [address_1_cookie, UpdateResult] =...
         get_address_1_cookie(updateYorN, ProxyHost, ProxyPort)
% 对python脚本必要的参数进行设置
if nargin < 1
    updateYorN = 1;
end
if nargin < 2
    ProxyHost = '127.0.0.1';
    ProxyPort = '10809';
end

username = 'jnuhby';
password = 'Superlong(159357';
cookie_file_path = 'E:\matlab\download_rinex\cookie_file\nasa_cookie.txt';

if updateYorN == 1
    try
        UpdateResult = system(['python E:\matlab\download_rinex\' ...
            'python_code\nasa_cookie.py ', username, ' ', password, ' ',...
            cookie_file_path, ' ', ProxyHost, ProxyPort,  ' > nul']);
    catch
        UpdateResult = 1;
    end
end

cookie = importdata(cookie_file_path);

if length(cookie) == 1
    address_1_cookie = cookie{1};
elseif any(cellfun(@(x) contains(x, 'Cookie:'), cookie))
    ind = find(cellfun(@(x) contains(x, 'Cookie:'), cookie));
    address_1_cookie = cookie{ind(1)}(9:end);
else
    try
        UpdateResult = system(['python E:\matlab\download_rinex\' ...
            'python_code\nasa_cookie.py ', username, ' ', password, ' ',...
            cookie_file_path, ' ', ProxyHost, ProxyPort,  ' > nul']);
    catch
        UpdateResult = 1;
    end
end

if exist("UpdateResult" , 'var') && UpdateResult == 1
    fprintf('Cookie更新失败，请检查网络连接是否正常\n')
end

end