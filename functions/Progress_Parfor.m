function D = Progress_Parfor(Str, Nums)
% usage: 
% D = Parfor_Progress(Str, Nums); % 此处必须输入两个参数
% parfor i = 1 : Nums
%     pause(0)
%     Parfor_Progress(D)
% end
% pause(0)为你的循环内容


persistent Count_Count N

if nargin == 2
    disp(Str)
    Count_Count = 0;
    N = Nums;
    D = parallel.pool.DataQueue;
    afterEach(D, @Progress_Parfor)
    disp('请骚等，正在开始并行ing')
elseif nargin == 1
    if ~isempty(Str)
        send(Str, [])
    else
        Count_Count = Count_Count + 1;
        Progress_Percent = Count_Count/N*100;
        Progress_Percent = sprintf('%03d%%', round(Progress_Percent));
        disp([repmat(char(8), 1, 5), Progress_Percent])
    end
end

end