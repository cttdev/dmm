close all;

masses = [0.01 0.02 0.05 0.1  0.2  0.5  1.  ]; % kg
voltages = [0.00129429 0.00129966 0.0013229  0.00136356 0.00144398 0.00169639 0.00211873]; % V

wire_offset = 0.0012904472817207; % V

voltages_tf = (voltages - wire_offset)';
masses_tf = masses';

% Compute the fit
linear = @(a, x) a * x;
f = fit(voltages_tf, masses_tf, linear, "StartPoint", 1);

% Extract the params and 95% CI
conf_level = 0.95;
params = coeffvalues(f)
ci = confint(f, conf_level);
uncertainty = diff(ci) / 2

% Compute the domain for the fit line
x_fit = linspace(min(voltages_tf), max(voltages_tf), 100);
y_fit = predint(f, x_fit, conf_level, 'functional', 'off');

% Extract the upper and lower bounds of the fit
y_fit_upper = y_fit(:, 2);
y_fit_lower = y_fit(:, 1);

% Compute the region boundriaes
x_fit_region = [x_fit, fliplr(x_fit)];
in_between_region = [y_fit_upper; flipud(y_fit_lower)];

% Plot the data. curve fit, and shaded region
hf = fill(x_fit_region, in_between_region, "blue", "DisplayName", "95% Confidence Bounds");
hf.FaceAlpha = 0.5;
hf.FaceColor = "#0072BD";
hf.EdgeColor = "none";
hold on

plot(x_fit, f(x_fit), "Color", "#0072BD", "DisplayName", "Linear Fit: a * x; a = (1216 ± 26) kg/V")
plot(voltages_tf, masses_tf, "o", "Color", "#0072BD", "DisplayName", "Data")

% legend()
title("Strain Gauge Calibration")
xlabel("Voltage (V)")
ylabel("Mass (kg)")
improvePlot

% % Shade the region
% hf = fill(x2, in_between, 'm', 'DisplayName', '95% confidence bounds');
% hold on;
% 
% % Adjust some of the parameters of the shading
% hf.FaceAlpha = 0.5; % Make shading semi-transparent
% hf.FaceColor = 'm'; % Set color of shaded region
% hf.EdgeColor = 'none'; % Set color of edge of shaded region
% 
% % Plot the least squares fit of the data
% plot(x_, feval(fit_object, x_), 'b-', 'DisplayName', 'LSQ fit');  
% 
% plot(x, y, 'ro', 'DisplayName', 'Data');  % Plot data last so it appears on top
% xlabel('X (arb)');
% ylabel('Y (arb)');
% legend;
% improvePlot;


figure
