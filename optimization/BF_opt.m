function [f_t, f_u, status] = BF_opt(N, P, eta, h_tag, h_user, h_tag_user, gamma_u, gamma_t, gamma_r, n_user, n_tag, n_reader) 

    % Calculate the combining vector
    w = h_tag ./ vecnorm(h_tag);
    
    % Solve the optimization problem of beamforming
    cvx_begin quiet
    %cvx_precision high

    variable f_t(N, 1) complex % Sensing BF vector
    variable f_u(N, 1) complex % Comm. BF vector

    % Objective
    obj = norm(f_t) + norm(f_u); 
    minimize(obj)

    subject to
        sum(pow_abs(f_t, 2)) + sum(pow_abs(f_u, 2)) <= P;

        % SINR constraints
        norm([h_user' * f_t, ...
              sqrt(eta) * h_tag_user * h_tag' * f_t, ...
              sqrt(eta) * h_tag_user * h_tag' * f_u, ...
              sqrt(eta) * h_tag_user * sqrt(n_tag),  ...
              sqrt(n_user)]) ...
           <= sqrt(1/gamma_u) * real(h_user' * f_u);

        norm([h_tag' * f_u, ...
              sqrt(n_tag)]) ...
           <= sqrt(1/gamma_t) * real(h_tag' * f_t);
        
        norm([sqrt(eta) * w' * h_tag * h_tag' * f_u, ...
              sqrt(eta) * w' * h_tag * sqrt(n_tag),  ...
              sqrt(n_reader)]) ...
           <= sqrt(eta/gamma_r) * abs(w' * h_tag) * real(h_tag' * f_t);
    cvx_end

    if strcmp(cvx_status, "Solved") && (norm(f_t)^2 + norm(f_u)^2 <= P)
        status = cvx_status;
    else
        status = "Infeasible";
        f_t = zeros(N, 1);
        f_u = zeros(N, 1);
    end
end
