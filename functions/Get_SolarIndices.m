function [result, data_type, VarPos] = Get_SolarIndices(VarName, StartTime, EndTime)
% 爬取omniweb的太阳活动数据
if nargin < 1
    VarName = ["Solar index F10.7"; "Kp*10 Index"; "Dst Index, nT"];
end
if nargin < 2
    StartTime = [2024 1 1];
    EndTime = [2024 12 31];
end

% 通过循环确保不会失败
n = 0;
while 1
    n = n + 1;

    try
        % 获取每个变量的编号
        Web = webread('https://omniweb.gsfc.nasa.gov/form/dx1.html');
        Web = strrep(Web, '&gt;', '>');
        Expression = 'VALUE="(\d+?)" NAME="vars".*?>(.*?)</td>';
        Vars = regexp(Web, Expression, 'tokens');
        Vars = vertcat(Vars{:});

        VarValue = vertcat(Vars{contains(Vars(:, 2), VarName), 1});
        VarPos = zeros(size((VarName)));
        for i = 1 : numel(VarName)
            VarPos(i) = find(contains(Vars(:, 2), VarName(i)));
        end
        [~, VarPos] = sort(VarPos);

        VarValue = strjoin(string(VarValue), '&vars=');

        % 向网站发送请求，获取数据
        body = sprintf(['activity=retrieve' ...
            '&res=hour' ...
            '&spacecraft=omni2' ...
            '&start_date=%d%02d%02d' ...
            '&end_date=%d%02d%02d' ...
            '&vars=%s' ...
            '&scale=Linear' ...
            '&ymin=' ...
            '&ymax=' ...
            '&charsize=1.5' ...
            '&symsize=0.5' ...
            '&symbol=0' ...
            '&imagex=960' ...
            '&imagey=720'], StartTime(1), StartTime(2), StartTime(3), ...
            EndTime(1), EndTime(2), EndTime(3), VarValue);

        header = [matlab.net.http.HeaderField('Content-Type', ...
            'application/x-www-form-urlencoded')];

        request = matlab.net.http.RequestMessage('POST', header, body);
        response = send(request, 'https://omniweb.gsfc.nasa.gov/cgi/nx1.cgi');
        break
    catch ME
        if n >= 5
            error(ME.message)
        end
        pause(5)
    end

end

data = response.Body.Data;

% 从data中截取结果
VarNum = numel(VarName);
Expression0 = 'Selected parameters:(.*)YEAR\s+DOY\s+HR\s+1';
data_type = regexp(data, Expression0, 'tokens');
Expression0 = '\s+\d+\s+(.*?)\n';
data_type = regexp(data_type{:}, Expression0, 'tokens');

Expression = 'YEAR\s+DOY\s+HR\s+1';
for i = 1 : VarNum-1
    Expression = [Expression, '\s+', num2str(i+1)];
end

Expression = [Expression, '(.*)</pre><hr><HR>'];
result = regexp(data, Expression, 'tokens');

result = textscan(result{:}, ['%f %f %f', repmat(' %f', [1, VarNum])]);
result = horzcat(result{:});

% x = datetime(result(1,1),1,1) + days(result(:,2))-1 + hours(result(:,3));
% plot(x,result(:,4))
% hold on
% plot(x,result(:,5))
% plot(x,result(:,6))
% hold off
% saveas(gcf, '1.fig')
end