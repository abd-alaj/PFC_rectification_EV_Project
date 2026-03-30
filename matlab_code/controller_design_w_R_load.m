clear; clc; close all;

Vac_rms = 240;
Vac_peak = Vac_rms * sqrt(2);
f_line = 60;
omega_line = 2*pi*f_line;
V_batt = 400;
I_batt = 36; 

% redefined R as just 11.1 ohms instead of a calculated value. 
R = V_batt / I_batt; 
P_avg = V_batt * I_batt; 
I_L = (P_avg / Vac_rms) * sqrt(2); 

D = 1 - Vac_peak/V_batt;
D_prime = 1 - D;
L = 500e-6;
C = 30e-3;
fs = 100e3;

s = tf('s');
den_coeff = [L*C, L/R, D_prime^2];
num_i_coeff = [V_batt*C, V_batt/R + D_prime*I_L];
num_v_coeff = [-L*I_L, D_prime*V_batt];

G_i_exact = tf(num_i_coeff, den_coeff);
G_v_exact = tf(num_v_coeff, den_coeff);

omega_n = D_prime / sqrt(L*C);
zeta = 1 / (2*R*C*omega_n);
fn = omega_n / (2*pi);
z_voltage_rhp = num_v_coeff(2)/(-num_v_coeff(1));

fc_i = fs / 20;
omega_c_i = 2*pi*fc_i;
PM_i_target = 60;

[mag_i, phase_i] = bode(G_i_exact, omega_c_i);
mag_plant_i = mag_i;
phase_plant_i = phase_i;

phi_z_needed_i = -90 + PM_i_target - phase_plant_i;
omega_z_i = omega_c_i / tand(phi_z_needed_i);
Kp_i = omega_c_i / (mag_plant_i * sqrt(omega_c_i^2 + omega_z_i^2));
Ki_i = Kp_i * omega_z_i;

C_i = Kp_i + Ki_i/s;
L_i_ol = C_i * G_i_exact;
[Gm_i, Pm_i, ~, wc_i_actual] = margin(L_i_ol);
T_i_cl = feedback(L_i_ol, 1);

K_v = Vac_peak / (2 * V_batt * C);
omega_p_v = 2 / (R * C);
G_v_avg = tf(K_v, [1, omega_p_v]);

fc_v = 5;
omega_c_v = 2*pi*fc_v;
[mag_v, phase_v] = bode(G_v_avg, omega_c_v);
mag_plant_v = mag_v;
phase_plant_v = phase_v;

PM_v_target = 60;
phi_z_needed_v = -90 + PM_v_target - phase_plant_v;
omega_z_v = omega_c_v / tand(phi_z_needed_v);
Kp_v = omega_c_v / (mag_plant_v * sqrt(omega_c_v^2 + omega_z_v^2));
Ki_v = Kp_v * omega_z_v;

C_v = Kp_v + Ki_v/s;
L_v_ol = C_v * G_v_avg;
[Gm_v, Pm_v, ~, wc_v_actual] = margin(L_v_ol);
T_v_cl = feedback(L_v_ol, 1);

fprintf('Inner loop PID:')
fprintf('Kp_i = %.8f, Ki_i = %.8f\n', Kp_i, Ki_i);
fprintf('Outer loop PID')
fprintf('Kp_v = %.8f, Ki_v = %.8f\n', Kp_v, Ki_v);

L_v_nested = C_v * G_v_avg * T_i_cl;
[~, Pm_nested] = margin(L_v_nested);
fprintf('\nNested PM: %.2f degrees\n', Pm_nested);

% visualizations
w_vec = logspace(0, 7, 500);

subplot(2,1,1);
bode(G_i_exact, tf(V_batt, [L, 0]), w_vec); 
title('G_i: Exact vs Simplified');
legend('Exact', 'Simplified');
grid on;

subplot(2,1,2);
bode(G_v_exact, w_vec);
title('G_v Exact (RHP Zero Analysis)');
grid on;

figure(2);
subplot(2,1,1);
margin(L_i_ol);
grid on;
subplot(2,1,2);
step(T_i_cl);
title('Inner Loop Step Response');
grid on;

figure(3);
margin(L_v_ol);
grid on;

figure(4);
step(T_v_cl);
title('Outer Loop Step Response');
grid on;

% Nested Verification
L_v_nested = C_v * G_v_avg * T_i_cl;
[~, Pm_nested] = margin(L_v_nested);
fprintf('\nNested PM: %.2f degrees\n', Pm_nested);