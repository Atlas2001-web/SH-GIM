function Initialize_Folder(Folder,Start_Time,End_Time,file)

% if strcmp(file,'obs')
    Start_Time=Start_Time-days(1);
    End_Time=End_Time+days(1);
% end
for T=Start_Time:End_Time
    F_year=string(year(T));
    F_doy=day2doy(T);
    year_char = char(F_year);
    target_name=sprintf('%s%03d',year_char(3:4),F_doy);
    target_path=fullfile(Folder,target_name);
    if exist(target_path,'dir')
        rmdir(target_path, 's');
    end

end
end