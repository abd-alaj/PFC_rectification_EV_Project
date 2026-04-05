clear; clc; close all;
lw       = 1.5;
fontName = 'CMU Serif';
fontSize = 12;
%% This matlab script calculates power factor and total harmonic distortion given a .mat file.
load("./controller_w_r_load_data.mat");
v_out_sig = data.getElement('V_out');
t         = v_out_sig.Values.Time;
v_out     = v_out_sig.Values.Data;
i_out     = data.getElement('I_out').Values.Data;
curr_draw = data.getElement('current_draw').Values.Data;
ind_curr  = data.getElement('inductor_current').Values.Data;
v_in      = data.getElement('V_in').Values.Data;
f0 = 60;                        % fundamental frequency (Hz)
fs = 1 / mean(diff(t));         % sampling frequency from time vector
t_start = 1.8;
t_end   = 2.0;
idx     = t >= t_start & t <= t_end;
t_ss    = t(idx);
curr_ss = curr_draw(idx);
v_ss    = v_out(idx);
%% FFT
N        = length(curr_ss);
f_axis   = (0:N-1) * (fs / N);
curr_fft = fft(curr_ss) / N;
curr_mag = 2 * abs(curr_fft(1:floor(N/2)));
%% Find harmonics
f_harmonics  = f0 * (1:10);
harmonic_amp = zeros(1, 10);
for k = 1:10
    [~, idx_h]      = min(abs(f_axis - f_harmonics(k)));
    harmonic_amp(k) = curr_mag(idx_h);
end
%% THD calculation
fundamental = harmonic_amp(1);
harmonics   = harmonic_amp(2:end);
THD         = (sqrt(sum(harmonics.^2)) / fundamental) * 100;
%% Power Factor
v_in_ss = v_in(idx);
V_rms = rms(v_in_ss);
I_rms = rms(curr_ss);
S     = V_rms * I_rms;
P     = mean(v_in_ss .* curr_ss);
PF    = P / S;
%% Display
fprintf('=== THD & Power Factor Analysis ===\n');
fprintf('Fundamental (60Hz) amplitude : %.4f A\n', fundamental);
fprintf('THD                          : %.2f %%\n', THD);
fprintf('V_rms                        : %.2f V\n', V_rms);
fprintf('I_rms                        : %.2f A\n', I_rms);
fprintf('Real Power                   : %.2f W\n', P);
fprintf('Apparent Power               : %.2f VA\n', S);
fprintf('Power Factor                 : %.4f\n', PF);
%% Plot harmonics
figure('Color', 'w');
bar(f_harmonics, harmonic_amp, 'LineWidth', lw);
xlabel('Frequency (Hz)', 'FontName', fontName);
ylabel('Amplitude (A)',  'FontName', fontName);
title(sprintf('Input Current Harmonics — THD: %.2f%%, PF: %.4f', THD, PF), ...
'FontName', fontName);
set(gca, 'TickLabelInterpreter', 'latex', 'FontName', fontName, 'FontSize', fontSize);
grid on;
exportgraphics(gcf, 'thd_harmonics.pdf', 'ContentType', 'vector');
%% Plot steady state current vs reference sinusoid
figure('Color', 'w');
plot(t_ss, curr_ss, 'LineWidth', lw);
hold on;
plot(t_ss, fundamental .* abs(sin(2*pi*f0*t_ss)), '--r', 'LineWidth', 1.2);
xlabel('Time (s)',        'FontName', fontName);
ylabel('Current (A)',     'FontName', fontName);
title('Steady State Input Current vs Fundamental', 'FontName', fontName);
legend({'Measured', 'Fundamental'}, 'FontName', fontName, 'Interpreter', 'latex');
set(gca, 'TickLabelInterpreter', 'latex', 'FontName', fontName, 'FontSize', fontSize);
grid on;
exportgraphics(gcf, 'thd_current_ss.pdf', 'ContentType', 'vector');
