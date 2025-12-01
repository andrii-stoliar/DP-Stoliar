clc; clear; close all;
load pb_vent6_spir4_pif4.mat

time = time(5900:6700) - time(5900);
spir = spir(5900:6700) - 4;
snimac1 = snimac1(5900:6700) - snimac1(5901);
vent = vent(5900:6700);
setpoint1 = setpoint1(5900:6700);
setpoint1(1:100) = 0;

figure(1);
plot(time, spir)
hold on
plot(time, snimac1)
hold on
plot (time, setpoint1)
ylim([-4 6])
hold off

T = table(time, spir, snimac1, setpoint1, vent, 'VariableNames', {'time','spir','snimac1','setpoint','vent'});
fname = fullfile('ts_pb_vent6_spir4_PI_real.csv');
writetable(T, fname); 

clc; clear; 
load pb_vent6_spir4_pbTopb.mat

time = time(2300:3100) - time(2300);
spir = spir(2300:3100) - 4;
snimac1 = snimac1(2300:3100) - snimac1(2300);
vent = vent(2300:3100);
setpoint1 = setpoint1(2300:3100);
setpoint1(1:100) = 0;

figure(2);
plot(time, spir)
hold on
plot(time, snimac1)
hold on
plot (time, setpoint1)
ylim([-4 6])
hold off

T = table(time, spir, snimac1, setpoint1, vent, 'VariableNames', {'time','spir','snimac1','setpoint','vent'});
fname = fullfile('ts_pb_vent6_pbTopb_real_badToShow.csv');
writetable(T, fname); 