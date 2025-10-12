%%PID
%PIDDidiy - PID controller design for MIMO system

clc
clear
close all

% STEP 1 - preparation of data before identification -----------------------------------------------------------------

% Parameters of the experiment
Ts = 0.1;          
step_len = 100;    
NsPerStep = step_len / Ts; 
levels = 0:10;    

% Load experiments data
load prevodova_vent3.mat
time3 = time; spir3 = spir; y13 = snimac1; y23 = snimac2; vent3 = vent;

load prevodova_vent6.mat
time6 = time; spir6 = spir; y16 = snimac1; y26 = snimac2; vent6 = vent;

load prevodova_vent9.mat
time9 = time; spir9 = spir; y19 = snimac1; y29 = snimac2; vent9 = vent;

% mean values of skoks

y13_skok = zeros(7, 1000);
y23_skok = zeros(7, 1000);
y16_skok = zeros(7, 1000);
y26_skok = zeros(7, 1000);
y19_skok = zeros(7, 1000);
y29_skok = zeros(7, 1000);

for i = 1:7
    idx_start = 1000*i + 1;
    idx_end = idx_start + 999;
    y13_skok(i, :) = y13(idx_start:idx_end) - y13(idx_start);
    y23_skok(i, :) = y23(idx_start:idx_end) - y23(idx_start);    
    y16_skok(i, :) = y16(idx_start:idx_end) - y16(idx_start);
    y26_skok(i, :) = y26(idx_start:idx_end) - y26(idx_start); 
    y19_skok(i, :) = y19(idx_start:idx_end) - y19(idx_start);
    y29_skok(i, :) = y29(idx_start:idx_end) - y29(idx_start); 
end

for i = 1:7
    y13_mean = mean(y13_skok, 1);
    y23_mean = mean(y23_skok, 1);
    y16_mean = mean(y16_skok, 1);
    y26_mean = mean(y26_skok, 1);
    y19_mean = mean(y19_skok, 1);
    y29_mean = mean(y29_skok, 1);
end

% STEP 2 - MIMO system identification --------------------------------------------------------------------------------

t = (0:999)' * 0.1;  
u = ones(size(t));   

% Build iddata objects for each fan level
data_3_near = iddata(y13_mean', u, Ts, 'OutputName','near', 'InputName','spir');
data_3_far  = iddata(y23_mean', u, Ts, 'OutputName','far',  'InputName','spir');
data_6_near = iddata(y16_mean', u, Ts, 'OutputName','near', 'InputName','spir');
data_6_far  = iddata(y26_mean', u, Ts, 'OutputName','far',  'InputName','spir');
data_9_near = iddata(y19_mean', u, Ts, 'OutputName','near', 'InputName','spir');
data_9_far  = iddata(y29_mean', u, Ts, 'OutputName','far',  'InputName','spir');

% Model order
np = 2; 
nz = 2;  

% Identify SISO transfer functions using tfest
G3_near = tfest(data_3_near, np, nz);
G3_far  = tfest(data_3_far,  np, nz);
G6_near = tfest(data_6_near, np, nz);
G6_far  = tfest(data_6_far,  np, nz);
G9_near = tfest(data_9_near, np, nz);
G9_far  = tfest(data_9_far,  np, nz);


% model comparison

% simulate model responses
y3n_model = lsim(G3_near, ones(size(t)), t);
y3f_model = lsim(G3_far , ones(size(t)), t);
y6n_model = lsim(G6_near, ones(size(t)), t);
y6f_model = lsim(G6_far , ones(size(t)), t);
y9n_model = lsim(G9_near, ones(size(t)), t);
y9f_model = lsim(G9_far , ones(size(t)), t);

% compute RMSE for each model
rmse_3n = sqrt(mean((y3n_model - y13_mean').^2));
rmse_3f = sqrt(mean((y3f_model - y23_mean').^2));
rmse_6n = sqrt(mean((y6n_model - y16_mean').^2));
rmse_6f = sqrt(mean((y6f_model - y26_mean').^2));
rmse_9n = sqrt(mean((y9n_model - y19_mean').^2));
rmse_9f = sqrt(mean((y9f_model - y29_mean').^2));

% overall average RMSE
rmse_total = mean([rmse_3n, rmse_3f, rmse_6n, rmse_6f, rmse_9n, rmse_9f]);

% Plot results
figure('Name','Model vs averaged response','Color','w');
sgtitle(sprintf('Model vs Averaged Data — RMSE avg = %.4f', rmse_total)); 

subplot(3,2,1)
plot(t, y13_mean, 'k', t, y3n_model, 'r--', 'LineWidth', 1.2)
title(sprintf('vent=3 — near (RMSE=%.3f)', rmse_3n))
legend('data','model')

subplot(3,2,2)
plot(t, y23_mean, 'k', t, y3f_model, 'r--', 'LineWidth', 1.2)
title(sprintf('vent=3 — far (RMSE=%.3f)', rmse_3f))
legend('data','model')

subplot(3,2,3)
plot(t, y16_mean, 'k', t, y6n_model, 'r--', 'LineWidth', 1.2)
title(sprintf('vent=6 — near (RMSE=%.3f)', rmse_6n))
legend('data','model')

subplot(3,2,4)
plot(t, y26_mean, 'k', t, y6f_model, 'r--', 'LineWidth', 1.2)
title(sprintf('vent=6 — far (RMSE=%.3f)', rmse_6f))
legend('data','model')

subplot(3,2,5)
plot(t, y19_mean, 'k', t, y9n_model, 'r--', 'LineWidth', 1.2)
title(sprintf('vent=9 — near (RMSE=%.3f)', rmse_9n))
legend('data','model')

subplot(3,2,6)
plot(t, y29_mean, 'k', t, y9f_model, 'r--', 'LineWidth', 1.2)
title(sprintf('vent=9 — far (RMSE=%.3f)', rmse_9f))
legend('data','model')

% Styling
for k = 1:6
    subplot(3,2,k)
    xlabel('Time [s]')
    ylabel('\Delta y')
    grid on
end

% STEP 3 — Autotuned PID with individual tuning for near/far ---------------------------------------------

Tsim = 100;
t = 0:Ts:Tsim;
r = 6 * ones(size(t));  

systems = {G3_near, G3_far, G6_near, G6_far, G9_near, G9_far};
labels  = {'G3 near', 'G3 far', 'G6 near', 'G6 far', 'G9 near', 'G9 far'};
omega_c = [0.8, 2, 0.6, 2, 0.8, 2];  

figure('Name','Autotuned PID Step Responses (Individual Near/Far)','Color','w');
sgtitle('Step responses — Autotuned PID (0→6), near vs far tuned separately');

u_all = zeros(length(t), 6);  

for i = 1:6
    G = systems{i};
    
    [C, info] = pidtune(G, 'PID', omega_c(i));

    T_cl = feedback(C * G, 1);      
    T_u  = feedback(C, G);           

    y = lsim(T_cl, r, t);
    u_pid = lsim(T_u, r, t);
    
    u_pid = max(0, min(10, u_pid));
    u_all(:, i) = u_pid;

    % Remove undershoot
    y(y < 0) = 0;

    % Plot outputs
    subplot(4,2,i)
    plot(t, y, 'b', 'LineWidth', 1.5)
    title(sprintf('%s — Kp=%.2f, Ki=%.2f, Kd=%.2f', ...
        labels{i}, C.Kp, C.Ki, C.Kd))
    xlabel('Time [s]')
    ylabel('Output')
    grid on
end

subplot(4,2,[7 8])
hold on
colors = lines(6);
for i = 1:6
    plot(t, u_all(:, i), 'Color', colors(i,:), 'LineWidth', 1.4)
end
hold off
grid on
xlabel('Time [s]')
ylabel('Control signal u(t)')
title('All PID control signals (saturated 0–10)')
legend(labels, 'Location','bestoutside')

set(gcf,'Position',[100 100 1000 800]);


% STEP 4 — Matrix of PID parameters --------------------------------------------------------------

pid_matrix = table({'G3_near'; 'G3_far'; 'G6_near'; 'G6_far'; 'G9_near'; 'G9_far'}, zeros(6,1), zeros(6,1), zeros(6,1), 'VariableNames', {'System','Kp','Ki','Kd'});

for i = 1:6
    G = systems{i};
    [C, info] = pidtune(G, 'PID', omega_c(i));
    pid_matrix.Kp(i) = C.Kp;
    pid_matrix.Ki(i) = C.Ki;
    pid_matrix.Kd(i) = C.Kd;
end

disp('Matrix of PID parameters:')
disp(pid_matrix)

save('pid_parameters.mat', 'pid_matrix');
%writetable(pid_matrix, 'pid_parameters.csv');
