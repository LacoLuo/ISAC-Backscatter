function [f_t, f_u, status] = PA_opt(N, P, eta, h_tag, h_user, h_tag_user, gamma_u, gamma_t, gamma_r, n_user, n_tag, n_reader, tag_angle, user_angle) 
    
    % Calculate the zero-forcing precoding
    if tag_angle == user_angle
        [f_t, f_u] = generate_beamforming_vectors(h_tag, h_user, "conjugate_beamforming");
    else
        [f_t, f_u] = generate_beamforming_vectors(h_tag, h_user, "zero_forcing");
    end

    % Calculate the combining vector
    w = h_tag ./ vecnorm(h_tag);
    
    % Solve the optimization problem of beamforming
    cvx_begin quiet

    variable P_t
    variable P_u

    % Objective
    obj = P_t + P_u;
    minimize(obj)

    subject to
        % Power constraint
        P_t + P_u <= P;

        % SINR constraints
        P_u * abs(h_user' * f_u)^2 >= ...
            gamma_u * P_t * abs(h_user' * f_t)^2 + ...
            gamma_u * eta * abs(h_tag_user)^2 * (P_t * abs(h_tag' * f_t)^2 + P_u * abs(h_tag' * f_u)^2 + n_tag) + ...
            gamma_u * n_user;

        P_t * abs(h_tag' * f_t)^2 >= ...
            gamma_t * P_u * abs(h_tag' * f_u)^2 + ...
            gamma_t * n_tag;

        eta * abs(w' * h_tag)^2 * P_t * abs(h_tag' * f_t)^2 >= ...
            gamma_r * eta * abs(w' * h_tag)^2 * P_u * abs(h_tag' * f_u)^2 + ...
            gamma_r * eta * n_tag * abs(w' * h_tag)^2 + ...
            gamma_r * n_reader;

    cvx_end

    if strcmp(cvx_status, "Solved") && (P_t + P_u <= P)
        status = cvx_status;
        f_t = sqrt(P_t) * f_t;
        f_u = sqrt(P_u) * f_u;
    else
        status = 'Infeasible';
        f_t = zeros(N, 1);
        f_u = zeros(N, 1);
    end
end
