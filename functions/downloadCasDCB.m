function downloadCasDCB(startTime, endTime, downloadPath)
if nargin < 1 
    startTime = datetime([2024, 10, 29]);
    endTime = datetime([2024, 12, 31]);
end
if nargin < 3
    downloadPath = 'F:\dcb\2024\';
end

link = ftp_connect('ftp.gipp.org.cn', [], [], 'ftp');
for T = startTime : endTime
    remotePath = sprintf('/product/dcb/mgex/%d/CAS0*_%d%03d*.BSX.gz', ...
        year(T), year(T), day2doy(T));
    fileList = dir(link, remotePath);
    if isempty(fileList)
        continue
    end
    filePath = fileList.name;
    download_file({filePath}, {downloadPath}, [], link)
end

close(link)
end