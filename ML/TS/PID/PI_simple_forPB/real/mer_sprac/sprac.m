clc; clear; close all;
load pb_vent6_spir4_pif4.mat

time = time(5999:6500) - time(5999);
spir = spir(5999:6500) - 4;
snimac1 = snimac1(5999:6500) - snimac1(6000);
vent = vent(5999:6500);
setpoint1 = setpoint1(5999:6500);

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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc; clear; 
load pb_vent6_spir4_pbTopb.mat

time = time(1799:end) - time(1799);
spir = spir(1799:end);
snimac1 = snimac1(1799:end);
vent = vent(1799:end);
setpoint1 = setpoint1(1799:end);
setpoint1 = setpoint1;

figure(2);
plot(time, spir)
hold on
plot(time, snimac1)
hold on
plot (time, setpoint1)
hold off

T = table(time, spir, snimac1, setpoint1, vent, 'VariableNames', {'time','spir','snimac1','setpoint','vent'});
fname = fullfile('ts_pb_vent6_pbTopb_real_badToShow.csv');
writetable(T, fname); 