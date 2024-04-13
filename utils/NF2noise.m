function noise = NF2noise(NF, B)
    % NF: Noise figure (dB)
    % B: Bandwidth (Hz)

    T = 290; % Kelvin
    k = physconst('Boltzmann'); % Boltzmann constant
    noise = T*k*B*db2pow(NF);
end