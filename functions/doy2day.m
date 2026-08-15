function day=doy2day(doy)

if nargin < 1
    doy = [2022 1];
end

JulianDay = juliandate(datetime([doy(1), 1, 1])) + doy(2) - 1;
day = datetime(JulianDay, 'ConvertFrom', 'juliandate');
% julian_day=juliandate(doy(1),1,1)+doy(2)-1;
% day=datetime(julian_day,"ConvertFrom",'juliandate');



