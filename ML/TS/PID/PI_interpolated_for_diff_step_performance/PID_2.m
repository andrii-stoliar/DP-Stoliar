%% PIDDidiy - simplified PI controller design for vent6_near (different step amplitudes)
clc; clear; close all;

% === Load identified model ==================================================
load('C:\MyFiles\Study\DP-Stoliar\ML\TS\identification\identified_models.mat');

% === Simulation setup =======================================================
Tsim = 100;
t_sim = 0:Ts:Tsim;
amps = 1:8;

u_min = 0;
u_max = 10;
base_w = 0.5;

Y_all = zeros(length(t_sim), numel(amps));
U_all = zeros(length(t_sim), numel(amps));
pi_table = zeros(numel(amps), 4);

% === Loop through step amplitudes ===========================================
for k = 1:numel(amps)
    omega_c = base_w * (1 + 0.1*(k-1)); 
    [C, ~] = pidtune(G6_near, 'PI', omega_c);

    T_cl = feedback(C * G6_near, 1);
    T_u  = feedback(C, G6_near);

    r = amps(k) * ones(size(t_sim));
    y = lsim(T_cl, r, t_sim);
    u = lsim(T_u, r, t_sim);

    u = min(max(u, u_min), u_max);
    y(y < 0) = 0;

    Y_all(:,k) = y;
    U_all(:,k) = u;

    pi_table(k,:) = [amps(k), C.Kp, C.Ki, omega_c];
end

% === Plot responses =========================================================
figure('Name','vent6 near — PI step responses','Color','w');
hold on
for k = 1:numel(amps)
    plot(t_sim, Y_all(:,k), 'LineWidth', 1.4)
end
plot(t_sim, amps(end)*ones(size(t_sim)), 'k--')
grid on
xlabel('Time [s]')
ylabel('Output y(t)')
legend(arrayfun(@(a)sprintf('step=%d',a), amps, 'UniformOutput',false), 'Location','bestoutside')
title('vent6 near — PI responses for different step amplitudes')

figure('Name','vent6 near — control signals','Color','w');
hold on
for k = 1:numel(amps)
    plot(t_sim, U_all(:,k), 'LineWidth', 1.4)
end
yline(u_min,'k--');
yline(u_max,'k--');
grid on
xlabel('Time [s]')
ylabel('Control signal u(t)')
legend(arrayfun(@(a)sprintf('step=%d',a), amps, 'UniformOutput',false), 'Location','bestoutside')
title('vent6 near — PI control signals (saturation 0–10)')

% === Save PI parameters =====================================================
if ~exist('./pi_params', 'dir')
    mkdir('./pi_params');
end

pi_matrix_6_near = array2table(pi_table, ...
    'VariableNames',{'Step','Kp','Ki','Omega_c'});

disp('PI parameters for vent6_near by step:')
disp(pi_matrix_6_near)

save('./pi_params/pi_parameters_6_near_by_step.mat','pi_matrix_6_near');
writetable(pi_matrix_6_near,'./pi_params/pi_parameters_6_near_by_step.csv');
