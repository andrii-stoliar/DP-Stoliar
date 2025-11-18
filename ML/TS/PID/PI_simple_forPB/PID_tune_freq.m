clc; clear; close all;
load pb_vent6_spir4_id.mat

Gs = Gs_fmin;
Ts = 0.1;

% BODE data
[mag,phase,w] = bode(Gs);
mag_dB   = squeeze(20*log10(mag));
phase_deg = squeeze(phase);
w = squeeze(w);

% levels zalomov (idk what to call them in English)
levels = [mag_dB(1), mag_dB(1)-3, -55, mag_dB(end)];

% find frequencies at levels
w_mark = arrayfun(@(L) interp1(mag_dB, w, L), levels);
f_mark = w_mark/(2*pi);

% PLOT
figure;

subplot(2,1,1)
semilogx(w,mag_dB,'b','LineWidth',1.2); grid on; hold on
semilogx(w_mark,levels,'ro','MarkerSize',7,'LineWidth',1.4)
ylabel('Magnitude (dB)')
title('Bode Magnitude')
xlim([min(w) max(w)])

subplot(2,1,2)
semilogx(w,phase_deg,'b','LineWidth',1.2); grid on; hold on
ylabel('Phase (deg)')
xlabel('Frequency (rad/s)')
title('Bode Phase')
xlim([min(w) max(w)])

hold off;

format long g
disp(w_mark)
disp(f_mark)

% Pocus spravit PI AKA "Ako som pocitil ze som debil" :D
wc = sqrt(w_mark(2)*w_mark(3)); 

wi = 0.2*wc; % integral frequency
Ti = 1/wi;

% P gain at wc

s = tf('s');
C_pi_noK = (1 + 1/(Ti*s)); 

[magC, ~] = bode(C_pi_noK, wc);
magC = squeeze(magC);

[magGs, ~] = bode(Gs, wc);
magGs = squeeze(magGs);

Kp = 1 / (magC * magGs);
C  = Kp * C_pi_noK;

G_oro = C * Gs;

% SIMULATION
sysc = ss(Gs);

sysd = c2d(sysc, Ts, 'zoh');
[Ad,Bd,Cd,Dd] = ssdata(sysd);

Tend = 20;                
t = 0:Ts:Tend;
r = 0.4 * ones(size(t));  

N = numel(t);
y = zeros(1,N);
u = zeros(1,N);
e = zeros(1,N);

xG = zeros(size(Ad,1),1);  
I  = 0;                   

u_prev = 0;               

for k = 1:N
    y(k) = Cd*xG + Dd*u_prev;

    e(k) = r(k) - y(k);

    I = I + Ts * e(k);          
    u_unsat = Kp * ( e(k) + I/Ti );

    u(k) = min(max(u_unsat, -4), 6);

    if abs(u(k) - u_unsat) > 1e-9
        I = I - Ts * e(k);
    end

    xG = Ad*xG + Bd*u(k);

    u_prev = u(k);
end

figure;
subplot(2,1,1);
plot(t,y,'LineWidth',1.6); hold on;
yline(0.4,'k--','LineWidth',1.0);
grid on;
title('Output y(t)');
xlabel('Time [s]');
ylabel('y');

subplot(2,1,2);
plot(t,u,'LineWidth',1.6); hold on;
yline(6,'r--','LineWidth',1.0);
yline(-4,'r--','LineWidth',1.0);
grid on;
title('Control signal u(t) with saturation');
xlabel('Time [s]');
ylabel('u');
