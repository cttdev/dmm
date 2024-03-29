close all;

% Setup
num_trials = 5; % The number of trials to use
num_points = 7 * 1000; % Number of datapoints per trial

% Start by loading in all the data csvs so masks can be created
data_dir = dir("data\trials\");

% Get all the subdirectories in the trials folder (the flow rates)
data_dir_mask = [data_dir(:).isdir];
data_dir = {data_dir(data_dir_mask).name};
data_dir = data_dir(~ismember(data_dir, {'.', '..'}));
flow_rates = str2double(data_dir);

% % Array to hold all the raw data
% data = zeros([length(flow_rates), num_trials, num_points, 2]);
% offsets = zeros([length(flow_rates), num_trials]);
% masks = zeros([length(flow_rates), num_trials, num_points]);
% 
% % Plotting Setup
% xlabel("Time (s)")
% ylabel("Extrusion Force (kg)")
% for i = 1:length(flow_rates)
%     % Get the files for each flow rate
%     fr_dir = dir("data\trials\" + data_dir{i});
% 
%     fr_dir_mask = [fr_dir(:).isdir];
%     fr_dir = {fr_dir(~fr_dir_mask).name};
% 
%     % For each of the flow rate samples put it into the data array
%     for j = 1:num_trials
%         data(i, j, :, :) = readmatrix("data\trials\" + data_dir{i} + "\" + fr_dir{j});
% 
%         % Plot the data from the trial to make the mask
%         brush on
%         times = squeeze(data(i, j, :, 1));
%         forces = squeeze(data(i, j, :, 2));
%         plot(times, forces)
%         xlabel("Time (s)")
%         ylabel("Extrusion Force (kg)")
% 
%         % Wait for user to brush data
%         while true
%             if waitforbuttonpress == 1
%                 break
%             end
%         end
% 
%         % Find brushed region and store it as the mask
%         ax = gca;
%         mask = logical(squeeze(ax.Children.BrushData));
% 
%         % Compute the mean of the region and use that as the zero offset
%         zero_offset = mean(forces(mask));
%         disp("Zero Offset: " + num2str(zero_offset) + " kg")
%         disp("Zero Offset Num Samples: " + num2str(sum(mask)))
% 
%         offsets(i, j) = zero_offset;
% 
%         plot(times, forces - zero_offset)
%         xlabel("Time (s)")
%         ylabel("Extrusion Force (kg)")
% 
%         % Wait for user to brush data
%         while true
%             if waitforbuttonpress == 1
%                 break
%             end
%         end
% 
%         % Find brushed region and store it as the mask
%         ax = gca;
%         masks(i, j, :) = ax.Children.BrushData;
% 
%         % Plot the masked region
%         brush off
%         mask = logical(squeeze(masks(i, j, :)));
%         plot(times(mask), forces(mask) - zero_offset)
%         xlabel("Time (s)")
%         ylabel("Extrusion Force (kg)")
% 
%         % Wait for user to confrim mask
%         while true
%             if waitforbuttonpress == 1
%                 break
%             end
%         end
%     end
% end

% Plot the Level 1 Data
trial_num = 1;
for i = 1:length(flow_rates)
    mask = logical(squeeze(masks(i, trial_num, :)));

    zero_offset = offsets(i, trial_num);

    times = squeeze(data(i, trial_num, :, 1));
    forces = squeeze(data(i, trial_num, :, 2));
    
    figure(1)
    plot(times, forces, "DisplayName", "Flow Rate: " + num2str(flow_rates(i)) + " mm^3/s")
    hold on

    figure(2)
    plot(times(mask), forces(mask) - zero_offset, "DisplayName", "Flow Rate: " + num2str(flow_rates(i)) + " mm^3/s")
    hold on
end

figure(1)
xlabel("Time (s)")
ylabel("Force (kg)")
title("Level 1 Data for Trial " + num2str(trial_num))
legend(gca, "show")
improvePlot

figure(2)
xlabel("Time (s)")
ylabel("Force (kg)")
title("Masked Level 1 Data for Trial " + num2str(trial_num))
legend(gca, "show")
improvePlot

% Construct a flow rate plot
figure
plot_colors = ["#0072BD", "#D95319", "#EDB120", "#7E2F8E", "#77AC30", "#4DBEEE", "#A2142F"];
% mean_and_uncertainties_a = ["(1.3 ± 5.5)*10^-5 kg/V^n", "(1.3 ± 5.5)*10^-5 kg/V^n"]
mean_and_uncertainties_n = ["(4.2 ± 1.7)", "(1.48 ± 0.27)", "(2.11 ± 0.86)", "(0.84 ± 0.15)", "(0.74 ± 0.14)"];
for j = 1:num_trials
    mean_forces = zeros(length(flow_rates), 1);
    for i = 1:length(flow_rates)
        mask = logical(squeeze(masks(i, j, :)));

        times = squeeze(data(i, j, :, 1));
        forces = squeeze(data(i, j, :, 2));

        zero_offset = offsets(i, j);

        times = times(mask);
        forces = forces(mask) - zero_offset;

        mean_forces(i) = mean(forces);
    end

    % Compute the power law fit on the data
    f = fit(flow_rates', mean_forces, "power1")
    
    % Extract the params and 95% CI
    conf_level = 0.95;
    params = coeffvalues(f);
    ci = confint(f, conf_level);
    uncertainty = diff(ci) / 2
    
    % Compute the domain for the fit line
    x_fit = linspace(min(flow_rates), max(flow_rates), 100);
    y_fit = predint(f, x_fit, conf_level, 'functional', 'off');
    
    % Extract the upper and lower bounds of the fit
    y_fit_upper = y_fit(:, 2);
    y_fit_lower = y_fit(:, 1);
    
    % Compute the region boundriaes
    x_fit_region = [x_fit, fliplr(x_fit)];
    in_between_region = [y_fit_upper; flipud(y_fit_lower)];
    
    % Plot the data. curve fit, and shaded region
    hf = fill(x_fit_region, in_between_region, "m", "DisplayName", "95% Confidence Bounds Trial " + num2str(j));
    hf.FaceAlpha = 0.5;
    hf.FaceColor = plot_colors(mod(j, length(plot_colors)));
    hf.EdgeColor = "none";
    hold on
    
    plot(x_fit, f(x_fit), "Color", plot_colors(mod(j, length(plot_colors))), "DisplayName", "Power Law Fit: a * x^n; n = " + mean_and_uncertainties_n(j))
    plot(flow_rates, mean_forces, "o", "Color", plot_colors(mod(j, length(plot_colors))), "DisplayName", "Raw Data Trial " + num2str(j))
end

title("Extrusion Data and Fit")
xlabel("Flow Rate (mm^3 / s)")
ylabel("Extrusion Force (kg)")
improvePlot
legend("FontSize", 10);