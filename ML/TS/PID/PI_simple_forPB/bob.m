

alpha0 = 3;
alpha1 = 30000;
b0 = 2756;
b1 = -4.057e4;
a0 = 3948;

Ki = alpha0 / b0
Kp = (alpha1 - a0 - Ki * b1) / b0

Kp = 2;
Ki = 2;

C = tf([Kp Ki], [1 0]);   

T_cl = feedback(C * Gs_fmin, 1);   

Ts = 0.01;                    
t_end = 150;                 
t = 0:Ts:t_end;

u = zeros(size(t));
u(t >= 30  & t < 60)  = 0.5;
u(t >= 60  & t < 90)  = 0.0;
u(t >= 90  & t < 120) = -0.5;
u(t >= 120 & t <=150) = 0.0;

[y, t_out] = lsim(T_cl, u, t);

figure(4);
plot(t_out, y, 'LineWidth', 1.5); hold on;
plot(t_out, u, '--', 'LineWidth', 1.0);  
grid on;
hold off;