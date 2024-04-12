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

% Array to hold all the raw data
data = zeros([length(flow_rates), num_trials, num_points, 2]);
offsets = zeros([length(flow_rates), num_trials]);
masks = zeros([length(flow_rates), num_trials, num_points]);

% Plotting Setup
xlabel("Time (s)")
ylabel("Extrusion Force (kg)")
for i = 1:length(flow_rates)
    % Get the files for each flow rate
    fr_dir = dir("data\trials\" + data_dir{i});

    fr_dir_mask = [fr_dir(:).isdir];
    fr_dir = {fr_dir(~fr_dir_mask).name};

    % For each of the flow rate samples put it into the data array
    for j = 1:num_trials
        data(i, j, :, :) = readmatrix("data\trials\" + data_dir{i} + "\" + fr_dir{j});

        % Plot the data from the trial to make the mask
        brush on
        times = squeeze(data(i, j, :, 1));
        forces = squeeze(data(i, j, :, 2));
        plot(times, forces)
        xlabel("Time (s)")
        ylabel("Extrusion Force (kg)")

        % Wait for user to brush data
        while true
            if waitforbuttonpress == 1
                break
            end
        end

        % Find brushed region and store it as the mask
        ax = gca;
        zero_offset_mask = logical(squeeze(ax.Children.BrushData));

        % Compute the mean of the region and use that as the zero offset
        zero_offset = mean(forces(zero_offset_mask));
        disp("Zero Offset: " + num2str(zero_offset) + " kg")
        disp("Zero Offset Num Samples: " + num2str(sum(zero_offset_mask)))

        offsets(i, j) = zero_offset;

        plot(times, forces - zero_offset)
        xlabel("Time (s)")
        ylabel("Extrusion Force (kg)")

        % Wait for user to brush data
        while true
            if waitforbuttonpress == 1
                break
            end
        end

        % Find brushed region and store it as the mask
        ax = gca;
        masks(i, j, :) = ax.Children.BrushData;
        mask = logical(squeeze(masks(i, j, :)));

        % Plot the masked regions with everything
        figure
        plot(times, forces * 9.81)
        hold on

        xs = [min(times(zero_offset_mask)), max(times(zero_offset_mask))];
        ys = ylim;
        y_upper = repelem(ys(2), 2);
        y_lower = repelem(ys(1), 2);

        hf = fill([xs, fliplr(xs)], [y_lower, flipud(y_upper)], "blue", "DisplayName", "95% Confidence Bounds");
        hf.FaceAlpha = 0.5;
        hf.FaceColor = "#77AC30";
        hf.EdgeColor = "none";
        ylim(ys)
        
        xs = [min(times(mask)), max(times(mask))];
        ys = ylim;
        y_upper = repelem(ys(2), 2);
        y_lower = repelem(ys(1), 2);

        hf = fill([xs, fliplr(xs)], [y_lower, flipud(y_upper)], "blue", "DisplayName", "95% Confidence Bounds");
        hf.FaceAlpha = 0.5;
        hf.FaceColor = "#7E2F8E";
        hf.EdgeColor = "none";
        ylim(ys)

        title("Trial " + num2str(j) + " Flow Rate " + num2str(flow_rates(i)) + " mm^3/s Level 1 Data")
        xlabel("Time (s)")
        ylabel("Extrusion Force (N)")

        improvePlot

        break
    end

    break
end