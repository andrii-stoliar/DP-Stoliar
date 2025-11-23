clc; clear; close all;
load pb_vent6_spir4_id.mat

Gs = Gs_fmin;
Ts = 0.1;

p = pole(Gs);

T = -1 ./ p; 

T1 = max(T)        
T2 = min(T) 

K = dcgain(Gs)

Ti = 4*T2
Kp = T1/(2*K*T2)

C = Kp * tf([Ti 1],[Ti 0]);

L = C*Gs;
margin(L)
bode(L)
grid on

[GM, PM, wcg, wcp] = margin(L);
PM


