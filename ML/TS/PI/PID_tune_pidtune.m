clc; clear; close all;
load pb_vent6_spir4_id.mat

Gs = Gs_ls
Ts = 0.1;

Gz = c2d(Gs, Ts, 'tustin');
[Ad,Bd,Cd,Dd] = ssdata(Gz);

%0.5
wc = 0.5;                        
Cz = pidtune(Gz, 'pi', wc) 
Goro = Gs*d2c(Cz, 'tustin')

[numC,denC] = tfdata(Cz,'v');
[Ac,Bc,Cc,Dc] = tf2ss(numC,denC);  

N  = 500;
t  = (0:N-1)*Ts;
ref = 0.35 * ones(1,N);
K_limit = [-4 6];

xG = zeros(size(Ad,1),1);   
xC = zeros(size(Ac,1),1);   
y = zeros(1,N);
u = zeros(1,N);
e = zeros(1,N);

for k = 2:N
    
    e(k) = ref(k) - y(k-1);

    xC = Ac*xC + Bc*e(k);
    u_raw = Cc*xC + Dc*e(k);

    u(k) = min(max(u_raw, K_limit(1)), K_limit(2));

    xG = Ad*xG + Bd*u(k);
    y(k) = Cd*xG + Dd*u(k);

end

% results of regulation

% Parameters
ref_val = ref(end);        % step reference value
tol = 0.02;                % settling tolerance (2%)

% Steady-state estimate (mean of last 10% of samples)
idx_last = round(0.9*N):N;
steady_val = mean(y(idx_last));

% Overshoot (перерегулирование) in percent relative to reference
ymax = max(y);
overshoot = max(0,(ymax - ref_val)/abs(ref_val)) * 100;

% Settling time (время регулирования): first time after which y stays within tol*ref
outside = find(abs(y - ref_val) > tol*abs(ref_val));
if isempty(outside)
    settling_time = 0; % already within tolerance
else
    last_out = max(outside);
    if last_out < N
        settling_time = t(last_out+1);
    else
        settling_time = NaN; % did not settle within simulation time
    end
end

% Mean squared error (средняя квадратичная ошибка)
mse = mean((y - ref).^2);

% Display results
fprintf('Steady-state (last 10%% mean): %.4f\n', steady_val);
if isnan(settling_time)
    fprintf('Settling time (%.2f%% tol): not settled within simulation time\n', tol*100);
else
    fprintf('Settling time (%.2f%% tol): %.3f s\n', tol*100, settling_time);
end
fprintf('Overshoot: %.2f %%\n', overshoot);
fprintf('MSE: %.6f\n', mse);

figure;
subplot(2,1,1);
plot(t,y,'LineWidth',2); grid on;
title('Step Response (ref=0.4)');
ylabel('y');

subplot(2,1,2);
plot(t,u,'LineWidth',2); grid on;
title('Control Signal (Saturated)');
ylabel('u');
xlabel('Time [s]');

T = table(t', ref', u', y', 'VariableNames', {'time','setpoint','vstup','vystup'});
fname = fullfile('ts_pb_vent6_spir4_pidtune_sim.csv');
writetable(T, fname);
