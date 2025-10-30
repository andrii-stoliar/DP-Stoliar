%% identify_systems.m
% Identify MIMO system and save transfer functions
clc; clear; close all;

% Parameters
Ts = 0.1;
step_len = 4*60;
NsPerStep = step_len / Ts;
levels = 0:10;

% Load data
load('./prevodova_mer/prevodova_vent3.mat')
time3 = time; spir3 = spir; y13 = snimac1; y23 = snimac2;

load('./prevodova_mer/prevodova_vent6.mat')
time6 = time; spir6 = spir; y16 = snimac1; y26 = snimac2;

load('./prevodova_mer/prevodova_vent9.mat')
time9 = time; spir9 = spir; y19 = snimac1; y29 = snimac2;

% Compute averaged step responses
y13_skok = zeros(6, 2400);
y23_skok = zeros(6, 2400);
y16_skok = zeros(6, 2400);
y26_skok = zeros(6, 2400);
y19_skok = zeros(6, 2400);
y29_skok = zeros(6, 2400);

for i = 1:6
    idx_start = 2400*i + 1;
    idx_end = idx_start + 2399;
    y13_skok(i, :) = y13(idx_start:idx_end) - y13(idx_start);
    y23_skok(i, :) = y23(idx_start:idx_end) - y23(idx_start);
    y16_skok(i, :) = y16(idx_start:idx_end) - y16(idx_start);
    y26_skok(i, :) = y26(idx_start:idx_end) - y26(idx_start);
    y19_skok(i, :) = y19(idx_start:idx_end) - y19(idx_start);
    y29_skok(i, :) = y29(idx_start:idx_end) - y29(idx_start);
end

y13_mean = mean(y13_skok, 1);
y23_mean = mean(y23_skok, 1);
y16_mean = mean(y16_skok, 1);
y26_mean = mean(y26_skok, 1);
y19_mean = mean(y19_skok, 1);
y29_mean = mean(y29_skok, 1);

% Identification
t = (0:2399)' * Ts;
u = ones(size(t));

data_3_near = iddata(y13_mean', u, Ts);
data_3_far  = iddata(y23_mean', u, Ts);
data_6_near = iddata(y16_mean', u, Ts);
data_6_far  = iddata(y26_mean', u, Ts);
data_9_near = iddata(y19_mean', u, Ts);
data_9_far  = iddata(y29_mean', u, Ts);

G3_near = ls_identify_basic(y13_mean', u, Ts)
G3_far  = ls_identify_basic(y23_mean', u, Ts)
G6_near = ls_identify_basic(y16_mean', u, Ts)
G6_far  = ls_identify_basic(y26_mean', u, Ts)
G9_near = ls_identify_basic(y19_mean', u, Ts)
G9_far  = ls_identify_basic(y29_mean', u, Ts)


% Save identified models
save('identified_models.mat', ...
    'G3_near', 'G3_far', 'G6_near', 'G6_far', 'G9_near', 'G9_far', 'Ts');

disp('Identified models saved to identified_models.mat');

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

% === Save data for Python plotting ===
T_out = table(t, ...
    y13_mean', y23_mean', y16_mean', y26_mean', y19_mean', y29_mean', ...
    y3n_model, y3f_model, y6n_model, y6f_model, y9n_model, y9f_model, ...
    'VariableNames', { ...
    'time', ...
    'y13_data', 'y23_data', 'y16_data', 'y26_data', 'y19_data', 'y29_data', ...
    'y3n_model', 'y3f_model', 'y6n_model', 'y6f_model', 'y9n_model', 'y9f_model'});

writetable(T_out, 'ts_identified_results.csv');
disp('Saved plot data to identified_results.csv');

function G = ls_identify_basic(y, u, Ts)
    
    y = y(:);
    u = u(:);
    N = length(y);
    na = 2; nb = 2;
    
    Phi = zeros(N-2, na+nb);
    for k = 3:N
        Phi(k-2,:) = [-y(k-1), -y(k-2), u(k-1), u(k-2)];
    end
    Y = y(3:N);
    
    theta = pinv(Phi) * Y;  
    
    a1 = theta(1); 
    a2 = theta(2);
    b1 = theta(3); 
    b2 = theta(4);
    
    num = [b1 b2];
    den = [1 a1 a2];
    Gd = tf(num, den, Ts);
    
    G = d2c(Gd, 'tustin');

end

