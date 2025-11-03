clc
clear
close all

load prevodova_mer/prevodova_vent9.mat

time = time(1:end-1);
snimac1 = snimac1(1:end-1);
snimac2 = snimac2(1:end-1);
spir = spir(1:end-1);
vent = vent(1:end-1);

for i = 1:11
    from = (i-1)*2400 + 1999;
    to = from + 400;
    static1(i) = mean(snimac1(from:to));
    static2(i) = mean(snimac2(from:to));
    in(i) = i-1;
end

csvwrite('prevodova9.csv', [time, vent, spir, snimac1, snimac2]);
csvwrite('static9.csv', [in', static1', static2']);
