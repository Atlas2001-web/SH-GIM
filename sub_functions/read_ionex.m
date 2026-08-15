function [SDCB_REF,Sites_Info]=read_ionex(i_ipath,Sites_Info)

doys=unique(Sites_Info.doy);
n_d=length(doys);
len=length(Sites_Info.name);
Sites_Info.RDCB_REF=linspace(0,0,len);
SDCB_REF.value=zeros(n_d,32);
SDCB_REF.doy=linspace(0,0,n_d);
list=dir([i_ipath '/*.*i*']);
for i=1:n_d
    index=find_ionex(list,doys(i));
    index2= Sites_Info.doy==doys(i);
    [DCB_rec,SDCB_REF.value(i,:)]=r_ionex([i_ipath '/' list(index).name],Sites_Info.name(index2));
    Sites_Info.RDCB_REF(index2)=DCB_rec;
    SDCB_REF.doy(i)=doys(i);
end
end
%-------------------------------sub function-------------------------------
function [DCB_rec,DCB_sat]=r_ionex(fpath,sites)
fid=fopen(fpath,'r');
n_r=length(sites);
DCB_rec=linspace(0,0,n_r);
DCB_sat=linspace(0,0,32);
flag=0;
while 1
    line=fgetl(fid);
    if ~ischar(line), break, end
    if flag==1,break,end
    if length(line)>76&&strcmpi(line(61:77),'START OF AUX DATA')
        flag=1;
        line=fgetl(fid);
        while 1
            if length(line)>74&&strcmpi(line(61:75),'END OF AUX DATA'),break,end
            %--satellites' DCB
            if length(line)>75&&(strcmpi(line(4),'G')||strcmpi(line(4),' '))&&strcmpi(line(61:76),'PRN / BIAS / RMS')
                prn=str2double(line(5:6));
                DCB_sat(prn)=str2double(line(10:16));
                line=fgetl(fid);
                continue;
            end
            %--receivers' DCB
            if length(line)>10&&(strcmpi(line(4),'G')||strcmpi(line(4),' '))&&strcmpi(line(61:80),'STATION / BIAS / RMS')
                index=find(strcmpi(line(7:10),sites), 1);
                if ~isempty(index)
                    DCB_rec(index)=str2double(line(30:36));
                end
            end
            line=fgetl(fid);
        end    
    end
end
fclose(fid);
end

