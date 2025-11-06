clc; clear; close all;

save_dir = 'csv_data';

% ensure save dir exists
if ~exist(save_dir,'dir')
    mkdir(save_dir);
end

load pb_mer/pb_vent6_spir4.mat

% RAW DATA -------------------------------------------------------------

time = time(:);
spir = spir(:);
snimac1 = snimac1(:);
snimac2 = snimac2(:);
vent = vent(:);


figure(1);
plot(time, spir, 'LineWidth', 1.5);
hold on;
plot(time, snimac1, 'LineWidth', 1.5);
grid on;
hold off;

% Detrended data ----------------------------------------------------

snimac1_n = detrend(snimac1);
spir_n = spir - 4;

T = table(time, spir, snimac1, spir_n, snimac1_n, 'VariableNames', {'time','spir','snimac1','spir_n','snimac1_n'});
fname = fullfile(save_dir, 'pb_vent6_spir4_raw.csv');
try
    writetable(T, fname);  
catch ME
    warning('Failed to write CSV: %s', ME.message);
end

% AVERAGE EXPERIMENTAL DATA --------------------------------------------

time = time(2400:11999) - time(2400);
snimac1_n = mean([snimac1_n(2400:11999), snimac1_n(12000:21599), snimac1_n(21600:31199)], 2);
spir_n = spir_n(2400:11999);
vent = vent(2400:11999 );

figure(2);
plot(time, spir_n, 'LineWidth', 1.5);
hold on;
plot(time, snimac1_n, 'LineWidth', 1.5);
grid on;
hold off;

% Identification with least squares ------------------------------------------------------


Gs = ls_identify_basic(snimac1_n, spir_n, 0.1);
snimac1_s = lsim(Gs, spir_n, time);

figure(3);
plot(time, snimac1_n, 'k', time, snimac1_s, 'r--', 'LineWidth', 1.2)
legend('data','model')

% FUNCTIONS -------------------------------------------------------

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






