% System parameters
params.N_v = 1; % Number of vertical elements
params.N_h = 8; % Number of horizontal elements
params.ant_spacing = 0.5;
params.BS_height = 0; % Height of the base station (meter)

params.F_c = 2.4 * 1e9; % Carrier frequency (Hz)
params.B = 10 * 1e6; % Bandwidth (Hz)
params.P_dBm = 30; % Transmit power (dBm)
params.noise_figure = 7; % Noise figure (dB)

params.K = 1; % Number of users
params.T = 1; % Number of tags
params.S_reader = -94; % Reader's sensitivity (dBm)
params.S_tag = -25.5; % Tag's sensitivity (dBm)
params.backscatter_mod_eff = 0.16; % Backscatter modulation efficiency
params.gamma_u_dB = 0; % Communication requirement (dB)