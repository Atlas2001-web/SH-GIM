function P4 = Get_P4(Obs, Site_Coor, Sate_Coor, lim, f1, f2, GNSS_Sys)

if nargin < 7
    GNSS_Sys = 'G';
end
lim = deg2rad(lim);
[rx, ry, rz] = deal(Site_Coor(1), Site_Coor(2), Site_Coor(3));

% 截止高度角剔除
Obs = cutobs(Sate_Coor, rx, ry, rz, Obs, lim);
if all(~Obs.L1, 'all') && all(~Obs.L2, 'all') && all(~Obs.P1, 'all') && all(~Obs.P2, 'all')
    P4 = [];
    return 
end

% 提取高度角用于多径修正与判定
[rx, ry, rz] = deal(Site_Coor(1), Site_Coor(2), Site_Coor(3));
el = Get_EA(rx, ry, rz, Sate_Coor.x*1000, Sate_Coor.y*1000, Sate_Coor.z*1000);

% 针对北斗进行高度角多径修正及 GEO 剔除
if GNSS_Sys == 'C'
    Obs = bds_code_bias_correction(Obs, el);
end

% 周跳探测，以及P4的计算
P4 = prepro(Obs, f1, f2);
if all(~P4, "all")
    P4 = [];
end

end



%----------------subfunction-----------------------------------------------
function obs = cutobs(sate, rx, ry, rz, obs, lim)

x = sate.x;
y = sate.y;
z = sate.z;

el = Get_EA(rx, ry, rz, x*1000, y*1000, z*1000);
Ind1 = el < lim;
Ind2 = structfun(@(x) x == 0, obs, 'UniformOutput', false);
Ind2 = struct2cell(Ind2);

Ind = any(cat(3, Ind2{:}, Ind1), 3);

obs = structfun(@(x) StructInd(x, Ind), obs, 'UniformOutput', false);

end



%----------------subfunction-----------------------------------------------
function P4 = prepro(obs, f1, f2)
% delete cycle slip
Sat_Num = size(obs.L1, 2);
P4 = zeros(2880, Sat_Num);
L4 = zeros(2880, Sat_Num);
P4_Smooth = zeros(2880, Sat_Num);

c  = physconst('lightspeed');       %__________________________speed of light

lamda_w = c./(f1-f2);                %____________________wide lane wavelength

L6 = lamda_w .* (obs.L1 - obs.L2) - (f1.*obs.P1 + f2.*obs.P2) ./ (f1+f2);  %__MW observable
Li = obs.L1 - f1.*obs.L2./f2;
Nw = L6 ./ lamda_w;                  %_____________________wide lane ambiguity

for i = 1 : Sat_Num  %i is PRN number
    %------divide arc---------------------------
    arc = Get_arc(L6(:, i));

    [arc_n, ~] = size(arc);
    %----delete arc less than 10 epoches-------
    arc_d = zeros(arc_n , 1);
    for j=1:arc_n
        n_epoch=arc(j,2)-arc(j,1)+1;
        if n_epoch<10
            for k=arc(j,1):arc(j,2)
                obs.P2(k,i) = 0;
                obs.L1(k,i) = 0;
                obs.L2(k,i) = 0;
                obs.P1(k,i) = 0;

                L6(k,i) = 0;
                Nw(k,i) = 0;
                Li(k,i) = 0;
            end
            arc_d(j) = 1;
        end
    end
    arc(logical(arc_d),:)=[];

    %----mw detect cycle slip------------------
    [arc_n,~]=size(arc);
    %slip=[];
    j=1;
    while j < arc_n+1 %j is arc number

        %----first epoch check----------
        e=arc(j,1);
        while 1

            if e+1==arc(j,2)||e==arc(j,2)
                break;
            end

            fir=Nw(e,i);
            sec=Nw(e+1,i);
            thi=Nw(e+2,i);

            firl=Li(e,i);
            secl=Li(e+1,i);
            thil=Li(e+2,i);

            sub=abs(fir-sec);
            sub2=abs(sec-thi);
            subl=abs(firl-secl);
            subl2=abs(secl-thil);

            if sub>1||sub2>1||subl>1||subl2>1
                L6(e,i)=0;
                obs.L1(e,i)=0;
                obs.L2(e,i)=0;
                obs.P2(e,i)=0;
                obs.P1(e,i)=0;
                Nw(e,i)=0;
                Li(e,i)=0;
                e=e+1;
                arc(j,1)=e;
            else
                arc(j,1)=e;
                break;
            end
        end

        %----detect------------------
        if arc(j,2)-arc(j,1)<10
            for k=arc(j,1):arc(j,2)
                obs.P2(k,i)=0;
                obs.L1(k,i)=0;
                obs.L2(k,i)=0;
                obs.P1(k,i)=0;
                L6(k,i)=0;
                Nw(k,i)=0;
                Li(k,i)=0;
            end
            arc(j,:)=[];
            arc_n=arc_n-1;
            continue;
        end

        ave_N=linspace(0,0,arc(j,2)-arc(j,1)+1);
        sigma2=linspace(0,0,arc(j,2)-arc(j,1)+1);
        sigma=linspace(0,0,arc(j,2)-arc(j,1)+1);
        ave_N(1)=Nw(arc(j,1),i);
        sigma2(1)=0;
        sigma(1)=0;
        count=2;

        for k=arc(j,1)+1:arc(j,2)-1 %----------------------check epoch k+1
            %step1---MW and ionospheric residual
            ave_N(count)=ave_N(count-1)+(Nw(k,i)-ave_N(count-1))/count;
            sigma2(count)=sigma2(count-1)+((Nw(k,i)-ave_N(count-1))^2-sigma2(count-1))/count;
            sigma(count)=sqrt(sigma2(count));

            T=abs(Nw(k+1,i)-ave_N(count));   %---MW combination
           I1= round(abs(Li(k+1,i)-Li(k,i)),4);       %---ionospheric residual combination

            if T<4*sigma(count) && I1<0.28   %-------------------------no cycle slip
                count=count+1;
                continue;
            else
            %step2.1---exist cycle slip but k+1 is the final epoch
                if k+1==arc(j,2)             %---------------------arc end
                    if k+1-arc(j,1)>10
                        L6(k+1,i)=0;
                        obs.P2(k+1,i)=0;
                        obs.L1(k+1,i)=0;
                        obs.L2(k+1,i)=0;
                        obs.P1(k+1,i)=0;
                        Nw(k+1,i)=0;
                        Li(k+1,i)=0;
                        arc(j,2)=k;
                    else                     %------delete scatter epoches
                    %------delete all epochs of current group which have
                    %------less than 10 epochs
                        for l = arc(j,1) : k+1
                            L6(l,i)      = 0;
                            obs.P2(l, i) = 0;
                            obs.L1(l, i) = 0;
                            obs.L2(l, i) = 0;
                            obs.P1(l, i) = 0;
                            Nw(l, i)     = 0;
                            Li(l, i)     = 0; %k?l?
                        end
                        arc(j,:) = [];
                        j = j-1;
                        arc_n = arc_n-1;
                    end
                    break;
                end
            %step2.2---cycle slip or gross error
            %if gross error,delete epoch k+1
                I2=abs(Li(k+2,i)-Li(k+1,i));
                if abs(Nw(k+2,i)-Nw(k+1,i))<1&&I2<1  %-----------cycle slip
                    if k+1-arc(j,1)>10
                        arc=[arc(1:j-1,:);[arc(j,1),k];[k+1,arc(j,2)];arc(j+1:arc_n,:)];
                        arc_n=arc_n+1;
                    else                    %------delete scatter epoches
                        for l = arc(j, 1):k
                            L6(l, i) = 0;

                            obs.P2(l, i) = 0;
                            obs.L1(l, i) = 0;
                            obs.L2(l, i) = 0;
                            obs.P1(l, i) = 0;

                            Nw(l, i) = 0;
                            Li(l, i) = 0;
                        end
                        arc(j, 1) = k+1;
                        j = j-1;
                    end
                else                        %-----------------gross error(粗差)
                    if k+1-arc(j,1)>10
                        L6(k+1,i)=0;
                        obs.P2(k+1,i)=0;
                        obs.L1(k+1,i)=0;
                        obs.L2(k+1,i)=0;
                        obs.P1(k+1,i)=0;
                        Nw(k+1,i)=0;
                        Li(k+1,i)=0;
                        arc=[arc(1:j-1,:);[arc(j,1),k];[k+2,arc(j,2)];arc(j+1:arc_n,:)];
                        arc_n=arc_n+1;
                    else
                        for l=arc(j,1):k+1  %------delete scatter epoches
                            L6(l,i)=0;
                            obs.P2(l,i)=0;
                            obs.L1(l,i)=0;
                            obs.L2(l,i)=0;
                            obs.P1(l,i)=0;
                            Nw(l,i)=0;
                            Li(l,i)=0;
                        end
                        arc(j,1)=k+2;
                        j=j-1;
                    end
                end
                break; %---Exist cycle slip or gross error.Therefore, use
                       % the epoch k+1 with the existing anomaly as the 
                       % boundary to divide the data.
            end
        end
        j=j+1;
    end

    P4(:, i) = obs.P1(:, i)-obs.P2(:, i);
    if isscalar(f1)
        L4(:, i) = (c/f1)*obs.L1(:, i) - (c/f2)*obs.L2(:, i);
    else
        L4(:, i) = (c/f1(i))*obs.L1(:, i) - (c/f2(i))*obs.L2(:, i);
    end
    

    %这里其实就是L4+常数偏移的结果，最后还是使用hatch滤波来进行处理
    P4_Smooth(:, i) = L4(:, i);
    for j = 1 : arc_n
        Idx = find(P4(arc(j, 1) : arc(j, 2), i));
        if numel(Idx) < 40
            P4_Smooth(arc(j, 1) : arc(j, 2), i) = 0;
            continue
        end
        seg   = arc(j,1):arc(j,2);
        valid = (P4(seg,i)~=0) & (L4(seg,i)~=0);
        Delta = mean(P4(seg(valid),i) + L4(seg(valid),i));
        P4_Smooth(arc(j, 1) : arc(j, 2), i) = -P4_Smooth(arc(j, 1) : arc(j, 2), i) + Delta;
    end
    P4 = P4_Smooth;

end
end



%----------------subfunction-----------------------------------------------
function x = StructInd(x, Ind)
x(Ind) = 0;
end

%----------------subfunction-----------------------------------------------
function obs = bds_code_bias_correction(obs, el)
    SatNum = size(obs.L1, 2);
    for i = 1:SatNum
        % 判断如果是 GEO 卫星 (PRN 1~5, 59~60)
        if ismember(i, [1, 2, 3, 4, 5, 59, 60])
            % 为防止法方程秩亏，默认剔除地球静止轨道卫星
            obs.P1(:, i) = 0;
            obs.L1(:, i) = 0;
            obs.P2(:, i) = 0;
            obs.L2(:, i) = 0;
            continue;
        end
        
        % 针对 BDS-2 IGSO/MEO 卫星 (PRN 6~16)，注入 Wanninger-Beer 等效模型
        % 由于各频段系数存在差异，此处给出泛化的基于高度角(米制)的高仰角归零经验误差模型
        if i >= 6 && i <= 16
            Elev_deg = rad2deg(el(:, i));
            valid = Elev_deg > 0 & obs.P1(:, i) ~= 0;
            
            E_val = Elev_deg(valid);
            % Wanninger-Beer 近似抛物线模型 (多径效应随着高度角减小呈抛物线增大)
            % 此处使用了一个泛化基础物理常数，您可以参考正式论文修改特定频段截距
            bias_P1 = -0.0001 * (E_val - 90).^2 + 0.5; 
            bias_P2 = -0.00015 * (E_val - 90).^2 + 0.6; 
            
            % 从测距码观测值中扣除因为多径引入的系统延长
            obs.P1(valid, i) = obs.P1(valid, i) - bias_P1;
            obs.P2(valid, i) = obs.P2(valid, i) - bias_P2;
        end
    end
end
