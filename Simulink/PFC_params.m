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

Ts = 1e-6;                


% set your L and C values here,
% these will be overwritten if you have
% params_from_ripple_minimas set to true
L = 500e-6;
C = 30e-3;
target_PM = 50;

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

%% Current Plant
% inductor current pertubation plant in relation to d(s)
ils_num = [V_batt * C, (V_batt / R) + D_bar * I_L];
ils_den = [L*C, L/R, D_bar^2];
ils = tf(ils_num, ils_den) * (1/Vac);

%% Control Params
Ts_controller = 1 / (2 * f_sw);
