clc, clear, close all

load switch_1st.mat

vars = whos;

for k = 1:length(vars)
    name = vars(k).name;
    val = eval(name);

    if isnumeric(val) && isvector(val)
        val = val(:);          % force column
        if length(val) >= 7000
            val = val(1221:7000); % true 1:7000
            eval([name ' = val;']);
        end
    end
end
time = time - time(1);

whos

sp_all = [sp_global_soft(1:1280); sp_local(1281:1780) + 4.4884; sp_global_soft(1781:4280); sp_local(4281:4780) + 6.3412; sp_global_soft(4781:end)];

T = table(time, snimac1, sp_all, u_global, u_local, mode_local, sp_global, sp_global_soft, sp_local, 'VariableNames', {'time','y','sp_all', 'u_global','u_local','mode_local', 'sp_global','sp_global_soft','sp_local'});
fname = fullfile('ts_ml_switch_1st.csv');
writetable(T, fname); 



