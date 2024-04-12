clear;
close all;

nozzle_bores = [0.4, 0.4, 0.6, 0.8]; % mm
files = ["0.4mm_PLT", "0.4mm_VOL", "0.6mm_VOL", "0.8mm_VOL"];
duts = ["0.4mm Plated Copper", "0.4mm Brass Volcano", "0.6mm Brass Volcano", "0.8mm Brass Volcano"];

% Construct plots of each trials and their fits and one overall plot
plot_colors = ["#0072BD", "#EDB120", "#D95319", "#A2142F", "#7E2F8E", "#77AC30", "#4DBEEE"];
mean_and_uncertainties_n = ["(4.2 ± 1.7)", "(1.48 ± 0.27)", "(2.11 ± 0.86)", "(0.84 ± 0.15)", "(0.74 ± 0.14)"];
handles = [];

bore_sizes = [];
constants = [];
constants_uncertainties = [];
powers = [];
powers_uncertainties = [];

for k = 1:length(files)
    % Load the data from the file
    load("data_processed\" + files(k), "flow_rates_sorted", "data_sorted", "masks_sorted", "offsets", "num_trials");

    % Concatenate and plot the data per trial
    dut_flow_rates = [];
    dut_mean_forces = [];

    for j = 1:num_trials
        mean_forces = zeros(length(flow_rates_sorted), 1);
        for i = 1:length(flow_rates_sorted)
            mask = logical(squeeze(masks_sorted(i, j, :)));
    
            times = squeeze(data_sorted(i, j, :, 1));
            forces = squeeze(data_sorted(i, j, :, 2));
            forces = forces * 9.81;
    
            zero_offset = offsets(i, j);
            zero_offset = zero_offset * 9.81;
    
            times = times(mask);
            forces = forces(mask) - zero_offset;
    
            mean_forces(i) = mean(forces);
        end

        dut_flow_rates = [dut_flow_rates, flow_rates_sorted];
        dut_mean_forces = [dut_mean_forces, mean_forces'];
        
        figure(1)
        subplot(2, 2, k)
        plot(flow_rates_sorted, mean_forces, "o", "Color", plot_colors(mod(j, length(plot_colors))), "DisplayName", "Raw Data Trial " + num2str(j))
        hold on

        % Compute the fit per trial
        f = fit(flow_rates_sorted', mean_forces, "power1")
    
        % Extract the params and 95% CI
        conf_level = 0.95;
        params = coeffvalues(f);
        ci = confint(f, conf_level);
        uncertainty = diff(ci) / 2
        
        % Save the fit data
        bore_sizes = [bore_sizes, nozzle_bores(k)];
        constants = [constants, params(1)];
        constants_uncertainties = [constants_uncertainties, uncertainty(1)];
        powers = [powers, params(2)];
        powers_uncertainties = [powers_uncertainties, uncertainty(2)];
    end

    figure(2)
    h = plot(dut_flow_rates, dut_mean_forces, "o", "Color", plot_colors(mod(k, length(plot_colors))), "DisplayName", duts(k));
    handles = [handles, h];
    hold on

    % Compute the power law fit on the data
    f = fit(dut_flow_rates', dut_mean_forces', "power1")
    
    % Extract the params and 95% CI
    conf_level = 0.95;
    params = coeffvalues(f);
    ci = confint(f, conf_level);
    uncertainty = diff(ci) / 2
    
    % Compute the domain for the fit line
    x_fit = linspace(min(flow_rates_sorted), max(flow_rates_sorted), 100);
    y_fit = predint(f, x_fit, conf_level, 'functional', 'off');
    
    % Extract the upper and lower bounds of the fit
    y_fit_upper = y_fit(:, 2);
    y_fit_lower = y_fit(:, 1);
    
    % Compute the region boundriaes
    x_fit_region = [x_fit, fliplr(x_fit)];
    in_between_region = [y_fit_upper; flipud(y_fit_lower)];
    
    % Plot the data, curve fit, and shaded region
    figure(1)
    subplot(2, 2, k)
    hf = fill(x_fit_region, in_between_region, "m", "DisplayName", "95% Confidence Bounds");
    hf.FaceAlpha = 0.5;
    hf.FaceColor = plot_colors(mod(k, length(plot_colors)));
    hf.EdgeColor = "none";
    
    plot(x_fit, f(x_fit), "Color", plot_colors(mod(k, length(plot_colors))), "DisplayName", "Power Law Fit")

    title(duts(k) + " Nozzle")
    xlabel("Flow Rate (mm^3 / s)")
    ylabel("Extrusion Force (kg)")
    improvePlot
    linkaxes

    figure(2)
    hf = fill(x_fit_region, in_between_region, "m", "DisplayName", duts(k) + " 95% Confidence Bounds");
    hf.FaceAlpha = 0.5;
    hf.FaceColor = plot_colors(mod(k, length(plot_colors)));
    hf.EdgeColor = "none";

    plot(x_fit, f(x_fit), "Color", plot_colors(mod(k, length(plot_colors))), "DisplayName", duts(k) + " Fit")

    % Plot the points for the constant versus bore size
    figure(3)
    
    % Compute total uncertianty using Case 1A
    % t_val = 2.776;
    bore_size_vals = bore_sizes(end-(num_trials-1):end);
    constant_vals = constants(end-(num_trials-1):end);
    constants_uncertainty_vals = constants_uncertainties(end-(num_trials-1):end);

    % u_avg = t_val * std(constant_vals) / sqrt(num_trials);
    % u_indiv = sqrt(sum((1 / num_trials * constants_uncertainty_vals).^2));
    % u_tot = sqrt(u_avg^2 + u_indiv^2);

    h = errorbar(bore_size_vals, constant_vals, constants_uncertainty_vals, "o", "Color", plot_colors(mod(k, length(plot_colors))));
    alpha = 0.5;
    set([h.Bar, h.Line], 'ColorType', 'truecoloralpha', 'ColorData', [h.Line.ColorData(1:3); 255*alpha])
    set(h.Cap, 'EdgeColorType', 'truecoloralpha', 'EdgeColorData', [h.Cap.EdgeColorData(1:3); 255*alpha])
    hold on

    % Plot the points for the power versus bore size
    figure(4)
    
    % Compute total uncertianty using Case 1A
    % t_val = 2.776;
    bore_size_vals = bore_sizes(end-(num_trials-1):end);
    powers_vals = powers(end-(num_trials-1):end);
    powers_uncertainty_vals = powers_uncertainties(end-(num_trials-1):end);

    % u_avg = t_val * std(powers_vals) / sqrt(num_trials);
    % u_indiv = sqrt(sum((1 / num_trials * powers_uncertainty_vals).^2));
    % u_tot = sqrt(u_avg^2 + u_indiv^2);

    h = errorbar(bore_size_vals, powers_vals, powers_uncertainty_vals, "o", "Color", plot_colors(mod(k, length(plot_colors))))
    alpha = 0.5;
    set([h.Bar, h.Line], 'ColorType', 'truecoloralpha', 'ColorData', [h.Line.ColorData(1:3); 255*alpha])
    set(h.Cap, 'EdgeColorType', 'truecoloralpha', 'EdgeColorData', [h.Cap.EdgeColorData(1:3); 255*alpha])
    hold on
end

figure(2)
title("All Trials Extrusion Profile for Each Nozzle")
xlabel("Flow Rate (mm^3 / s)")
ylabel("Extrusion Force (N)")
y_limit = ylim;
ylim([0, y_limit(2)])
improvePlot

figure(3)
bore_sizes_mod = bore_sizes(num_trials+1:end);
constants_mod = constants(num_trials+1:end);

mean_val = mean(powers);
power_val = 3;

% Compute the power law fit on the data
f = fit(bore_sizes_mod', constants_mod', "a/x^" + num2str(power_val))

% Extract the params and 95% CI
conf_level = 0.95;
params = coeffvalues(f);
ci = confint(f, conf_level);
uncertainty = diff(ci) / 2

% Compute the domain for the fit line
x_fit = linspace(min(bore_sizes_mod), max(bore_sizes_mod), 100);
y_fit = predint(f, x_fit, conf_level, 'functional', 'off');

% Extract the upper and lower bounds of the fit
y_fit_upper = y_fit(:, 2);
y_fit_lower = y_fit(:, 1);

% Compute the region boundriaes
x_fit_region = [x_fit, fliplr(x_fit)];
in_between_region = [y_fit_upper; flipud(y_fit_lower)];

% Plot the data, curve fit, and shaded region
hf = fill(x_fit_region, in_between_region, "m", "DisplayName", "95% Confidence Bounds");
hf.FaceAlpha = 0.5;
hf.FaceColor = "#CD5D23";
hf.EdgeColor = "none";

plot(x_fit, f(x_fit), "Color", "#CD5D23", "DisplayName", "Power Law Fit")

xlim([0.35, 0.85])
xlabel("Bore Size (mm)")
ylabel("Fit Constant: a", "Interpreter", "latex")
improvePlot

figure(4)

% % Compute the power law fit on the data
% f = fit(bore_sizes', powers', "a*x+b")
% 
% % Extract the params and 95% CI
% conf_level = 0.95;
% params = coeffvalues(f);
% ci = confint(f, conf_level);
% uncertainty = diff(ci) / 2
% 
% % Compute the domain for the fit line
% x_fit = linspace(min(bore_sizes), max(bore_sizes), 100);
% y_fit = predint(f, x_fit, conf_level, 'functional', 'off');
% 
% % Extract the upper and lower bounds of the fit
% y_fit_upper = y_fit(:, 2);
% y_fit_lower = y_fit(:, 1);
% 
% % Compute the region boundriaes
% x_fit_region = [x_fit, fliplr(x_fit)];
% in_between_region = [y_fit_upper; flipud(y_fit_lower)];
% 
% % Plot the data, curve fit, and shaded region
% hf = fill(x_fit_region, in_between_region, "m", "DisplayName", "95% Confidence Bounds");
% hf.FaceAlpha = 0.5;
% hf.FaceColor = plot_colors(mod(k, length(plot_colors)));
% hf.EdgeColor = "none";
% 
% plot(x_fit, f(x_fit), "Color", plot_colors(mod(k, length(plot_colors))), "DisplayName", "Power Law Fit")

% Compute the power law fit on the data
mean_val = mean(powers);

% Extract the params and 95% CI
t_val = 2.093;
uncertainty = t_val * std(powers) / sqrt(length(powers));

% Compute the domain for the fit line
x_fit = [min(bore_sizes), max(bore_sizes)];

% Extract the upper and lower bounds of the fit
y_fit_upper = repelem(mean_val + uncertainty, 2);
y_fit_lower = repelem(mean_val - uncertainty, 2);

% Compute the region boundriaes
x_fit_region = [x_fit, fliplr(x_fit)];
in_between_region = [y_fit_upper, flipud(y_fit_lower)];

% Plot the data, curve fit, and shaded region
hf = fill(x_fit_region, in_between_region, "m", "DisplayName", "95% Confidence Bounds");
hf.FaceAlpha = 0.5;
hf.FaceColor = "#9A6249";
hf.EdgeColor = "none";

plot(x_fit, repelem(mean_val, 2), "Color", "#9A6249", "DisplayName", "Power Law Fit")

xlim([0.35, 0.85])
xlabel("Bore Size (mm)")
ylabel("Fit Constant: n", "Interpreter", "latex")
improvePlot
