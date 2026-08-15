function [doy , current_year]=day2doy(day)

if isnumeric(day)

    doy = floor(datenum(day)-datenum(day(1),1,1)+1);
    current_year = day(1);

elseif isdatetime(day)
    
    doy = floor(datenum(day) - datenum(year(day) , 1 , 1) + 1);
    current_year = year(day);

end

