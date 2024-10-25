addpath(genpath('./')); % Add paths of subfolders
clear all
eval('sim_params');
rng('default')

%% Define system parameters
c = physconst('LightSpeed');
lambda = c / params.F_c; % Wavelength (meter)
params.lambda = lambda;

N_h = params.N_h; % Number of vertical elements
N_v = params.N_v; % Number of horizontal elements
N = N_h * N_v; % Number of antenna elements
ant_spacing = params.ant_spacing;

BS_height = params.BS_height; % Height of the base station (meter)
P = 10^( (params.P_dBm-30) / 10 ); % Transmit power (Watt)
params.P = P;

K = params.K; % Number of users
T = params.T; % Number of tag
backscatter_mod_eff = params.backscatter_mod_eff; % Backscatter modulation efficiency
eta = backscatter_mod_eff;

%% Define user's SINR constraint
gamma_u_dB = 0; % dB
gamma_u = 10^( gamma_u_dB / 10 ); 

%% Define the receive noise power
B = params.B;
NF = params.noise_figure;
n_tag = NF2noise(NF, B); % Watt
n_reader = NF2noise(NF, B); % Watt
n_user = NF2noise(NF, B); % Watt

%% Define the sensitivity
S_reader = params.S_reader; % dBm
S_tag = params.S_tag; % dBm
gamma_r = 10^( (S_reader-30) / 10 ) / n_reader; 
gamma_t = 10^( (S_tag-30) / 10 ) / n_tag; 

%% Define coordinate vectors of antenna elements
[Tx_coor, D] = generate_Tx_coordinates(N_h, N_v, ant_spacing, BS_height, lambda);
Tx_coor = Tx_coor - Tx_coor(1, :);
ref_ant_coor = Tx_coor(1, :);

%% Define Fraunhofer and Fresnel distances
Fraunhofer_d = 2 * D^2 / lambda; % meter
Fresnel_d = 0.62 * sqrt(D^3/lambda); % meter

%% Define user's position & channel
user_distance = 5;
user_angle = 135;
user_coor = zeros(1, 3);
user_coor(1, 1) = user_distance * sind(user_angle);
user_coor(1, 2) = - user_distance * cosd(user_angle);
h_user = generate_LoS_channel(N_h, lambda, ant_spacing, ref_ant_coor, user_coor);

%% Calculate the maximum distance
tic
angle_step = 0.1;
angles = 0:angle_step:180;
num_angles = size(angles, 2);

tag_distance = 6;

total_power_PA = zeros(num_angles, 1);
tag_power_PA = zeros(num_angles, 1);
user_power_PA = zeros(num_angles, 1);
total_power_BF = zeros(num_angles, 1);
tag_power_BF = zeros(num_angles, 1);
user_power_BF = zeros(num_angles, 1);
for i = 1:num_angles
    tag_angle = angles(i);
    disp(tag_angle)

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
    [PA_f_t, PA_f_u, PA_status] = PA_opt(N, P, eta, h_tag, h_user, h_tag_user, ...
                                         gamma_u, gamma_t, gamma_r, n_user, n_tag, n_reader, ...
                                         tag_angle, user_angle);

    % Solve beamforming optimization problem
    [BF_f_t, BF_f_u, BF_status] = BF_opt(N, P, eta, h_tag, h_user, h_tag_user, ...
                                         gamma_u, gamma_t, gamma_r, n_user, n_tag, n_reader);
        

    % Record the total power, user's power, tag's power
    total_power_PA(i) = norm(PA_f_t)^2 + norm(PA_f_u)^2;
    tag_power_PA(i) = norm(PA_f_t)^2;
    user_power_PA(i) = norm(PA_f_u)^2;
    total_power_BF(i) = norm(BF_f_t)^2 + norm(BF_f_u)^2;
    tag_power_BF(i) = norm(BF_f_t)^2;
    user_power_BF(i) = norm(BF_f_u)^2;
end
toc

%% Define output directory
output_filename = strcat("./results/", ...
    "transmit_power_", ...
    "ant_", num2str(N_v), "x", num2str(N_h), "_", ...
    "P_", num2str(params.P_dBm), "_", ...
    "SINR_u_", num2str(gamma_u_dB), "_", ...
    "tag_d_", num2str(tag_distance), ...
    ".mat");

save(output_filename, "user_coor", "angles", "total_power_PA", "tag_power_PA", "user_power_PA", "total_power_BF", "tag_power_BF", "user_power_BF")