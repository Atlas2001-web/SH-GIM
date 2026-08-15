clear
clc
current_path=pwd;
% 生成类型转换的结构体
Obs_Type_Conversion.R2toR3.GC1 = 'C1C';
Obs_Type_Conversion.R2toR3.GC2 = 'C2C';
Obs_Type_Conversion.R2toR3.GP1 = 'C1W';
Obs_Type_Conversion.R2toR3.GP2 = 'C2W';
Obs_Type_Conversion.R2toR3.RC1 = 'C1C';
Obs_Type_Conversion.R2toR3.RC2 = 'C2C';
Obs_Type_Conversion.R2toR3.RP1 = 'C1P';
Obs_Type_Conversion.R2toR3.RP2 = 'C2P';

Obs_Type_Conversion.R2toR3.GL1 = 'L1';
Obs_Type_Conversion.R2toR3.GL2 = 'L2';
Obs_Type_Conversion.R2toR3.RL1 = 'L1';
Obs_Type_Conversion.R2toR3.RL2 = 'L2';

Obs_Type_Conversion.R3toR2(1).G1C = 'C1';
Obs_Type_Conversion.R3toR2(1).G2C = 'C2';
Obs_Type_Conversion.R3toR2(1).G1W = 'P1';
Obs_Type_Conversion.R3toR2(1).G2W = 'P2';
Obs_Type_Conversion.R3toR2(1).R1C = 'C1';
Obs_Type_Conversion.R3toR2(1).R2C = 'C2';
Obs_Type_Conversion.R3toR2(1).R1P = 'P1';
Obs_Type_Conversion.R3toR2(1).R2P = 'P2';

Obs_Type_Conversion.R3toR2(2).G1C = 'L1';
Obs_Type_Conversion.R3toR2(2).G2C = 'L2';
Obs_Type_Conversion.R3toR2(2).G1W = 'L1';
Obs_Type_Conversion.R3toR2(2).G2W = 'L2';
Obs_Type_Conversion.R3toR2(2).R1C = 'L1';
Obs_Type_Conversion.R3toR2(2).R2C = 'L2';
Obs_Type_Conversion.R3toR2(2).R1P = 'L1';
Obs_Type_Conversion.R3toR2(2).R2P = 'L2';

save(fullfile(current_path,'/sub_mat/Conversion_Struct.mat'), "Obs_Type_Conversion")