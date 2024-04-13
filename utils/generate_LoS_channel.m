function [LoS_channel] = generate_LoS_channel(N, lambda, ant_spacing, Tx_coor, Rx_coor)
    AoD = mod(atan2d( (Rx_coor(1, 1)-Tx_coor(1, 1)), (-Rx_coor(1, 2)-Tx_coor(1, 2)) ), 180);
    d = sqrt(sum((Rx_coor - Tx_coor).^2));

    kd = 2 * pi * ant_spacing;
    ant_index = 0:1:N-1;
    path_gain = lambda/(4*pi*d) * exp(- 1j * 2*pi/lambda * d);
    LoS_channel = path_gain .* exp(- 1j * kd * ant_index' * cosd(AoD));
end
