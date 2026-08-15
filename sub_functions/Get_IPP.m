function [b, s] = Get_IPP(E, A, B, L, H_Shell, R)
% b：穿刺点纬度，s：穿刺点经度
% E：高度角，A：方位角，B：测站的纬度，L：测站的经度
% H_shell：薄层假设的高度，R：测站海拔
z = asin(R.*sin((pi/2-E))./(R+H_Shell));
t = pi/2-E-z;
b = asin(sin(B).*cos(t)+cos(B).*sin(t).*cos(A));

% s = L + asin(sin(t).*sin(A)./cos(b));

s = nan(size(B));
Condition = (B >= 0 & tan(t).*cos(A) > tan(pi/2 - B)) | (B < 0 & -tan(t).*cos(A) > tan(pi/2 + B));
s(Condition) = L(Condition) - asin(sin(t(Condition)).*sin(A(Condition))./cos(b(Condition))) + pi;
s(~Condition) = L(~Condition) + asin(sin(t(~Condition)).*sin(A(~Condition))./cos(b(~Condition)));

s(s > pi) = s(s > pi) - 2*pi;
s(s < -pi) = s(s < -pi) + 2*pi;

end