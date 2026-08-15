function Matrix=Get_Matrix(Current_GNSS, Group_Name, ...
    Current_SDCB_Idx, Current_Sat_Idx, RDCB_Idx, ...
    cof_, Cur_Sat_X, Cur_Sat_Y, Cur_Sat_Z, stations, Coor, list_obs, Time, P4_Folder, ...
    Add_FigNum, R, Height,TimeRes,n_r,ObsStride)
if nargin < 20 || isempty(ObsStride)
    ObsStride = 1;
end
Matrix_sub=cell(1,n_r);
parfor m = 1 : n_r
    site = list_obs(m).name(1:4);
    Matrix_sub{m} = Calculate_Single_Station_2(Current_GNSS, Group_Name, ...
        Current_SDCB_Idx, Current_Sat_Idx, RDCB_Idx, ...
        cof_, Cur_Sat_X, Cur_Sat_Y, Cur_Sat_Z, stations, Coor, site, Time, P4_Folder, ...
        Add_FigNum, R, Height,TimeRes,ObsStride);
end
Matrix=vertcat(Matrix_sub{:});


end







function Matrix_sub_sub = Calculate_Single_Station_2(GNSS_Name, ...
    Group_Name, Current_SDCB_Idx, Current_Sat_Idx, RDCB_Idx, ...
    cof_, Sat_X, Sat_Y, Sat_Z, stations, Coor, site, Time, P4_Folder, ...
    Add_FigNum, R, Height,TimeRes,ObsStride)
Matrix_sub_sub=[];
% =============================================================
% 閫氳繃娴嬬珯鍚嶇О鑾峰彇鍓嶅悗鍏变笁澶╃殑鏁版嵁
%浠庤繖閲屽紑濮嬭繘琛孲RBF鐨勯噸鏂板缓妯?
P4_Cell = cell(1, 3);
Keep_Run = false;  %榛樿涓?
for k = [0, -1, 1]
    Current_Time = Time + days(k);
    File_Name = sprintf('%02d%03d/%sP4.mat', ...
        Get_yearLastTwo(Current_Time), day2doy(Current_Time), site);
    File_Name = fullfile(P4_Folder, File_Name);
    if k == 0
        load(File_Name, 'P4')
        if isfield(P4, GNSS_Name) && isfield(P4.(GNSS_Name), Group_Name)
            Data = P4.(GNSS_Name).(Group_Name);
            Sat_Num = size(Data, 2);
            P4_Cell{k + 2} = Data;
            Keep_Run = true; % 褰撳墠绔欑偣瀛樺湪璇NSS鐨勮娴嬪€肩粍鍚堬紝缁х画澶勭悊璇ョ珯鐐?
        else
            Keep_Run=false;
            break
        end
    else
        if ~exist(File_Name, 'file')
            % 鍒涘缓闆剁煩闃碉紝淇濇寔涓庡崼鏄熺煩闃靛悓鏍风殑澶у皬
            P4_Cell{k+2} = zeros(2880, Sat_Num);
        else
            load(File_Name, 'P4')
            if isfield(P4, GNSS_Name) && isfield(P4.(GNSS_Name), Group_Name)
                Current_P4 = P4.(GNSS_Name).(Group_Name);
                % 鍓嶄竴澶╃殑鏁版嵁锛屼娇鐢ㄧ粨鏉烝dd_FigNum骞呯殑鏁版嵁
                P4_Cell{k+2} = Current_P4;
            else
                % 鍓嶅悗涓ゅぉ鐨勬暟鎹腑锛屼笉瀛樺湪褰撳墠瑙傛祴鍊肩粍鍚堬紙涓€鑸笉鍙兘锛?
                P4_Cell{k+2} = zeros(2880, Sat_Num);
            end
        end
    end
    % 閬嶅巻涓€澶╃殑鏁版嵁
end

% 褰撳墠绔欑偣涓嶅瓨鍦ㄨGNSS闇€姹傜殑瑙傛祴鍊肩粍鍚堬紝璺宠繃璇ョ珯鐐?
if ~Keep_Run
    return
end

for i=1:3
    P4_Cell{1,i}(:,Current_Sat_Idx)=[];
end
% =============================================================
% 鑾峰彇褰撳墠绔欑偣鐨勫潗鏍?
Idx = find(strcmpi(site, stations), 1);
Receiver_X = Coor(Idx, 1);
Receiver_Y = Coor(Idx, 2);
Receiver_Z = Coor(Idx, 3);
Current_RDCB_Idx = RDCB_Idx.(GNSS_Name).(Group_Name).(site);   %鑾峰彇娴嬬珯鐨凞CB绱㈠紩浣嶇疆
%杩欓噷杩涜for寰幆鏉ヨ繘琛屽鐞嗕笉鍚屽ぉ鏁扮殑娉曟柟绋嬫瀯寤烘祦绋?
Matrix_sub_x=cell(1,3);
for i=1:3
    % =============================================================
    P4=P4_Cell{1,i};
    if all(P4(:)==0)
        continue;
    end
    temp_Sat_X=Sat_X(2880*(i-1)+1:2880*i,:);
    temp_Sat_Y=Sat_Y(2880*(i-1)+1:2880*i,:);
    temp_Sat_Z=Sat_Z(2880*(i-1)+1:2880*i,:);
    Matrix_sub_x{i} = Get_Matrix_sub(P4, temp_Sat_X, temp_Sat_Y, temp_Sat_Z, ...
        Receiver_X, Receiver_Y, Receiver_Z, ...
        Current_RDCB_Idx, Current_SDCB_Idx, ...
        cof_, R, Height,TimeRes,i,Add_FigNum,ObsStride);
    


end
Matrix_sub_sub=vertcat(Matrix_sub_x{:});
end


function Matrix_sub_sub = Get_Matrix_sub(P4, sat_x, sat_y, sat_z, rec_x, rec_y, rec_z, ...
    RDCB_Idx, SDCB_Idx, cof_, ...
    R, Height,TimeRes,ep,add_time,ObsStride)
% 灏嗘帴鏀舵満绗涘崱灏斿潗鏍囪浆鎹负澶у湴鍧愭爣锛堢含搴︺€佺粡搴︺€侀珮搴︼級
[rec_b, rec_l] = XYZtoBLH_kent(rec_x, rec_y, rec_z);
SatNum = size(P4, 2);
Data_SDCB_Idx = SDCB_Idx(1) : SDCB_Idx(2);     %鑾峰彇浜嗚繖棰楀崼鏄熺殑DCB浣嶇疆绱㈠紩淇℃伅
[~,~,~,starttime,endtime] = get_temp(ep, add_time);  %ep鏄ぉ鏁?addtime鏄坊鍔犵殑鏃堕棿
Matrix_su = cell(1, endtime - starttime + 1);
indx = 1;
for t = starttime:endtime      %23.24     1.2
    % This loop only extracts observation records for the active SH solver.
    Matrix_sub = cell(1, SatNum);
    for i = 1:SatNum
        if ~isscalar(cof_)
            cof = cof_(i);
        else
            cof = cof_;
        end

        time_P4 = P4(1 + (t - 1) * TimeRes : t * TimeRes, i);
        obs_idx = find(time_P4 ~= 0);
        if isempty(obs_idx)
            continue;
        end
        if ObsStride > 1
            obs_idx = obs_idx(1:ObsStride:end);
        end

        n = numel(obs_idx);
        temp_alfa2 = zeros(n, 1);
        temp_alfa1 = zeros(n, 1);
        lon = zeros(n, 1);
        lat = zeros(n, 1);
        R_DCB = zeros(n, 1);
        S_DCB = zeros(n, 1);
        temp_angle = zeros(n, 1);
        temp_p = zeros(n, 1);
        temp_cof = zeros(n, 1);
        temp_cos = zeros(n, 1);

        time_window_start = TimeRes * t - (TimeRes - 1);
        for q = 1:n
            k = time_window_start + obs_idx(q) - 1;
            [E, A] = Get_EA_kent(rec_x, rec_y, rec_z, sat_x(k,i) * 1000, sat_y(k,i) * 1000, sat_z(k,i) * 1000);
            IPPz = asin(R * sin(pi / 2 - E) / (R + Height));
            t_r = 30 * (k - 1) * pi / 43200;
            [b, s] = Get_IPP_kent(E, A, rec_b, rec_l, IPPz, t_r);
            temp_angle(q) = E;  %鑾峰彇杩欓噷闈㈢殑楂樺害瑙?
            lon(q) = s;
            lat(q) = b;
            temp_p(q) = P4(k, i);
            R_DCB(q) = RDCB_Idx;
            S_DCB(q) = Data_SDCB_Idx(i);
            temp_alfa1(q) = (k - ((TimeRes * t) - (TimeRes - 1))) / TimeRes;
            temp_alfa2(q) = 1 - temp_alfa1(q, 1);
            temp_cof(q) = cof;
            %temp_cos(q)=cos(IPPz);
            temp_cos(q) = sqrt(1 - (R * sin(0.9782 * (pi / 2 - E)) / (R + Height))^2);
        end
        %ep ,t,lon,lat,angle,S_dcb,R_dcb,P4,t_alfa1,t_alfa2,cof,cos(IPPz)
        temp_ep = ep * ones(n, 1);
        temp_t = t * ones(n, 1);
        Matrix_sub{i} = [temp_ep,temp_t,lon,lat,temp_angle,S_DCB,R_DCB,temp_p,temp_alfa1,temp_alfa2,...
            temp_cof,temp_cos];
    end
    Matrix_su{indx} = vertcat(Matrix_sub{:});
    indx = indx + 1;
end
%杩欓噷鏄珮搴﹁鐨勫鐞嗚繃绋?
Matrix_sub_sub = vertcat(Matrix_su{:});
end

function[localM,localL,localP,starttime,endtime]=get_temp(ep,addtime)

if ep==1
    localM = cell(addtime, 1);
    localL = cell(addtime, 1);
    localP=cell(addtime,1);
    starttime=24-addtime+1;  %23   23
    endtime=24;         %24
elseif ep==2
    localM = cell(24, 1);
    localL = cell(24, 1);
    localP=cell(24,1);
    starttime=1;  %1
    endtime=24;     %24
elseif ep==3
    localM = cell(addtime, 1);
    localL = cell(addtime, 1);
    localP=cell(addtime,1);
    starttime=1;  %1
    endtime=addtime;  %23
end
end
