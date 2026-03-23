load exp1.mat

T = table(t, r_l, r_g, r_gf, y, y_pb, u, u_g, u_l, u_pb, active_g, Ki_l, Kp_l);
writetable(T, 'ts_ml_prep_real.csv');