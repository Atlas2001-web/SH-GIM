function Orb = read_sp3(FileName)
if nargin < 1
    FileName = "F:\GNSS-sp3\COD0MGXFIN_20233650000_01D_05M_ORB.SP3";
end

Lines = readlines(FileName);

% 读取头文件信息
n = 0;
while 1
    n = n + 1;

    % 第一行的内容，历元数量
    if Lines{n}(1) == '#' && Lines{n}(2) ~= '#'
        EpochNum = sscanf(Lines{n}(33:39), '%f');
    end

    if Lines{n}(1) == '+' && Lines{n}(2) ~= '+'
        SatNum = sscanf(Lines{n}(4:6), '%f');
        LineNum_Sat = ceil(SatNum/17);

        SatPrn = vertcat(Lines{n : n+LineNum_Sat-1});
        SatPrn(:, 1:9) = [];

        SatPrn = SatPrn - '0';
        GNSSTypes = [SatPrn(:, 1:3:end)];
        GNSSType = unique(GNSSTypes);
        GNSSType(GNSSType < 0) = [];

        WeightArray = zeros(34, 17);
        for i = 1 : size(WeightArray, 2)
            WeightArray((i-1)*2+1 : i*2, i) = [10, 1];
        end
        SatPrn(:, 1:3:end) = [];
        SatPrn = SatPrn * WeightArray;
        SatPrn = SatPrn';
        
        % 预分配空间，创建变量
        for i = 1 : numel(GNSSType)
            Idx = find(GNSSTypes' == GNSSType(i), 1, 'last');
            for j = 1 : 3
                Orb.(char(GNSSType(i) + '0')).(char(119+j)) = ...
                    zeros(EpochNum, SatPrn(Idx));
            end
        end

        n = n + LineNum_Sat - 1;
    end

    % 到达数据部分，终止循环
    if Lines{n}(1) == '*'
        break
    end
    
end

WeightArray = zeros(60, 4);
WeightArray(3:4, 1) = [10, 1];
for i = 2 : 4
    WeightArray(5 + 14*(i-2) : 18 + 14*(i-2), i) = ...
        [logspace(6, 0, 7), 0, logspace(-1, -6, 6)];
end

% 读取数据部分
k = 0;
Epoch = 1;
while 1
    n = n + 1;
    k = k + 1;
    if Lines{n}(1) == '*' || Lines{n}(1:3) == "EOF"
        Line = vertcat(Lines{n-k+1 : n-1});
        Line = Line - '0';

        CGNSSType = Line(:, 2);

        % 找出负值
        Idx = [any(Line(:, 5:18) == -3, 2), ...
            any(Line(:, 19:32) == -3, 2), ...
            any(Line(:, 33:46) == -3, 2)];
        Line(Line < 0 | Line > 9) = 0;

        Data = Line*WeightArray;
        Corr = Data(:, 2:4);
        SatPrn = Data(:, 1);
        Corr(Idx) = -Corr(Idx);

        for i = 1 : numel(GNSSType)
            Idx = CGNSSType == GNSSType(i);
            for j = 1 : 3
                Orb.(char(GNSSType(i) + '0')). ...
                    (char(119+j))(Epoch, SatPrn(Idx)) = Corr(Idx, j);
            end
        end

        Epoch = Epoch + 1;
        k = 0;
    end

    if Epoch > EpochNum
        break
    end

end


end