function download_file(URL, StoragePath, option, ftp)

if nargin < 3
    option = [];
end
if nargin < 4
    ftp = [];
end

n = 0;
while 1
    [URL, StoragePath] = Download(URL, StoragePath, option, ftp);

    if isempty(URL)
        break
    end

    if n > 10
        fprintf('部分文件无法下载:\n')
        fprintf(URL)
        break
    end
end


end

function [URL_new, StoragePath_new] = Download(URL, StoragePath, option, ftp)
% URL:下载链接，n*1的cell或string
% StoragePath: 存储路径以及文件名，n*1的cell或string，大小必须与URL相同
% option（非必要）: 同websave，部分需要cookie的站点需要输入
% 如果是ftp，则StoragePath是与URL相同大小的存储路径（不包含文件名）

URL_new = URL;
StoragePath_new = StoragePath;

for i = 1 : length(URL)
    isSuccessful = 1;

    CurrentStorage = StoragePath{i};
    CurrentURL = URL{i};
    fprintf('开始下载%s ==>>', CurrentURL)
    
    n = 1; % 循环次数
    while 1
        try
            if exist('ftp', 'var') && ~isempty(ftp)
                mget(ftp, CurrentURL, CurrentStorage);
                movefile(fullfile(CurrentStorage, CurrentURL), CurrentStorage)
                fprintf('⭐成功下载%s\n' , CurrentURL)
            else
                if exist("option" , 'var') && ~isempty(option)
                    websave(CurrentStorage, CurrentURL, option);
                else
                    websave(CurrentStorage, CurrentURL);
                end        
            end

            % 检查下载的文件是否正确
            if ~exist('ftp', 'var') || isempty(ftp)
                if exist(CurrentStorage, 'file')
                    fprintf('⭐成功下载%s\n' , CurrentStorage)
                elseif exist([CurrentStorage, '.html'], 'file')
                    delete([CurrentStorage, '.html'])
                    error('下载出错\n')
                end
            end
           
            break
        catch ME
            % 文件不存在，则跳过该文件
            if contains(ME.message, 'Not Found')
                fprintf('☠404 Not Found 文件不存在\n')
                break
            end
            % 文件存在，但是下载出错，检查问题尝试重新下载
            n = n + 1;
            fprintf('⦾下载出错(%s)，正在尝试第%d次下载 ==>>', ME.message, n)
            if n > 3
                %网络检查
                while 1
                    try
                        webread('https://www.bing.com/#!');
                        break % 网络正常，则停止网络检查，再重新尝试一次
                    catch
                        fprintf('网络故障，1分钟后重新尝试\n')
                        pause(60)
                        continue
                    end
                end
            end
            if n > 4
                % 第四次重新尝试仍然失败，则跳过这个文件
                fprintf('☠%s\n', ME.message)
                isSuccessful = 0;
                break
            end
        end
    end

    if exist([CurrentStorage, '.html'], 'file')
        delete([CurrentStorage, '.html'])
    end

    % 当前文件下载失败
    if ~isSuccessful
        continue
    end

    % 成功下载，则将该文件的URL移除
    URL_new = setdiff(URL_new , CurrentURL);
    StoragePath_new = setdiff(StoragePath_new, CurrentStorage);
end


if exist('ftp', 'var') && ~isempty(ftp)
    folder = split(URL{1}, '/');
    folder = folder{2};
    rmdir(fullfile(StoragePath{1}, folder), 's');
end

end
