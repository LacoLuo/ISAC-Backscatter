addpath(genpath('./')); % Add paths of subfolders
clearvars

SINR_u_dB = 0;
user_distance = 5;
postfix = "";

num_ant_1 = 4;
num_ant_2 = 8;

load(strcat("results\max_distance_ant_1x", num2str(num_ant_1), "_P_30_SINR_u_", num2str(SINR_u_dB), "_user_d_", num2str(user_distance), postfix, ".mat"))
max_distances_BF_1 = max_distances_BF;
max_distances_PA_1 = max_distances_PA;
load(strcat("results\max_distance_ant_1x", num2str(num_ant_2), "_P_30_SINR_u_", num2str(SINR_u_dB), "_user_d_", num2str(user_distance), postfix, ".mat"))
max_distances_BF_2 = max_distances_BF;
max_distances_PA_2 = max_distances_PA;

user_angle = mod(atand(user_coor(1, 1)/(-user_coor(1, 2))), 180);

set_default_plot;

figure()
xline(user_angle, '--', LineWidth=2, Color='#464145');
hold on
plot(angles, max_distances_BF_1, ':', Color='#2F8AB7');
hold on
plot(angles, max_distances_PA_1, ':', Color='#921D21');
hold on
plot(angles, max_distances_BF_2, '-', Color='#2F8AB7');
hold on
plot(angles, max_distances_PA_2, '-', Color='#921D21');
grid on
box on
legend('', "Location", "northwest")

plot([NaN NaN], [NaN NaN], Color='#2F8AB7', DisplayName='Joint Beamforming Optimization')
plot([NaN NaN], [NaN NaN], Color='#921D21', DisplayName='Zero-Forcing with Power Allocation')

plot([NaN NaN], [NaN NaN], Color='k', LineStyle=":", DisplayName=strcat(num2str(num_ant_1), ' Antennas'))
plot([NaN NaN], [NaN NaN], Color='k', LineStyle="-", DisplayName=strcat(num2str(num_ant_2), ' Antennas'))

xlim([0 180])   
ylim([0 30])
ylabel('Distance (meter)')
xlabel('Angle (degree)')