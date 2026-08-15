function [b, s] = Get_IPP_kent(E, A, B, L, z, t_r)
t = pi / 2 - E - z;
b = asin(cos(t) * sin(B) + sin(t) * cos(B) * cos(A));

if (B > deg2rad(70) && tan(t) * cos(A) > tan(pi / 2 - B)) || ...
        (B < -deg2rad(70) && -tan(t) * cos(A) > tan(pi / 2 + B))
    s = L + pi - asin(sin(t) * sin(A) / cos(b));
else
    s = L + asin(sin(t) * sin(A) / cos(b));
end

s = mod(s + pi, 2 * pi) - pi;
[b, s] = geo2mag(b, s);
s = s + t_r - pi;
s = mod(s + pi, 2 * pi) - pi;
end
