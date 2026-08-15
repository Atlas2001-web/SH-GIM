function lastTwo = Get_yearLastTwo(time)

if isdatetime(time)
    timeYear = year(time);
elseif isscalar(time)
    timeYear = time;
end

lastTwo = mod(timeYear, 100);