clear all
rng('default')

Num_of_scenarios = 1000; % Number of different user distributions
x_min = 0;
x_max = 20;
y_min = -20;
y_max = 20;

UE_coors = zeros(Num_of_scenarios, 3);
for i = 1:Num_of_scenarios
    regenerate = 0;
    while ~regenerate
        UE_coors(i, 1) = (x_max - x_min) * rand + x_min;
        UE_coors(i, 2) = (y_max - y_min) * rand + y_min;
        regenerate = 1;

        if (UE_coors(i, 1) == 0) && (UE_coors(i, 2) == 0)
            regenerate = 0; 
        end
    end
end

save(strcat("user_distribution\", ...
            "_x_", num2str(x_min), "_", num2str(x_max), ...
            "_y_", num2str(y_min), "_", num2str(y_max), ...
            ".mat"), "UE_coors")
