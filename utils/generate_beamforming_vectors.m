function [f_tag, f_user] = generate_beamforming_vectors(h_tag, h_user, BF)
    N = size(h_user, 1);
    if strcmp(BF, 'conjugate_beamforming')
        f_user = h_user ./ vecnorm(h_user);
        f_tag = h_tag ./ vecnorm(h_tag);
    elseif strcmp(BF, 'zero_forcing')
        channels = cat(2, h_user, h_tag);
        precoding_vector = channels / (channels' * channels);
        F = precoding_vector ./ vecnorm(precoding_vector);
        f_user = F(:, 1);
        f_tag = F(:, 2);
    end
end