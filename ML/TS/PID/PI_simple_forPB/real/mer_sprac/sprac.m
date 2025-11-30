clc; clear; close all;
load pb_vent6_spir4_pif4.mat

time = time(1700:end) - time(1700);
spir = spir(1700:end) - 4;
snimac1 = snimac1(1700:end) - snimac1(1800);
vent = vent(1700:end);
setpoint(1:101) = 0;
setpoint(101:702) = 0.35;

figure(1);
plot(time, spir)
hold on
plot(time, snimac1)
hold on
plot (time, setpoint)
ylim([-4 6])
hold off

T = table(time, spir, snimac1, setpoint, vent, 'VariableNames', {'time','spir','snimac1','setpoint','vent'});
fname = fullfile('ts_pb_vent6_spir4_PI4_real.csv');
writetable(T, fname); 

clc; clear; 
load pb_vent6_spir4_pbTopb.mat

time = time(1700:2400) - time(1700);
spir = spir(1700:2400) - 4;
snimac1 = snimac1(1700:2400) - snimac1(1800);
vent = vent(1700:2400);
setpoint1 = setpoint1(1700:2400);
setpoint1(1:101) = 0;

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