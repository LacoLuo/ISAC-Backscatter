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
eta = params.backscatter_mod_eff; % Backscatter modulation efficiency

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
load("user_distribution\_x_0_20_y_-20_20.mat")

%% Define output directory
output_dir = strcat("./results_user_distribution/", ...
    "max_distance_", ...
    "ant_", num2str(N_v), "x", num2str(N_h), "_", ...
    "P_", num2str(params.P_dBm), "_", ...
    "SINR_u_", num2str(gamma_u_dB), "/");

if ~exist(output_dir, 'dir')
   mkdir(output_dir)
end

%% Calculate the maximum distance
num_scenarios = size(UE_coors, 1);

angle_step = 1;
angles = 0:angle_step:180;
num_angles = size(angles, 2);

distance_step = 0.5;

for i = 1:1000
    disp(strcat("Scenario ", num2str(i)))
    tic
    % User's position and channel
    user_coor = UE_coors(i, :);
    user_angle = mod(atan2d(user_coor(1, 1), -user_coor(1, 2)), 180);
    h_user = generate_LoS_channel(N_h, lambda, ant_spacing, ref_ant_coor, user_coor);
    
    max_distances_PA = zeros(num_angles, 1);
    max_distances_BF = zeros(num_angles, 1);
    parfor j = 1:num_angles
        angle = angles(j);
        disp(angle)
    
        PA_done = 0;
        BF_done = 0;
        max_distance_PA = 0;
        max_distance_BF = 0;
        
        distance = 0;
        while ~(PA_done && BF_done)
            distance = distance + distance_step;
    
            % Compute tag's position
            tag_coor = zeros(1, 3);
            tag_coor(1, 1) = distance * sind(angle);
            tag_coor(1, 2) = - distance * cosd(angle);
    
            % Calculate tag's channel
            h_tag = generate_LoS_channel(N_h, lambda, ant_spacing, ref_ant_coor, tag_coor);
    
            % Compute channel between tag and user
            d_tag_user = sqrt(sum((tag_coor - user_coor).^2));
            h_tag_user = lambda/(4*pi*d_tag_user) * exp(- 1j * 2*pi/lambda * d_tag_user);
    
            % Solve power allocation problem given zero-forcing precoding
            if ~PA_done
                [PA_f_t, PA_f_u, PA_status] = PA_opt(N, P, eta, h_tag, h_user, h_tag_user, ...
                                                     gamma_u, gamma_t, gamma_r, n_user, n_tag, n_reader, ...
                                                     angle, user_angle);
    
                if strcmp(PA_status, "Solved")
                    max_distance_PA = distance;
                else
                    %disp(PA_status)
                    PA_done = 1;
                end
            end
    
            % Solve beamforming optimization problem
            if ~BF_done
                [BF_f_t, BF_f_u, BF_status] = BF_opt(N, P, eta, h_tag, h_user, h_tag_user, ...
                                                     gamma_u, gamma_t, gamma_r, n_user, n_tag, n_reader);
                
                if strcmp(BF_status, "Solved")
                    max_distance_BF = distance;
                else
                    %disp(BF_status)
                    BF_done = 1;
                end
            end
    
        end
    
        % Record the max. distance
        max_distances_PA(j) = max_distance_PA;
        max_distances_BF(j) = max_distance_BF;
    end
    toc
    
    % Define output filename
    output_filename = strcat(output_dir, ...
        "scenario_", num2str(i),".mat");
    
    save(output_filename, "user_coor", "angles", "max_distances_PA", "max_distances_BF")
end