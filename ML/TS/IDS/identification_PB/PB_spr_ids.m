clc; clear; close all; warning('off','all');

save_dir = 'csv_data';

% ensure save dir exists
if ~exist(save_dir,'dir')
    mkdir(save_dir);
end

load pb_mer/pb_vent6_spir4.mat

%----------------------------------------------------------------------------------------
% RAW DATA ------------------------------------------------------------------------------
%----------------------------------------------------------------------------------------

time = time(2400:end) - time(2400);
spir = spir(2400:end);
snimac = snimac1(2400:end);

figure(1);
plot(time, spir, 'LineWidth', 1.5);
hold on;
plot(time, snimac, 'LineWidth', 1.5);
grid on;
hold on;

%----------------------------------------------------------------------------------------
% Detrended and normalized data ---------------------------------------------------------
%----------------------------------------------------------------------------------------

snimac_n = my_detrend(snimac, time);
plot(time, snimac_n, 'LineWidth', 1.5);
hold off;

spir_n = spir - 4;

T = table(time, spir, snimac, spir_n, snimac_n, 'VariableNames', {'time','spir','snimac1','spir_n','snimac1_n'});
fname = fullfile(save_dir, 'pb_vent6_spir4_raw.csv');
writetable(T, fname);  

%----------------------------------------------------------------------------------------
% Average data calculation --------------------------------------------------------------
%----------------------------------------------------------------------------------------

time = time(1:9600);
snimac_n = mean([snimac_n(1:9600), snimac_n(9601:19200), snimac_n(19201:28800)], 2);
spir_n = spir_n(1:9600);

figure(2);
plot(time, spir_n, 'LineWidth', 1.5);
hold on;
plot(time, snimac_n, 'LineWidth', 1.5);
grid on;
hold off;

T = table(time, spir_n, snimac_n, 'VariableNames', {'time','spir_n','snimac1_n'});
fname = fullfile(save_dir, 'pb_vent6_spir4_avg.csv');
writetable(T, fname);

%----------------------------------------------------------------------------------------
% Identification ------------------------------------------------------------------------
%----------------------------------------------------------------------------------------

Ts = 0.1;

Gs_ls = ls_identify_basic(snimac_n, spir_n, Ts)
snimac_s_ls = lsim(Gs_ls, spir_n, time);

Gs_fmin = tf_identify_fmin(snimac_n, spir_n, time, Ts)
snimac_s_fmin = lsim(Gs_fmin, spir_n, time);

rmse_ls   = sqrt(mean((snimac_n - snimac_s_ls).^2));
rmse_fmin = sqrt(mean((snimac_n - snimac_s_fmin).^2));

fprintf('\n---------------------------------------------\n');
fprintf('RMSE (Least Squares): %.6f\n', rmse_ls);
fprintf('RMSE (fminsearch):    %.6f\n', rmse_fmin);
fprintf('---------------------------------------------\n\n');

figure(3);
plot(time, snimac_n, 'k', 'LineWidth', 1.5); hold on;
plot(time, snimac_s_ls, 'r--', 'LineWidth', 1.3);
plot(time, snimac_s_fmin, 'b-.', 'LineWidth', 1.3);
grid on;
hold off;

T = table(time, spir_n, snimac_n, snimac_s_ls, snimac_s_fmin, 'VariableNames', {'time','spir_n','snimac1_n','snimac1_s_ls','snimac1_s_fmin'});
fname = fullfile(save_dir, 'pb_vent6_spir4_id.csv');
writetable(T, fname);

% Approximation of the identified models 

[num, den] = tfdata(Gs_ls, 'v');
num = [0, 0, num(3)];
Gs_ls = tf(num, den)
roots(den)
snimac_s_ls = lsim(Gs_ls, spir_n, time);

[num, den] = tfdata(Gs_fmin, 'v');
num = [0, 0, num(3)];
Gs_fmin = tf(num, den)
roots(den)
snimac_s_fmin = lsim(Gs_fmin, spir_n, time);

rmse_ls   = sqrt(mean((snimac_n - snimac_s_ls).^2));
rmse_fmin = sqrt(mean((snimac_n - snimac_s_fmin).^2));

fprintf('\n---------------------------------------------\n');
fprintf('RMSE (Least Squares): %.6f\n', rmse_ls);
fprintf('RMSE (fminsearch):    %.6f\n', rmse_fmin);
fprintf('---------------------------------------------\n\n');

figure(4);
plot(time, snimac_n, 'k', 'LineWidth', 1.5); hold on;
plot(time, snimac_s_ls, 'r--', 'LineWidth', 1.3);
plot(time, snimac_s_fmin, 'b-.', 'LineWidth', 1.3);
grid on;
hold off;

T = table(time, spir_n, snimac_n, snimac_s_ls, snimac_s_fmin, 'VariableNames', {'time','spir_n','snimac1_n','snimac1_s_ls','snimac1_s_fmin'});
fname = fullfile(save_dir, 'pb_vent6_spir4_id_apprx.csv');
writetable(T, fname);

save('pb_vent6_spir4_id.mat', 'Gs_fmin', 'Gs_ls');

%----------------------------------------------------------------------------------------
% FUNCTIONS -----------------------------------------------------------------------------
%----------------------------------------------------------------------------------------
warning('on','all');

function G = ls_identify_basic(y, u, Ts)
    
    y = y(:);
    u = u(:);
    N = length(y);
    na = 2; nb = 2;
    
    H = zeros(N-2, na+nb);
    for k = 3:N
        H(k-2,:) = [-y(k-1), -y(k-2), u(k-1), u(k-2)];
    end
    Y = y(3:N);
    
    theta = pinv(H) * Y;  
    
    a1 = theta(1); 
    a2 = theta(2);
    b1 = theta(3); 
    b2 = theta(4);
    
    num = [b1 b2];
    den = [1 a1 a2];
    Gd = tf(num, den, Ts);
    
    G = d2c(Gd, 'tustin');

end

function G = tf_identify_fmin(y, u, time, Ts)

    y = y(:);
    u = u(:);
    time = time(:);

    p0 = [0 0 0 0];

    cost_fun = @(p) rmse_cost_stable(p, u, y, time, Ts);

    opts = optimset('Display', 'off', 'TolX', 1e-8, 'TolFun', 1e-8);
    p_opt = fminsearch(cost_fun, p0, opts);

    p_opt = 50 * tanh(p_opt);
    a1 = p_opt(1); a2 = p_opt(2); b1 = p_opt(3); b2 = p_opt(4);

    Gd = tf([b1 b2], [1 a1 a2], Ts);
    G  = d2c(Gd, 'tustin');

end

function err = rmse_cost_stable(p, u, y, t, Ts)

    p = 50 * tanh(p);
    a1 = p(1); a2 = p(2); b1 = p(3); b2 = p(4);

    try

        Gd = tf([b1 b2], [1 a1 a2], Ts);

        poles = pole(Gd);
        if any(abs(poles) >= 1)
            err = 1e6;
            return;
        end

        G = d2c(Gd, 'tustin');
        y_sim = lsim(G, u, t);

        err = sqrt(mean((y - y_sim).^2));

    catch
        err = 1e6;
    end
end

% my_detrend
% Implements subtraction of the linear trend using formulas (2.6)-(2.7)
% from the book:
% Douglas C. Montgomery, Elizabeth A. Peck, G. Geoffrey Vining.
% "Introduction to Linear Regression Analysis", 5th Edition, Wiley, 2012.
% (Section 2.2.1)

function y_detr = my_detrend(y, x)

    y = y(:);
    x = x(:);
    n = length(y);

    Sx  = sum(x);
    Sy  = sum(y);
    Sxx = sum(x.^2);
    Sxy = sum(x .* y);

    b1 = (n*Sxy - Sx*Sy) / (n*Sxx - Sx^2);  
    b0 = mean(y) - b1 * mean(x);            

    y_detr = y - (b0 + b1*x);

end





