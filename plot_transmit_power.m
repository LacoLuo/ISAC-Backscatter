clearvars

SINR_u_dB = 0;
tag_distance = 6;

num_ant_1 = 4;

load(strcat("results\transmit_power_ant_1x", num2str(num_ant_1), "_P_30_SINR_u_", num2str(SINR_u_dB), ...
            "_tag_d_", num2str(tag_distance), ".mat"))

user_angle = mod(atand(user_coor(1, 1)/(-user_coor(1, 2))), 180);

set_default_plot;

figure()
xline(user_angle, '--', LineWidth=2, Color='black');
hold on
plot(angles, (total_power_BF), ':', Color='#2F8AB7')
hold on
plot(angles, (total_power_PA), '--', Color='#921D21')
grid on
legend('', Location="northwest")

plot([NaN NaN], [NaN NaN], ':', Color='#2F8AB7', DisplayName='Joint Beamforming Optimization')
plot([NaN NaN], [NaN NaN], '--', Color='#921D21', DisplayName='Zero-Forcing with Power Allocation')


xlim([0 180])
ylim([0 1])
ylabel('Total Allocated Power (watt)')
xlabel('Angle (degree)')