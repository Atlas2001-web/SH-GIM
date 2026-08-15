function link = ftp_connect(address, username, password, LinkType)

n = 1;
while 1
    fprintf('开始第%d次尝试连接到%s ==>>', n, address)
    n = n + 1;
    try
        if isempty(username)
            switch LinkType
                case 'ftp'
                    link = ftp(address);
                case 'sftp'
                    link = sftp(address);
            end
        else
            switch LinkType
                case 'ftp'
                    link = ftp(address, username, password);
                case 'sftp'
                    link = sftp(address, username, "Password", password);
            end
        end
        fprintf('成功连接到%s\n', address)
        break
    catch ME
        fprintf('第%d次连接到%s失败,错误原因为%s\n', n, address, ME.message)
        if n > 10
            fprintf('无法连接到%s\n', address)
            link = -1;
            return
        else
            continue
        end
    end 
end

end