%% pid_tuning.m
% Load identified models and tune PID controllers
clc; clear; close all;

load('C:\MyFiles\Study\DP-Stoliar\ML\TS\identification\identified_models.mat');

Tsim = 100;
t = 0:Ts:Tsim;
r = 6 * ones(size(t));

systems = {G3_near, G3_far, G6_near, G6_far, G9_near, G9_far};
labels  = {'G3 near', 'G3 far', 'G6 near', 'G6 far', 'G9 near', 'G9 far'};
omega_c = [0.8, 2, 0.6, 2, 0.8, 2];

figure('Name','PID step responses','Color','w');
sgtitle('Step responses with autotuned PID (0→6)');

u_all = zeros(length(t), 6);
pid_matrix = table(labels', zeros(6,1), zeros(6,1), zeros(6,1), ...
    'VariableNames', {'System','Kp','Ki','Kd'});

for i = 1:6
    G = systems{i};
    [C, info] = pidtune(G, 'PID', omega_c(i));

    T_cl = feedback(C * G, 1);
    T_u  = feedback(C, G);

    y = lsim(T_cl, r, t);
    u = lsim(T_u, r, t);
    u = max(0, min(10, u));
    u_all(:, i) = u;

    subplot(4,2,i)
    plot(t, y, 'b', 'LineWidth', 1.5)
    title(sprintf('%s — Kp=%.2f, Ki=%.2f, Kd=%.2f', ...
        labels{i}, C.Kp, C.Ki, C.Kd))
    xlabel('Time [s]')
    ylabel('Output')
    grid on

    pid_matrix.Kp(i) = C.Kp;
    pid_matrix.Ki(i) = C.Ki;
    pid_matrix.Kd(i) = C.Kd;
end

subplot(4,2,[7 8])
colors = lines(6);
hold on
for i = 1:6
    plot(t, u_all(:, i), 'Color', colors(i,:), 'LineWidth', 1.4)
end
hold off
grid on
xlabel('Time [s]')
ylabel('Control signal u(t)')
title('All PID control signals (saturated 0–10)')
legend(labels, 'Location','bestoutside')

save('pid_parameters.mat', 'pid_matrix');
disp('✅ PID parameters saved to pid_parameters.mat');
