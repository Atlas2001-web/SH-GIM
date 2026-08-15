function A = Get_SHDesignMatrix(UT, Lat, Lon, order, coord_mode)
if nargin < 5
    coord_mode = 'geo_deg';
end

switch coord_mode
    case 'geo_deg'
        Lat_Rad = deg2rad(Lat);
        Lon_Rad = deg2rad(Lon);
        [Lat_Rad, Lon_Rad] = geo2mag(Lat_Rad, Lon_Rad);
        Lon_Rad = Lon_Rad + (UT - 12) * 15 * pi / 180;
    case 'solar_magnetic_rad'
        Lat_Rad = Lat;
        Lon_Rad = Lon;
    otherwise
        error('Get_SHDesignMatrix:InvalidCoordMode', 'Unsupported coordinate mode.');
end

Lon_Rad = mod(Lon_Rad + pi, 2 * pi) - pi;

ms = Lon_Rad * (0:order);
x = sin(Lat_Rad);
Cof_cos = cos(ms)';
Cof_sin = sin(ms)';

N = zeros(sum(1:order + 1), 1);
P = zeros(numel(N), numel(Lat_Rad));
Ind = zeros(size(N));
for n = 0 : order
    P_Pos = sum(1:n) + 1 : sum(1:n + 1);
    P(P_Pos, :) = legendre(n, x);
    Ind(P_Pos) = 1 : n + 1;

    for m = 0 : n
        if m == 0
            N(P_Pos(m + 1)) = sqrt(factorial(n - m) * (2 * n + 1) / factorial(n + m));
        else
            N(P_Pos(m + 1)) = sqrt(factorial(n - m) * (4 * n + 2) / factorial(n + m));
        end
    end
end
P = P .* N;

Cof_cos = Cof_cos(Ind, :) .* P;
Cof_sin = Cof_sin(Ind, :) .* P;
A = zeros(size(Cof_sin, 1) * 2, size(Cof_sin, 2));
A(1:2:end) = Cof_cos;
A(2:2:end) = Cof_sin;
A(all(A == 0, 2), :) = [];
A = A';
end
