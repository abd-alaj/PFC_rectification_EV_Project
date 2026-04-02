% this file takes data and processes it. that's it.

% Load the data file
load('R_load_data.mat');

% Extract Run 2
run2 = data{2};

% Extract signals to local variables
t         = run2.get('V_out').Values.Time;
v_out     = run2.get('V_out').Values.Data;
i_out     = run2.get('I_out').Values.Data;
curr_draw = run2.get('Current_draw').Values.Data;
ind_curr  = run2.get('Inductor_current').Values.Data;

% Formatting variables
lw       = 1.5;
fontName = 'CMU Serif';
fontSize = 12;

%% 1. V_out Plot (0 to 2s)
figure('Color', 'w');
subplot(2,1,1);
plot(t, v_out, 'LineWidth', lw);
hold on;
yline(400, '--r', '400V Target', 'LineWidth', 1.2, 'FontName', fontName);
xlim([0 2]);
ylabel('Voltage (V)', 'FontName', fontName);
set(gca, 'TickLabelInterpreter', 'latex', 'FontName', fontName, 'FontSize', fontSize);
grid on;

%% 2. V_out Ripple (0.58 to 0.65s)
subplot(2,1,2);
mask_v = (t >= 0.58 & t <= 0.65);
t_v    = t(mask_v);
v_v    = v_out(mask_v);

% Hardcoded ripple points
t_vmin = 0.612991; v_min = 398.3;
t_vmax = 0.614525; v_max = 405.7;
v_ripple = v_max - v_min;

plot(t_v, v_v, 'LineWidth', lw);
hold on;
plot(t_vmin, v_min, 'bo', 'MarkerFaceColor', 'b');
plot(t_vmax, v_max, 'ro', 'MarkerFaceColor', 'r');
text(t_vmax, v_max + 1, sprintf('Ripple: %.2f V', v_ripple), ...
    'FontName', fontName, 'FontWeight', 'bold');
xlim([0.58 0.65]);
xlabel('Time (s)', 'FontName', fontName);
ylabel('Voltage (V)', 'FontName', fontName);
set(gca, 'TickLabelInterpreter', 'latex', 'FontName', fontName, 'FontSize', fontSize);
grid on;

exportgraphics(gcf, 'V_out.pdf', 'ContentType', 'vector');

%% 3. I_out Plot (0 to 2s)
figure('Color', 'w');
subplot(2,1,1);
plot(t, i_out, 'LineWidth', lw);
hold on;
yline(36, '--r', '36A Target', 'LineWidth', 1.2, 'FontName', fontName);
xlim([0 2]);
ylabel('Current (A)', 'FontName', fontName);
set(gca, 'TickLabelInterpreter', 'latex', 'FontName', fontName, 'FontSize', fontSize);
grid on;

%% 4. I_out Ripple (0.58 to 0.65s)
subplot(2,1,2);
i_v = i_out(mask_v);

% Hardcoded ripple points
t_imin = 0.6130; i_min = 35.88;
t_imax = 0.6146; i_max = 36.55;
i_ripple = i_max - i_min;

plot(t_v, i_v, 'LineWidth', lw);
hold on;
plot(t_imin, i_min, 'bo', 'MarkerFaceColor', 'b');
plot(t_imax, i_max, 'ro', 'MarkerFaceColor', 'r');
text(t_imax, i_max + 0.05, sprintf('Ripple: %.2f A', i_ripple), ...
    'FontName', fontName, 'FontWeight', 'bold');
xlim([0.58 0.65]);
xlabel('Time (s)', 'FontName', fontName);
ylabel('Current (A)', 'FontName', fontName);
set(gca, 'TickLabelInterpreter', 'latex', 'FontName', fontName, 'FontSize', fontSize);
grid on;

exportgraphics(gcf, 'I_out.pdf', 'ContentType', 'vector');

%% 5. Current Draw & Inductor Current (0.5 to 0.6s)
figure('Color', 'w');
mask_zoom = (t >= 0.5 & t <= 0.6);

% Current Draw
subplot(2,1,1);
plot(t(mask_zoom), curr_draw(mask_zoom), 'LineWidth', lw);
ylabel('Current Draw (A)', 'FontName', fontName);
xlim([0.5 0.6]);
set(gca, 'TickLabelInterpreter', 'latex', 'FontName', fontName, 'FontSize', fontSize);
grid on;

% Inductor Current
subplot(2,1,2);
plot(t(mask_zoom), ind_curr(mask_zoom), 'LineWidth', lw);
ylabel('Inductor Current (A)', 'FontName', fontName);
xlabel('Time (s)', 'FontName', fontName);
xlim([0.5 0.6]);
set(gca, 'TickLabelInterpreter', 'latex', 'FontName', fontName, 'FontSize', fontSize);
grid on;

exportgraphics(gcf, 'curr_draw_and_inductor.pdf', 'ContentType', 'vector');