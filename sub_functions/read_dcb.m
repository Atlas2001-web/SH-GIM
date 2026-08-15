function DCB=read_dcb(pathname)

if nargin < 1
    pathname = 'F:\dcb\2023\CAS0MGXRAP_20230010000_01D_01D_DCB.BSX';
end

fid = fopen(pathname);

satellite_data_num = 0;

receiver_data_num = 0;

satellite_data_line{2000} = [];

receiver_data_line{8000} = [];

line = fgetl(fid);

while ~contains(line,'BIAS SVN_ PRN STATION__')

    line = fgetl(fid);

end

line = fgetl(fid);

GDSB_satel_num = 0;
EDSB_satel_num = 0;
CDSB_satel_num = 0;
RDSB_satel_num = 0;

while line(2:4)=="DSB"&&line(16)==' '

    satellite_data_num = satellite_data_num+1;

    satellite_data_line{satellite_data_num} = line;

    switch line(7)

        case 'G'
            GDSB_satel_num = GDSB_satel_num+1;
        case 'R'
            RDSB_satel_num = RDSB_satel_num+1;
        case 'E'
            EDSB_satel_num = EDSB_satel_num+1;
        case 'C'
            CDSB_satel_num = CDSB_satel_num+1;
   
    end

    line = fgetl(fid);

end

GDSB_rec_num = 0;
EDSB_rec_num = 0;
CDSB_rec_num = 0;
RDSB_rec_num = 0;

while 1

    if any(line(2:4)~="DSB")||any(contains(line,'-BIAS/SOLUTION '))

        break

    end

    switch line(7)
       
        case 'G'
            GDSB_rec_num = GDSB_rec_num+1;
        case 'R'
            RDSB_rec_num = RDSB_rec_num+1;
        case 'E'
            EDSB_rec_num = EDSB_rec_num+1;
        case 'C'
            CDSB_rec_num = CDSB_rec_num+1;
   
    end

    receiver_data_num = receiver_data_num+1;
    
    receiver_data_line{receiver_data_num} = line;

    line = fgetl(fid);

end

satellite_data_line(cellfun(@isempty,satellite_data_line)) = [];

receiver_data_line(cellfun(@isempty,receiver_data_line)) = [];

GDSB_satel_data{GDSB_satel_num,3} = [];
EDSB_satel_data{EDSB_satel_num,3} = [];
RDSB_satel_data{RDSB_satel_num,3} = [];
CDSB_satel_data{CDSB_satel_num,3} = [];

GNUM = 0;
RNUM = 0;
ENUM = 0;
CNUM = 0;
num = 0;

for i = 1:satellite_data_num

    num = num+1;

    switch satellite_data_line{num}(7)
        case 'G'
            GNUM = GNUM+1;
            GDSB_satel_data{GNUM,1} = sscanf(satellite_data_line{num}(12:33),'%s');
            GDSB_satel_data{GNUM,2} = sscanf(satellite_data_line{num}(80:91),'%f');
            GDSB_satel_data{GNUM,3} = sscanf(satellite_data_line{num}(95:103),'%f');
        case 'E'
            ENUM = ENUM+1;
            EDSB_satel_data{ENUM,1} = sscanf(satellite_data_line{num}(12:33),'%s');
            EDSB_satel_data{ENUM,2} = sscanf(satellite_data_line{num}(80:91),'%f');
            EDSB_satel_data{ENUM,3} = sscanf(satellite_data_line{num}(95:103),'%f');
        case 'R'
            RNUM = RNUM+1;
            RDSB_satel_data{RNUM,1} = sscanf(satellite_data_line{num}(12:33),'%s');
            RDSB_satel_data{RNUM,2} = sscanf(satellite_data_line{num}(80:91),'%f');
            RDSB_satel_data{RNUM,3} = sscanf(satellite_data_line{num}(95:103),'%f');
        case 'C'
            CNUM = CNUM+1;
            CDSB_satel_data{CNUM,1} = sscanf(satellite_data_line{num}(12:33),'%s');
            CDSB_satel_data{CNUM,2} = sscanf(satellite_data_line{num}(80:91),'%f');
            CDSB_satel_data{CNUM,3} = sscanf(satellite_data_line{num}(95:103),'%f');

    end

end

GNUM = 0;
RNUM = 0;
ENUM = 0;
CNUM = 0;
num = 0;

GDSB_rec_data{GDSB_rec_num,3} = [];
EDSB_rec_data{EDSB_rec_num,3} = [];
RDSB_rec_data{RDSB_rec_num,3} = [];
CDSB_rec_data{CDSB_rec_num,3} = [];

for i = 1:receiver_data_num

    num = num+1;

    switch receiver_data_line{num}(7)
        case 'G'
            GNUM = GNUM+1;
            GDSB_rec_data{GNUM,1} = sscanf(receiver_data_line{num}(16:33),'%s');
            GDSB_rec_data{GNUM,2} = sscanf(receiver_data_line{num}(80:91),'%f');
            GDSB_rec_data{GNUM,3} = sscanf(receiver_data_line{num}(95:103),'%f');
        case 'E'
            ENUM = ENUM+1;
            EDSB_rec_data{ENUM,1} = sscanf(receiver_data_line{num}(16:33),'%s');
            EDSB_rec_data{ENUM,2} = sscanf(receiver_data_line{num}(80:91),'%f');
            EDSB_rec_data{ENUM,3} = sscanf(receiver_data_line{num}(95:103),'%f');
        case 'R'
            RNUM = RNUM+1;
            RDSB_rec_data{RNUM,1} = sscanf(receiver_data_line{num}(16:33),'%s');
            RDSB_rec_data{RNUM,2} = sscanf(receiver_data_line{num}(80:91),'%f');
            RDSB_rec_data{RNUM,3} = sscanf(receiver_data_line{num}(95:103),'%f');
        case 'C'
            CNUM = CNUM+1;
            CDSB_rec_data{CNUM,1} = sscanf(receiver_data_line{num}(16:33),'%s');
            CDSB_rec_data{CNUM,2} = sscanf(receiver_data_line{num}(80:91),'%f');
            CDSB_rec_data{CNUM,3} = sscanf(receiver_data_line{num}(95:103),'%f');

    end

end

DCB.GPS.REC = GDSB_rec_data;
DCB.GPS.SAT = GDSB_satel_data;
DCB.GLONASS.REC = RDSB_rec_data;
DCB.GLONASS.SAT = RDSB_satel_data;
DCB.BDS.REC = CDSB_rec_data;
DCB.BDS.SAT = CDSB_satel_data;
DCB.Galileo.REC = EDSB_rec_data;
DCB.Galileo.SAT = EDSB_satel_data;











