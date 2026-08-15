function [doy, current_year] = GPSWeek2DOY(GPSWeek, GPSSec)

start_time = datetime([1980, 1, 6]);
date = start_time + days(GPSWeek*7) + seconds(GPSSec);
current_year = year(date);
doy = floor(datenum(date) - datenum(current_year , 1 , 1) + 1);
