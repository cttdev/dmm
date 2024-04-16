function F = analytical_solution(mat, T, A_F, Q, alpha, L_C, D_C)
    % Compute the capiliary geometry term
    cap_factor = (32 * Q) / (pi * D_C^3);

    % Compute the inner term used in the pressure drop equations
    factor = (1 + 3 * mat.n) / (4 * mat.n) * cap_factor;

    % Convergent Section Pressure Drop
    dP_alpha = mat.K(T) * factor^n * 2 / (3 * mat.n * tan(alpha / 2)) + ...
               mat.L * 2^(1 - mat.m) / (3 * m) * tan(alpha / 2)^mat.m * cap_factor^mat.m;

    % Entry Pressure Drop
    dP_0 = mat.K(T) * factor^n * 1.18 / n^0.7;

    % Capillary Pressure Drop
    dP_cap = mat.K(T) * factor^n * (4 * L_C) / D_C;

    % Total Pressure Drop
    dP = dP_alpha + dP_0 + dP_cap;

    % Extrusion Force
    F = dP * A_F;
end