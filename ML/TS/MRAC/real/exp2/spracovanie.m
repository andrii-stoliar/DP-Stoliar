load exp2.mat

T = table(time, r, snimac1, ym, spir, theta1, theta2, theta3, y0);
writetable(T, 'ts_ml_mrac_real.csv');