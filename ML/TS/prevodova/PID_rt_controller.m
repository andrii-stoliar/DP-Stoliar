clc; clear;

load('pid_parameters.mat','pid_matrix');

model = 'mimo_system_model';     
Ts = 0.1;                        
ref = 6;                        
spir = 0;                     

vent_levels = [3, 6, 9];

Kp_near = [pid_matrix.Kp(1), pid_matrix.Kp(3), pid_matrix.Kp(5)];
Ki_near = [pid_matrix.Ki(1), pid_matrix.Ki(3), pid_matrix.Ki(5)];
Kd_near = [pid_matrix.Kd(1), pid_matrix.Kd(3), pid_matrix.Kd(5)];

Kp_far  = [pid_matrix.Kp(2), pid_matrix.Kp(4), pid_matrix.Kp(6)];
Ki_far  = [pid_matrix.Ki(2), pid_matrix.Ki(4), pid_matrix.Ki(6)];
Kd_far  = [pid_matrix.Kd(2), pid_matrix.Kd(4), pid_matrix.Kd(6)];

prev_error = 0;
int_error = 0;
cur_t = 0;

load_system(model);
set_param(model, 'SimulationCommand', 'start');
pause(1); 

disp("Real-time PID control started");

while strcmp(get_param(model,'SimulationStatus'),'running')

    vent = evalin('base','vent_out');         
    sensor_mode = evalin('base','sensor_mode');
    y_meas = evalin('base','snimac');      

    if sensor_mode == 0
        Kp_vec = Kp_near; Ki_vec = Ki_near; Kd_vec = Kd_near;
    else
        Kp_vec = Kp_far;  Ki_vec = Ki_far;  Kd_vec = Kd_far;
    end

    vent = max(3, min(9, vent));
    Kp = interp1(vent_levels, Kp_vec, vent);
    Ki = interp1(vent_levels, Ki_vec, vent);
    Kd = interp1(vent_levels, Kd_vec, vent);

    error = ref - y_meas;
    int_error = int_error + error * Ts;
    deriv_error = (error - prev_error) / Ts;
    spir = Kp * error + Ki * int_error + Kd * deriv_error;
    prev_error = error;

    spir = max(0, min(10, spir));

    assignin('base','spir_in', [cur_t, spir]);

    fprintf("vent=%.1f | sensor=%d | y=%.3f | u=%.3f | Kp=%.2f Ki=%.2f Kd=%.2f\n", vent, sensor_mode, y_meas, spir, Kp, Ki, Kd);

    cur_t = cur_t + Ts;
    pause(Ts); 
end

disp("Simulation stopped");
