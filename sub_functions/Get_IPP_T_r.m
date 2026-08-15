function [b, s] = Get_IPP_T_r(E, A, B, L, H_Shell, R,T_r)
% b：穿刺点纬度，s：穿刺点经度
% E：高度角，A：方位角，B：测站的纬度，L：测站的经度
% H_shell：薄层假设的高度，R：测站海拔
z = asin(R.*sin((pi/2-E))./(R+H_Shell));
t = pi/2-E-z;
b = asin(sin(B).*cos(t)+cos(B).*sin(t).*cos(A));

s = nan(size(B));
Condition = (B >= 0 & tan(t).*cos(A) > tan(pi/2 - B)) | (B < 0 & -tan(t).*cos(A) > tan(pi/2 + B));
s(Condition) = L(Condition) - asin(sin(t(Condition)).*sin(A(Condition))./cos(b(Condition))) + pi;
s(~Condition) = L(~Condition) + asin(sin(t(~Condition)).*sin(A(~Condition))./cos(b(~Condition)));
% s = L + asin(sin(t).*sin(A)./cos(b));
%[b,s]=geo2mag(b,s);
s(s > pi) = s(s > pi) - 2*pi;
s(s < -pi) = s(s < -pi) + 2*pi;
s=s+T_r-pi;
end


function [Mlat,Mlon] = geo2mag(lat,lon)
% 将大地经纬度转化为地磁经纬度
% 磁极点取：经度72.2°W，纬度80.0°N（IGRF，2011）
% 输入及输出值为弧度制单位（rad）
% 2023/02/22 第一次修改：对输入IPP的经纬度数据是否是虚数进行判断，若为虚数，则直接赋值为nan
% 2023/10/28 第二次修改：将磁极点经纬度设为与CODE一致的80.33°和-72.67°
% 2024/05/15 第三次修改：对IPP经纬度数据为复数的情况进行了重新处理，
%                               当虚数部分较小时（小于0.1°），直接舍去虚数部分，取实数部分
%                               当虚数部分较大时（大于0.1°），则将该位置处直接设置为nan

% % 对输入的lat和lon是否为虚数进行判断
% if ~isreal(lat) | ~isreal(lon) %#ok<*OR2>
%     Mlat = nan(size(lat,1),size(lat,2),size(lat,3));
%     Mlon = nan(size(lon,1),size(lon,2),size(lon,3));
%     return
% end

% 对输入的lat和lon是否为虚数进行判断
if ~isreal(lat) | ~isreal(lon) %#ok<*OR2>

    % 搜索IPP经纬度中非0虚数的部分
    lat_imagPartidx = find(imag(lat));              % 搜索IPP纬度中非0虚数的部分
    lon_imagPartidx = find(imag(lon));            % 搜索IPP经度中非0虚数的部分
    imagPartidx = union(lat_imagPartidx, lon_imagPartidx);            % 取并集
    
    % 对非0虚数部分进行重新处理
    % 当非0虚数部分较大时，将该数值直接设置为nan
    if ~isempty(imagPartidx)
        [x,y,z] = ind2sub(size(lat), imagPartidx);              % 将一维位置信息转换为三维位置信息
        for I = 1 : length(x)
            ImagPart_lat = imag(lat(x(I),y(I),z(I)));              % 提取纬度的虚数部分
            ImagPart_lon = imag(lon(x(I),y(I),z(I)));            % 提取经度的虚数部分
            if abs(ImagPart_lat) > deg2rad(0.1) | abs(ImagPart_lon) > deg2rad(0.1)          % 虚部大于0.1°
                lat(x(I),y(I),z(I)) = nan;
                lon(x(I),y(I),z(I)) = nan;
            end
        end
    end
    
end

% 取IPP经纬度的实数部分
lat = real(lat);
lon = real(lon);

% CODE的磁极点经纬度
b = deg2rad(80.33);
l = deg2rad(-72.67);

% % XANG的磁极点经纬度
% b = deg2rad(80);
% l = deg2rad(-72.2);

% 以下公式基于刘长建，2011
% 计算地磁纬度
sb = sin(lat) .* sin(b) + cos(lat) .* cos(b) .* cos(lon - l);
Bm = asin(sb);

% 计算地磁经度
sl = cos(lat) .* sin(lon - l) ./ cos(Bm);
cl = (sin(b) .* sb - sin(lat)) ./ (cos(b) .* cos(Bm));
Lm = atan2(sl, cl);

% 地磁纬度/经度
Mlat = Bm;
Mlon = Lm;
end