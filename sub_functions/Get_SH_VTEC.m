function [VTEC, RMS] = Get_SH_VTEC(SH_Cof, Lat, Lon, Time, D)
order = sqrt(numel(SH_Cof)) - 1;
if fix(order) ~= order
    error('Get_SH_VTEC:InvalidCoefficientCount', ...
        'The spherical-harmonic coefficient count is inconsistent with the model order.');
end

Cof = Get_SHDesignMatrix(Time, Lat, Lon, order);

VTEC = Cof * SH_Cof;
VTEC(VTEC < 0) = 0.5;

if isvector(D)
    RMS = sqrt(sum((Cof .^ 2) .* reshape(D, 1, []), 2) * 100);
else
    RMS = sqrt(diag(Cof * D * Cof' * 100));
end
RMS = RMS(:);
end
