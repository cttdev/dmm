clear;
close all;

nozzle_bores = [0.4, 0.4, 0.6, 0.8]; % mm
files = ["0.4mm_PLT", "0.4mm_VOL", "0.6mm_VOL", "0.8mm_VOL"];
duts = ["0.4mm Plated Copper", "0.4mm Brass Volcano", "0.6mm Brass Volcano", "0.8mm Brass Volcano"];

% Construct plots of each trials and their fits and one overall plot
plot_colors = ["#0072BD", "#D95319", "#EDB120", "#7E2F8E", "#77AC30", "#4DBEEE", "#A2142F"];
mean_and_uncertainties_n = ["(4.2 ± 1.7)", "(1.48 ± 0.27)", "(2.11 ± 0.86)", "(0.84 ± 0.15)", "(0.74 ± 0.14)"];
handles = [];

bore_sizes = [];
normalized_mean_forces = [];

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
    
            zero_offset = offsets(i, j);
    
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
    end

    figure(2)
    h = plot(dut_flow_rates, dut_mean_forces, "o", "Color", plot_colors(mod(k, length(plot_colors))), "DisplayName", duts(k));
    handles = [handles, h];
    hold on

    if k > 1
        figure(3)
        normalized_mean_force = dut_mean_forces ./ dut_flow_rates;
        plot(nozzle_bores(k), normalized_mean_force, "o", "Color", plot_colors(mod(k, length(plot_colors))), "DisplayName", "Normalized")
        hold on

        bore_sizes = [bore_sizes, repelem(nozzle_bores(k), length(normalized_mean_force))];
        normalized_mean_forces = [normalized_mean_forces, normalized_mean_force];
    end

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
end

figure(2)
xlabel("Flow Rate (mm^3 / s)")
ylabel("Extrusion Force (kg)")
legend(handles, duts)
improvePlot

% Compute the inverse cubic fit on the data
f = fit(bore_sizes', normalized_mean_forces', "a/x^3")

% Extract the params and 95% CI
conf_level = 0.95;
params = coeffvalues(f);
ci = confint(f, conf_level);
uncertainty = diff(ci) / 2

% Compute the domain for the fit line
x_fit = linspace(min(bore_sizes), max(bore_sizes), 100);
y_fit = predint(f, x_fit, conf_level, 'functional', 'off');

% Extract the upper and lower bounds of the fit
y_fit_upper = y_fit(:, 2);
y_fit_lower = y_fit(:, 1);

% Compute the region boundriaes
x_fit_region = [x_fit, fliplr(x_fit)];
in_between_region = [y_fit_upper; flipud(y_fit_lower)];

% Plot the data, curve fit, and shaded region
figure(3)
hf = fill(x_fit_region, in_between_region, "m", "DisplayName", "95% Confidence Bounds");
hf.FaceAlpha = 0.5;
hf.FaceColor = "#C16643";
hf.EdgeColor = "none";

plot(x_fit, f(x_fit), "Color", "#C16643", "DisplayName", "Inverse Cubic Fit")

xlabel("Bore Size (mm)")
ylabel("Normalized Extrusion Force (kg / (mm^3 / s))")
improvePlot
