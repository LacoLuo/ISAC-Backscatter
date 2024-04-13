function [Tx_coor, D] = generate_Tx_coordinates(N_h, N_v, ant_spacing, BS_height, lambda)
    d = ant_spacing * lambda; % Spacing between antenna elements

    My_idx = 0:1:N_h-1;
    Mz_idx = 0:1:N_v-1;
    Myy_idx = repmat(My_idx, 1, N_v)';
    Mzz_idx = reshape(repmat(Mz_idx, N_h, 1), 1, N_h*N_v)';
    yz_idx = reshape(cat(3, Myy_idx', Mzz_idx'), [], 2);
    x_coor = zeros(size(yz_idx, 1), 1);
    yz_coor = (yz_idx - [(N_h-1)/2, (N_v-1)/2]) * d + [0, BS_height];

    Tx_coor = cat(2, x_coor, yz_coor);
    D = sqrt( (max(yz_coor(:, 1))-min(yz_coor(:, 1)))^2 + (max(yz_coor(:, 2))-min(yz_coor(:, 2)))^2 ); % Max largest dimension of antenna array
end
