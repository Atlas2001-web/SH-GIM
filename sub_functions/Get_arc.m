function arc = Get_arc(array)

len = length(array);
arc = [];
for i = 1:len
    if i == len
        if array(i) ~= 0
            arc = [arc, i];
        end
        continue;
    end
    if i == 1 && array(i) ~= 0
        arc = [arc, i];
    end
    if array(i) == 0 && array(i+1) ~= 0
        arc = [arc, i+1];
        continue;
    end
    if array(i) ~=0 && array(i+1) == 0
        arc = [arc, i];
        continue;
    end
end

if len == 0
    return
end

arc = reshape(arc, 2, [])';

end

