function Write_Ionex(Ionex_File_Name, GIMs, DCB_S, DCB_R, Time, Time_Res, ...
    FigNum, Cutoff_Ele, Lat_Res, Lon_Res, R, Height, Western_Edge, ...
        Eastern_Edge, Nothern_Edge, Southern_Edge)

fid = fopen(Ionex_File_Name, 'w');
Clean_Obj = onCleanup(@() fclose(fid));


% =========================================================================
fprintf(fid, '%8.1f%+12s%+1s%+19s%+3s%+17sIONEX VERSION / TYPE\n', ...
    1, '', 'I', '', 'MIX', '');

Current_Time = datetime('now');
Current_Time = string(Current_Time, 'uuuu-MM-dd HH:mm:SS');
fprintf(fid, '%-20s%-20s%-20sPGM / RUN BY / DATE\n', ...
    'GNSS_TEC1.0', 'XAN/LMD', Current_Time);

T1 = Time;
fprintf(fid, '%6d%6d%6d%6d%6d%6d%24sEPOCH OF FIRST MAP\n', ...
    year(T1), month(T1), day(T1), hour(T1), minute(T1), second(T1), '');

T2 = Time+days(1);
fprintf(fid, '%6d%6d%6d%6d%6d%6d%24sEPOCH OF LAST MAP\n', ...
    year(T2), month(T2), day(T2), hour(T2), minute(T2), second(T2), '');

fprintf(fid, '%6d%54sINTERVAL\n', Time_Res, '');

fprintf(fid, '%6d%54s# OF MAPS IN FILE\n', FigNum, '');

fprintf(fid, '%2s%4s%54sMAPPING FUNCTION\n', '', 'COSZ', '');

fprintf(fid, '%8.1f%52sELEVATION CUTOFF\n', Cutoff_Ele, '');

fprintf(fid, '%-60sOBSERVABLES USED\n', 'One-way carrier phase leveled to code');

%璇诲彇绔欑偣鏁伴噺鍜屽崼鏄熸暟閲?
Prn = cell(0, 1);
Station = cell(0, 1);
GNSS = fieldnames(DCB_S);
for i = 1 : numel(GNSS)

    Code = fieldnames(DCB_S.(GNSS{i}));
    for j = 1 : numel(Code)
        Prn = union({DCB_S.(GNSS{i}).(Code{j})(:).Prn}, Prn);

        Station = union({DCB_R.(GNSS{i}).(Code{j})(:).station}, Station);
    end
end

fprintf(fid, '%6d%54s# OF STATIONS\n', numel(Station),  '');

fprintf(fid, '%6d%54s# OF SATELLITES\n', numel(Prn), '');

fprintf(fid, '%8.1f%52sBASE RADIUS\n', R/1000, '');

fprintf(fid, '%6d%54sMAP DIMENSION\n', 1, '');

fprintf(fid, '%2s%6.1f%6.1f%6.1f%40sHGT1 / HGT2 / DHGT\n', '', Height/1000, Height/1000, 0, '');

fprintf(fid, '%2s%6.1f%6.1f%6.1f%40sLAT1 / LAT2 / DLAT\n', ...
    '', Nothern_Edge, Southern_Edge, -Lat_Res, '');

fprintf(fid, '%2s%6.1f%6.1f%6.1f%40sLON1 / LON2 / DLON\n', ...
    '', Western_Edge, Eastern_Edge, Lon_Res, '');

fprintf(fid, '%6d%54sEXPONENT\n', -1, '');

fprintf(fid, '%-60sSTART OF AUX DATA\n', 'DIFFERENTIAL CODE BIASES');

% 鍐欏叆DCB
GNSS = fieldnames(DCB_S);
for i = 1 : numel(GNSS)

    switch GNSS{i}
        case 'G'
            GNSS_Name = 'GPS';
        case 'R'
            GNSS_Name = 'GLONASS';
        case 'C'
            GNSS_Name = 'BeiDou';
        case 'E'
            GNSS_Name = 'Galileo';
    end
    
    Code = fieldnames(DCB_S.(GNSS{i}));
    for j = 1 : numel(Code)
        Code_Name1 = Code{j}(1:3);
        Code_Name2 = Code{j}(4:6);

        fprintf(fid, '%-26s%-7s%1s%1s%3s%1s%3s%18sCOMMENT\n', ...
            'Reference observables for', GNSS_Name, ':', '', Code_Name1, ...
            '-', Code_Name2, '');

        % 鍐欏叆鍗槦DCB
        Current_DCB = DCB_S.(GNSS{i}).(Code{j});

        for k = 1 : numel(Current_DCB)
            Prn = Current_DCB(k).Prn;
            Bias = normalize_ionex_scalar(Current_DCB(k).DCB);
            RMS = normalize_ionex_scalar(Current_DCB(k).RMS); % 鍚庣画娣诲姞

            fprintf(fid, '%+6s%10.3f%10.3f%34sPRN / BIAS / RMS\n', Prn, Bias, RMS, '');
        end

        % 鍐欏叆鎺ユ敹鏈篋CB
        Current_DCB = DCB_R.(GNSS{i}).(Code{j});
        
        for k = 1 : numel(Current_DCB)
            Station = Current_DCB(k).station;
            Bias = normalize_ionex_scalar(Current_DCB(k).DCB);
            RMS = normalize_ionex_scalar(Current_DCB(k).RMS); % 鍚庣画

            fprintf(fid, '%+4s%+6s%1s%9s%6s%10.3f%10.3f%14sSTATION / BIAS / RMS\n', ...
                GNSS{i}, Station, '', '*********', '', Bias, RMS, '');
        end
       
    end
end

fprintf(fid, '%-60sEND OF AUX DATA\n', 'DIFFERENTIAL CODE BIASES');
fprintf(fid, '%60sEND OF HEADER\n', '');

% 鍐欏叆VTEC
VTEC = GIMs.VTEC;
Fig_Time = @(x) Time + Time_Res/3600.*hours(x);
Fig_Time = Fig_Time(0:size(VTEC, 3)-1);

Data_Lat = Nothern_Edge : -Lat_Res : Southern_Edge;

for i = 1 : size(VTEC, 3)
    fprintf(fid, '%6d%54sSTART OF TEC MAP\n', i, '');

    fprintf(fid, '%6d%6d%6d%6d%6d%6d%24sEPOCH OF CURRENT MAP\n', ...
        year(Fig_Time(i)), month(Fig_Time(i)), day(Fig_Time(i)), ...
        hour(Fig_Time(i)), minute(Fig_Time(i)), second(Fig_Time(i)), '');

    for j = 1 : size(VTEC, 1)
        fprintf(fid, '%2s%6.1f%6.1f%6.1f%6.1f%6.1f%28sLAT/LON1/LON2/DLON/H\n', ...
            '', Data_Lat(j), Western_Edge, Eastern_Edge, Lon_Res, Height/1000, '');

        for k = 1 : 16 : size(VTEC, 2)
            Idx_End = min(k + 16 -1, size(VTEC, 2));
            Current_Data = round(VTEC(j, k:Idx_End, i)*10);

            fprintf(fid, [repmat('%5d', 1, numel(Current_Data)), '\n'], Current_Data);
        end
    end

    fprintf(fid, '%6d%54sEND OF TEC MAP\n', i, '');

end


% 鍐欏叆RMS
RMS = GIMs.RMS;
for i = 1 : size(RMS, 3)
    fprintf(fid, '%6d%54sSTART OF RMS MAP\n', i, '');

    fprintf(fid, '%6d%6d%6d%6d%6d%6d%24sEPOCH OF CURRENT MAP\n', ...
        year(Fig_Time(i)), month(Fig_Time(i)), day(Fig_Time(i)), ...
        hour(Fig_Time(i)), minute(Fig_Time(i)), second(Fig_Time(i)), '');

    for j = 1 : size(RMS, 1)
        fprintf(fid, '%2s%6.1f%6.1f%6.1f%6.1f%6.1f%28sLAT/LON1/LON2/DLON/H\n', ...
            '', Data_Lat(j), Western_Edge, Eastern_Edge, Lon_Res, Height/1000, '');

        for k = 1 : 16 : size(RMS, 2)
            Idx_End = min(k + 16 -1, size(RMS, 2));
            Current_Data = round(RMS(j, k:Idx_End, i)*10);

            fprintf(fid, [repmat('%5d', 1, numel(Current_Data)), '\n'], Current_Data);
        end
    end

    fprintf(fid, '%6d%54sEND OF RMS MAP\n', i, '');

end

fprintf(fid, '%60sEND OF FILE\n', '');
end

function value = normalize_ionex_scalar(value)
value = full(value);
value = double(value(1));
end
