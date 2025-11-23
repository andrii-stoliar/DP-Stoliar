function [u, integrator_out, y_ss_out] = pi_block(y, setpoint, integrator_in, time, y_ss_in)

% PI controller

% Inputs:
%   y            
%   setpoint       
%   integrator_in  
%   Kp, Ki        

% Outputs:
%   u            
%   integrator_out 

    pb_u = 4;
    Ts = 0.1;  
    u_min = - pb_u;
    u_max = 10 - pb_u;
    Kp = 12.6;
    Ki = 5.69;

    %init state of integrator

    if time < 10*60
        u = 4;
        y_ss_out = y;
    else
        
        y_ss_out = y_ss_in;
        pb_y = y_ss_in;
        %Outputs normalization
        y = y - pb_y; 

        % PI control law
        e = setpoint - y;

        if time <= 0.1
            integrator_out = 0;
        else
            integrator_out = integrator_in + e * Ts;
        end

        u = Kp * e + Ki * integrator_out;
        u = min(max(u, u_min), u_max);

        %Inputs normalization
        u = u + pb_u;

    end

end
