clear; clc;


% DISCLAIMER
% I tried everything to make this code give me a stable voltage controller
% and couldn't for the life of me make one...
% I gave up and just used the matlab PID tune function because it does some
% voodoo black magic shit that at the time of writing i don't understand.
% There's something in control systems or the other courses that may or may
% not have taught me that solves this issue, but i employed the strategies
% i knew and it didn't fucking work. I tried fucking EVERYTHING. HELL I
% EVEN TRIED TO FUCKING USE A POLE ZERO MODEL INSTEAD OF A PI, A STATE
% SPACE MODEL, EVERYTHING. EVEN DISCRETIZATION OF THE PLANT AND WORKING
% COMPLETELY IN THE DISCRETE DOMAIN BY HAND. NOTHING WORKED.

% I'm probably making the same mistake over and over again and this script
% is part of this endeavor. 

% I have too much shame to just delete this script. I spent 8+ hours making
% this script and debugging without ANY HELP OF AI because because
% approaching it before hand they would just state to put a pole at negative
% infinity or tell my script or hand calculations were wrong and then do
% the EXACT SAME FUCKING THING I DID but in a more convoluted manner.
% TSPMO
% either way, AI sucks for creation of a PI controller. 
% I am so mad at myself for spending so many tokens begging AI to find a 
% solution before I gave up and just went through the controls
% textbook. 

% TLDR: this script doesn't work. don't use it. It brings shame to my
% professor, my faculty, my supervisor, and my university. yet I cannot go
% out back and put it down like Old Yelller, I made it. It's mine, and it's
% failure is a result of it being mine. But I don't care. It stays on
% github. It stays on my PC, because atleast its my fucking work. 

% Parameters
Vac_rms = 240;
Vac = Vac_rms * sqrt(2);
I_rms = 60;
I_ac = 60 * sqrt(2);
I_L = I_ac;
f_line = 60;
omega_line = 2*pi*f_line;
V_batt = 400;
P_out = Vac_rms * I_rms;
I_batt = P_out / V_batt;
% sample load, this assumes a full load resistor for some calculations
R = V_batt / I_batt;
D = 1 - Vac/V_batt;
D_bar = 1 - D;
% set this variable to true if you are finding min capacitor or inductor
% for a boost PFC
params_from_ripple_minimas = false;
% set these ripple values if you are trying to determine a correct cap
current_ripple = 3;
voltage_ripple = 4;
% set the switching frequency, reasonable frequency switching would be:
% GaN MOSFET switches fall in the range of 120 kHz+ with max power of <2 kW
% SiC switch are in the range of 10kHz to 10 MHz with power rating of sub 1 MW
% IGBT switches at 12 Hz - 11 kHz, wattage max rating of 10 MW
f_sw = 50e3;
Ts = 1 / f_sw;
% set your L and C values here,
% these will be overwritten if you have
% params_from_ripple_minimas set to true
L = 500e-6;
C = 30e-3;
% Target Values
target_PM = 50; % change this if you would like to have a diff phase margin

%% For Voltage ripple calculations
if (params_from_ripple_minimas == true)
% redefine your L and C values
    L = (Vac / (2 * f_sw * current_ripple)) * (1 - (Vac / V_batt));
    C = P_out / (4 * omega_line * V_batt);
    disp('You have set params_from_ripple_minimas to true, if this is a mistake, invert that var and rerun the script');
    disp('your absolute minimum values for inductor and capacitor is:\n');
    disp(['L = ', num2str(L), 'C = ', num2str(C)]);
    disp('These values will be used to design your controller')
end

%% Voltage Plant
% output voltage pertubation plant in relation to d(s)
% these were derived by hand, I do not know how to do this via simscape,
% sorry
omega_lc = 1/sqrt(L*C);
omega_rhp = (D_bar * V_batt) / (L * I_L);
vbs_num = [-L * I_L, D_bar * V_batt];
vbs_den = [L*C, L/R, D_bar^2];
vbs = tf(vbs_num, vbs_den) * (1/V_batt);

omega_cv_max = omega_lc / 5;
omega_cv     = min(2*pi*8, omega_cv_max);

[mag_v_raw, phase_v_raw] = bode(vbs, omega_cv);
mag_v = mag_v_raw(1);
phase_v = mod(phase_v_raw(1) + 180, 360) - 180;

phase_vsys = target_PM - phase_v + 90;
omega_zv = omega_cv / tand(phase_vsys);

Kp_v = omega_cv / (mag_v * sqrt(omega_cv^2 + omega_zv^2));
Ki_v = Kp_v * omega_zv;

%% Current Plant
% inductor current pertubation plant in relation to d(s)
ils_num = [V_batt * C, (V_batt / R) + D_bar * I_L];
ils_den = [L*C, L/R, D_bar^2];
ils = tf(ils_num, ils_den) * (1/Vac);

omega_ci = (2 * pi * f_sw) / 10;
[mag_i_raw, phase_i_raw] = bode(ils, omega_ci);
mag_i = mag_i_raw(1);

phase_i = mod(phase_i_raw(1) + 180, 360) - 180;

phase_isys = target_PM - phase_i + 90;
omega_zi = omega_ci / tand(phase_isys);

% Standard PI Gain Formula
Kp_i = omega_ci / (mag_i * sqrt(omega_ci^2 + omega_zi^2));
Ki_i = Kp_i * omega_zi;

%% Print Results
disp('Voltage loop:');
disp(['Kp_v = ', num2str(Kp_v), ' Ki_v = ', num2str(Ki_v)]);
disp('Current loop:');
disp(['Kp_i = ', num2str(Kp_i), ' Ki_i = ', num2str(Ki_i)]);

%% Graph these results
s = tf('s');
C_v = Kp_v + Ki_v/s;
C_i = Kp_i + Ki_i/s;
L_v = C_v * vbs;
L_i = C_i * ils;

figure(1);
margin(L_i);
title('C_i (s)');
figure(2);
margin(L_v);
title('C_v (s)');

%% Debugging
disp('Current Plant')
disp(['LC resonance (rad/s): ', num2str(omega_lc)]);
disp(['RHP zero (rad/s):     ', num2str(omega_rhp)]);
disp(['D_bar:                ', num2str(D_bar)]);
disp(['I_L used in plant:    ', num2str(I_L)]);

disp('Voltage Plant');
disp(['mag_v (linear):  ', num2str(mag_v)]);
disp(['phase_v (deg):   ', num2str(phase_v)]);
disp(['phase_vsys:      ', num2str(phase_vsys)]);
disp(['omega_zv:        ', num2str(omega_zv)]);
disp(['Kp_v:            ', num2str(Kp_v)]);
disp(['Ki_v:            ', num2str(Ki_v)]);

%% Simulink Extraction
Ts_controller = 1 / (2 * f_sw);
assignin('base', 'Kp_v', Kp_v);
assignin('base', 'Ki_v', Ki_v);
assignin('base', 'Kp_i', Kp_i);
assignin('base', 'Ki_i', Ki_i);
assignin('base', 'Ts',   Ts);
assignin('base', 'Tsc',  Ts_controller);