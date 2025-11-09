load pb_vent6_spir4_id.mat

[num, den] = tfdata(Gs_ls, 'v');

a0 = den(1);
a1 = den(2);
a2 = den(3);
b0 = num(1);
b1 = num(2);
b2 = num(3);

w0 = 10;  
k  = 0.7; 
p  = 0;

Ki = (w0^2 * p)/b0
Kp = (w0^2 + 2*p*k*w0 - a0 - Ki*b1)/b0

s = tf('s');
G = Gs_fmin;

C = Kp + Ki/s;

T = feedback(C*G, 1);

t = 0:0.1:150;  
r = zeros(size(t));

r(t >= 30 & t < 60) = 0.3;
r(t >= 90 & t < 120) = -0.3;

[y, t_out] = lsim(T, r, t);

figure;
plot(t_out, r, 'k--', 'LineWidth', 1.2); hold on;
plot(t_out, y, 'b', 'LineWidth', 1.5);
grid on;
xlabel('Time [s]');
ylabel('Output');
legend('Reference', 'System output');
title('PI + System Response to Step Sequence');



