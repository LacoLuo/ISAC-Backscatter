addpath(genpath('./')); % Add paths of subfolders
clear all

disp(datetime('now'))
eval('sim_params');
rng('default')

%% Define system parameters
c = physconst('LightSpeed');
lambda = c / params.F_c; % Wavelength (meter)

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
B = params.B; % Hz
NF = params.noise_figure; % dB
n_tag = NF2noise(NF, B); % Watt
n_reader = NF2noise(NF, B); % Watt
n_user = NF2noise(NF, B); % Watt

%% Define the sensitivity
S_reader = params.S_reader; % dBm
S_tag = params.S_tag; % dBm
gamma_r = 10^( (S_reader-30) / 10 ) / n_reader; % dB
gamma_t = 10^( (S_tag-30) / 10 ) / n_tag; % dB

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
angle_step = 1;
distance_step = 0.1;

angles = 0:angle_step:180;
num_angles = size(angles, 2);
max_distances_PA = zeros(num_angles, 1);
max_distances_BF = zeros(num_angles, 1);
parfor i = 1:num_angles
    tag_angle = angles(i);
    disp(tag_angle)

    PA_done = 0;
    BF_done = 0;
    max_distance_PA = 0;
    max_distance_BF = 0;
    
    distance = 0;
    while ~(PA_done && BF_done)
        distance = distance + distance_step;

        % Compute tag's position
        tag_coor = zeros(1, 3);
        tag_coor(1, 1) = distance * sind(tag_angle);
        tag_coor(1, 2) = - distance * cosd(tag_angle);

        % Calculate tag's channel
        h_tag = generate_LoS_channel(N_h, lambda, ant_spacing, ref_ant_coor, tag_coor);

        % Compute channel between tag and user
        d_tag_user = sqrt(sum((tag_coor - user_coor).^2));
        h_tag_user = lambda/(4*pi*d_tag_user) * exp(- 1j * 2*pi/lambda * d_tag_user);

        % Solve power allocation problem given zero-forcing precoding
        if ~PA_done
            [PA_f_t, PA_f_u, PA_status] = PA_opt(N_h, P, eta, h_tag, h_user, h_tag_user, ...
                                                 gamma_u, gamma_t, gamma_r, n_user, n_tag, n_reader, ...
                                                 tag_angle, user_angle);

            if strcmp(PA_status, "Solved")
                max_distance_PA = distance;
            else
                PA_done = 1;
            end
        end

        % Solve beamforming optimization problem
        if ~BF_done
            [BF_f_t, BF_f_u, BF_status] = BF_opt(N_h, P, eta, h_tag, h_user, h_tag_user, ...
                                                 gamma_u, gamma_t, gamma_r, n_user, n_tag, n_reader);
            
            if strcmp(BF_status, "Solved")
                max_distance_BF = distance;
            else
                BF_done = 1;
            end
        end

    end

    % Record the max. distance
    max_distances_PA(i) = max_distance_PA;
    max_distances_BF(i) = max_distance_BF;
end
toc

%% Define output filename
output_dir = "./results/";
if ~exist(output_dir, "dir")
    mkdir(output_dir)
end

output_filename = strcat(output_dir, ...
    "max_distance_", ...
    "ant_", num2str(N_v), "x", num2str(N_h), "_", ...
    "P_", num2str(params.P_dBm), "_", ...
    "SINR_u_", num2str(gamma_u_dB), "_", ...
    "user_d_", num2str(user_distance), ...
    ".mat");

save(output_filename, "user_coor", "angles", "max_distances_PA", "max_distances_BF")