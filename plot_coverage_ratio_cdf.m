addpath(genpath('./')); % Add paths of subfolders
clearvars

%% Define parameters
SINR_u_dB = 0;
num_ant = 4;

%% Load upper bound of detection distance
load(strcat("results\UB_max_distance_ant_1x", num2str(num_ant), "_P_30.mat"))
UB_max_distance = max_distances_BF;

%% Compute the coverage ratio
num_scenarios = 568;
input_dir = strcat("results_user_distribution\max_distance_", ...
                   "ant_1x", num2str(num_ant), "_", ...
                   "P_30_", ...
                   "SINR_u_", num2str(SINR_u_dB), "\");

all_avg_ratio_BF = zeros(num_scenarios, 1);
all_avg_ratio_PA = zeros(num_scenarios, 1);
for i = 1:num_scenarios
    load(strcat(input_dir, "scenario_", num2str(i), ".mat"))

    avg_ratio_BF = mean( max_distances_BF ./ UB_max_distance );
    avg_ratio_PA = mean( max_distances_PA ./ UB_max_distance );

    all_avg_ratio_BF(i) = avg_ratio_BF;
    all_avg_ratio_PA(i) = avg_ratio_PA;
end

%% Plot CDF
set_default_plot;

figure()
[f, x] = ecdf(all_avg_ratio_BF);
plot(x, f, DisplayName='Joint Beamforming Optimization', Color='#2F8AB7')
hold on
[f, x] = ecdf(all_avg_ratio_PA);
plot(x, f, DisplayName='Zero-Forcing with Power Allocation', Color='#921D21')
grid on
legend(Location="northwest")

ylabel('CDF')
xlabel('Detection Coverage')
