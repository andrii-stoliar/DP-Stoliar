function [u, integrator_out, Kp_out, Ki_out] = pi_controller_interp_state(y, setpoint, setpoint_prev, integrator_in, Kp_in, Ki_in)

% Adaptive PI controller 
%
% Inputs:
%   y              - current system output
%   setpoint       - current setpoint
%   setpoint_prev  - previous setpoint
%   integrator_in  - previous integrator value
%   Kp_in, Ki_in   - previous PI parameters
%
% Outputs:
%   u              - control signal
%   integrator_out - updated integrator
%   Kp_out, Ki_out - current PI parameters

% Constants
Ts = 0.1;     
tol = 0.05;   
u_min = 0;
u_max = 10;

% Load PI table (only once)
persistent params
if isempty(params)
    tmp = load('pi_parameters_6_near_by_step.mat', 'pi_matrix_6_near');
    params = tmp.pi_matrix_6_near;
end

% Step change detection
delta_sp = abs(setpoint - setpoint_prev);

if delta_sp > tol
    % step amplitude
    step_amp = delta_sp;
    step_amp = min(max(step_amp, params.Step(1)), params.Step(end));
    
    % interpolate PI params
    Kp_out = interp1(params.Step, params.Kp, step_amp);
    Ki_out = interp1(params.Step, params.Ki, step_amp);
else
    % keep old parameters
    Kp_out = Kp_in;
    Ki_out = Ki_in;
end

% PI computation
e = setpoint - y;
integrator_out = integrator_in + e * Ts;
u = Kp_out * e + Ki_out * integrator_out;

if u > u_max
    u = u_max;
elseif u < u_min
    u = u_min;
end
end
