function [finalDCB, finalRMS] = readDCB(fileName)

if nargin < 1 
    fileName = 'F:\dcb\2022\CAS0MGXRAP_20220010000_01D_01D_DCB.BSX';
end

lines = readlines(fileName);

% 换行到数据所在行
n = 0;
while 1
    n = n + 1;
    if contains(lines(n), '*BIAS SVN_ PRN')
        n = n + 1;
        break
    end
end

%找出数据结尾
idx = find(contains(lines, '-BIAS/SOLUTION'));

charLines = char(lines(n:idx-1));

infOfGNSS = vertcat(charLines(:, 12));
GNSSType = unique(infOfGNSS);
infOfSta = vertcat(charLines(:, 16:19));
infOfCode = vertcat(charLines(:, 26:28));
infOfCode = [infOfCode, vertcat(charLines(:, 31:33))];

DCB = vertcat(charLines(:, 80:91));
RMS = vertcat(charLines(:, 92:103));

DCB = char2doubleIncludeNeg(DCB);
RMS = char2doubleExcludeNeg(RMS, 4);


% 分组数据
idx = all(infOfSta == ' ', 2);

% SDCB部分
Prn = vertcat(charLines(idx, 13:14));
Prn = char2doubleExcludeNeg(Prn, 0);

codeOfSat = infOfCode(idx, :);
DCBOfSat = DCB(idx);
RMSOfSat = RMS(idx);

for i = 1 : numel(GNSSType)
    indice = infOfGNSS(idx) == GNSSType(i);

    currentCode = codeOfSat(indice, :);
    currentDCB = DCBOfSat(indice);
    currentRMS = RMSOfSat(indice);
    currentPrn = Prn(indice);

    codeType = unique(currentCode, "rows");
    for j = 1 : size(codeType, 1)
        indice = all(currentCode == codeType(j, :), 2);
        finalDCB.Satellite.(GNSSType(i)).(codeType(j, :)) = ...
            [currentPrn(indice), currentDCB(indice)];
        finalRMS.Satellite.(GNSSType(i)).(codeType(j, :)) = ...
            [currentPrn(indice), currentRMS(indice)];
    end
end

% RDCB部分
codeOfSta = infOfCode(~idx, :);
DCBOfSta = DCB(~idx);
RMSOfSta = RMS(~idx);
infOfSta = infOfSta(~idx, :);

for i = 1 : numel(GNSSType)
    indice = infOfGNSS(~idx) == GNSSType(i);

    currentCode = codeOfSta(indice, :);
    currentDCB = DCBOfSta(indice);
    currentRMS = RMSOfSta(indice);
    currentSta = infOfSta(indice, :);

    codeType = unique(currentCode, "rows");
    for j = 1 : size(codeType, 1)
        indice = all(currentCode == codeType(j, :), 2);

        finalDCB.Receiver.(GNSSType(i)).(codeType(j, :)).Receiver = ...
            currentSta(indice, :);
        finalDCB.Receiver.(GNSSType(i)).(codeType(j, :)).Value = ...
            currentDCB(indice);
        finalRMS.Receiver.(GNSSType(i)).(codeType(j, :)).Receiver = ...
            currentSta(indice, :);
        finalRMS.Receiver.(GNSSType(i)).(codeType(j, :)).Value = ...
            currentRMS(indice);

    end
end

end

function result = char2doubleIncludeNeg(data)
% 将char格式的数据转换为double（四位小数）
weights = [logspace(6, 0, 7), 0, logspace(-1, -4, 4)]';
data = data - '0';

% 检查负号
idx = any(data == -3, 2);

data(data > 9 | data < 0) = 0;
result = data*weights;
result(idx) = -result(idx);

end

function result = char2doubleExcludeNeg(data, decimalPlaces)
% 将char格式的数据转换为double
totalLength = size(data, 2);
if decimalPlaces > 0
    weights = [logspace(totalLength-decimalPlaces-2, 0, totalLength-decimalPlaces-1), ...
        0, logspace(-1, -decimalPlaces, decimalPlaces)]';
else
    weights = logspace(totalLength-1, 0, totalLength)';
end
data = data - '0';

data(data > 9 | data < 0) = 0;
result = data*weights;

end