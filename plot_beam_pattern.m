addpath(genpath('./')); % Add paths of subfolders
clear all
eval('sim_params');
rng('default')

%% Define system parameters
c = physconst('LightSpeed');
lambda = c / params.F_c; % Wavelength (meter)
params.lambda = lambda;

N_v = params.N_v; % Number of vertical antenna elements
N_h = params.N_h; % Number of horizontal antenna elements
ant_spacing = params.ant_spacing;

BS_height = params.BS_height; % Height of the base station (meter)
P = 10^( (params.P_dBm-30) / 10 ); % Transmit power (Watt)

eta = params.backscatter_mod_eff; % Backscatter modulation efficiency

%% Define user's SINR constraint
gamma_u_dB = params.gamma_u_dB; % dB
gamma_u = 10^( gamma_u_dB / 10 ); 

%% Define the receive noise power
B = params.B;
NF = params.noise_figure;
n_tag = NF2noise(NF, B); % Watt
n_reader = NF2noise(NF, B); % Watt
n_user = NF2noise(NF, B); % Watt
n_user_dBW = 10 * log10(n_user); % dBW

%% Define the sensitivity
S_reader = params.S_reader; % dBm
S_tag = params.S_tag; % dBm
gamma_r = 10^( (S_reader-30) / 10 ) / n_reader; 
gamma_t = 10^( (S_tag-30) / 10 ) / n_tag; 
gamma_r_dB = 10 * log10(gamma_r);
gamma_t_dB = 10 * log10(gamma_t);

%% Define coordinate vectors of antenna elements
[Tx_coor, ~] = generate_Tx_coordinates(N_h, N_v, ant_spacing, BS_height, lambda);
Tx_coor = Tx_coor - Tx_coor(1, :);
ref_ant_coor = Tx_coor(1, :);

%% Define user's position & channel
user_distance = 5;
user_angle = 135;
user_coor = zeros(1, 3);
user_coor(1, 1) = user_distance * sind(user_angle);
user_coor(1, 2) = - user_distance * cosd(user_angle);
h_user = generate_LoS_channel(N_h, lambda, ant_spacing, ref_ant_coor, user_coor);

%% Calculate the maximum distance
tic

tag_angle = 90;
tag_distance = 5;

% Compute tag's position
tag_coor = zeros(1, 3);
tag_coor(1, 1) = tag_distance * sind(tag_angle);
tag_coor(1, 2) = - tag_distance * cosd(tag_angle);

% Calculate tag's channel
h_tag = generate_LoS_channel(N_h, lambda, ant_spacing, ref_ant_coor, tag_coor);

% Compute channel between tag and user
d_tag_user = sqrt(sum((tag_coor - user_coor).^2));
h_tag_user = lambda/(4*pi*d_tag_user) * exp(- 1j * 2*pi/lambda * d_tag_user);

% Solve power allocation problem given zero-forcing precoding
[PA_f_t, PA_f_u, PA_status] = PA_opt(N_h, P, eta, h_tag, h_user, h_tag_user, ...
                                     gamma_u, gamma_t, gamma_r, n_user, n_tag, n_reader, ...
                                     tag_angle, user_angle);

% Solve beamforming optimization problem
[BF_f_t, BF_f_u, BF_status] = BF_opt(N_h, P, eta, h_tag, h_user, h_tag_user, ...
                                     gamma_u, gamma_t, gamma_r, n_user, n_tag, n_reader);

toc

%% Compute BF gain
angle_step = 0.001;
angles = 0:angle_step:180;
num_angles = size(angles, 2);

normalized_array_response_vectors = zeros(N_h, num_angles);
for i = 1:num_angles
    kd = 2 * pi * ant_spacing;
    ant_index = 0:1:N_h-1;
    array_response_vector = exp(- 1j * kd * ant_index' * cosd(angles(i)));
    normalized_array_response_vectors(:, i) = array_response_vector ./ vecnorm(array_response_vector);
end

normalized_PA_f_t = PA_f_t ./ vecnorm(PA_f_t);
normalized_PA_f_u = PA_f_u ./ vecnorm(PA_f_u);
gain_PA_t = 10 * log10(abs(normalized_array_response_vectors' * normalized_PA_f_t));
gain_PA_u = 10 * log10(abs(normalized_array_response_vectors' * normalized_PA_f_u));

normalized_BF_f_t = BF_f_t ./ vecnorm(BF_f_t);
normalized_BF_f_u = BF_f_u ./ vecnorm(BF_f_u);
gain_BF_t = 10 * log10(abs(normalized_array_response_vectors' * normalized_BF_f_t));
gain_BF_u = 10 * log10(abs(normalized_array_response_vectors' * normalized_BF_f_u));

%% Plot BF gain
set_default_plot; 

figure()
xline(user_angle, '--', LineWidth=2, Color='black');
hold on
xline(tag_angle, '--', LineWidth=2, Color='black');
hold on
plot(angles, gain_PA_u, Color='#2F8AB7')
hold on
plot(angles, gain_PA_t, Color='#921D21')
grid on
legend('', "Location", "southwest")

plot([NaN NaN], [NaN NaN], Color='#921D21', DisplayName='Sensing beam')
plot([NaN NaN], [NaN NaN], Color='#2F8AB7', DisplayName='Communication beam')

xlim([0 180])
set(gca, 'ylim', [-180 0]);
set(gca, 'ytick', -180:20:0);
ylabel('Gain (dB)')
xlabel('Angle (degree)')
title('Zero-Forcing with Power Allocation')

figure()
xline(user_angle, '--', LineWidth=2, Color='black');
hold on
xline(tag_angle, '--', LineWidth=2, Color='black');
hold on
plot(angles, gain_BF_u, Color='#2F8AB7')
hold on
plot(angles, gain_BF_t, Color='#921D21')
grid on
box on
legend('', "Location", "southwest")

plot([NaN NaN], [NaN NaN], Color='#921D21', DisplayName='Sensing beam')
plot([NaN NaN], [NaN NaN], Color='#2F8AB7', DisplayName='Communication beam')

xlim([0 180])
set(gca, 'ylim', [-100 0]);
set(gca, 'ytick', -100:20:0);
ylabel('Gain (dB)')
xlabel('Angle (degree)')
title('Joint Beamforming Optimization')
